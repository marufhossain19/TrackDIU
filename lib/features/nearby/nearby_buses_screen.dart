// ====================================================
// features/nearby/nearby_buses_screen.dart — Modern Nearby Buses
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/modern_bus_card.dart';
import '../map/map_tracking_screen.dart';

class _NearbyBusEntry {
  final BusModel bus;
  final BusLocationModel location;
  final double distanceKm;

  _NearbyBusEntry({
    required this.bus,
    required this.location,
    required this.distanceKm,
  });
}

class NearbyBusesScreen extends ConsumerStatefulWidget {
  const NearbyBusesScreen({super.key});

  @override
  ConsumerState<NearbyBusesScreen> createState() => _NearbyBusesScreenState();
}

class _NearbyBusesScreenState extends ConsumerState<NearbyBusesScreen>
    with TickerProviderStateMixin {
  LatLng? _userPos;
  List<_NearbyBusEntry> _nearbyBuses = [];
  bool _isLoading = true;
  double _radiusKm = 10.0;
  final List<double> _radiusOptions = const [2.0, 5.0, 10.0, 20.0];
  final _radiusInputCtrl = TextEditingController(text: '10');
  final _radiusFocusNode = FocusNode();

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _radiusFocusNode.addListener(() {
      if (!_radiusFocusNode.hasFocus) {
        _submitCustomRadius();
      }
    });
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _radiusFocusNode.dispose();
    _radiusInputCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final locService = ref.read(locationServiceProvider);
    final pos = await locService.getCurrentPosition();
    
    // Default to DIU Campus position if location is null (e.g. emulator without mock GPS)
    final userLatLng = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(AppConstants.defaultLat, AppConstants.defaultLng);

    final allLocations =
        await ref.read(supabaseServiceProvider).fetchAllBusLocations();

    final buses = await ref.read(supabaseServiceProvider).fetchBuses();
    final busMap = {for (var b in buses) b.id: b};

    final nearby = <_NearbyBusEntry>[];
    for (final loc in allLocations) {
      final distKm = LocationService.distanceKm(
        userLatLng.latitude,
        userLatLng.longitude,
        loc.latitude,
        loc.longitude,
      );
      if (distKm <= _radiusKm) {
        final bus = busMap[loc.busId];
        if (bus != null) {
          nearby.add(_NearbyBusEntry(
            bus: bus,
            location: loc,
            distanceKm: distKm,
          ));
        }
      }
    }

    // Real locations within radius
    nearby.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (mounted) {
      setState(() {
        _userPos = userLatLng;
        _nearbyBuses = nearby;
        _isLoading = false;
      });
      _fadeCtrl.forward(from: 0);

      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _userPos!,
          zoom: _zoomForRadius(_radiusKm),
        ),
      ));
    }
  }

  void _onRadiusSelected(double km) {
    setState(() {
      _radiusKm = km;
      _radiusInputCtrl.text = km.toInt().toString();
    });
    _loadData();
  }

  void _submitCustomRadius() {
    final text = _radiusInputCtrl.text.trim();
    final km = int.tryParse(text);
    if (km != null && km > 0) {
      FocusScope.of(context).unfocus();
      _onRadiusSelected(km.toDouble());
    }
  }

  void _navigateToTracking(BusModel bus) {
    ref.read(selectedBusProvider.notifier).state = bus;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const MapTrackingScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: AppConstants.medAnim,
    ));
  }

  void _showBusDetail(_NearbyBusEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusDetailSheet(
        entry: entry,
        userPos: _userPos,
        onTrack: () {
          Navigator.of(context).pop();
          _navigateToTracking(entry.bus);
        },
      ),
    );
  }

  double _zoomForRadius(double km) {
    if (km <= 2) return 14.5;
    if (km <= 5) return 13.0;
    if (km <= 10) return 12.0;
    if (km <= 20) return 11.0;
    if (km <= 50) return 9.5;
    return 8.5;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Set<Marker> markers = {};
    if (_userPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('userLoc'),
        position: _userPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'You',
          snippet: 'Search radius center',
        ),
      ));
    }

    for (final e in _nearbyBuses) {
      markers.add(Marker(
        markerId: MarkerId('bus_${e.bus.id}'),
        position: LatLng(e.location.latitude, e.location.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          e.bus.isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: '${e.bus.number} (${e.distanceKm.toStringAsFixed(1)} km)',
          snippet: e.bus.route,
        ),
        onTap: () => _showBusDetail(e),
      ));
    }

    final Set<Circle> circles = {};
    if (_userPos != null) {
      circles.add(Circle(
        circleId: const CircleId('radius_circle'),
        center: _userPos!,
        radius: _radiusKm * 1000,
        fillColor: AppColors.primary.withValues(alpha: 0.08),
        strokeColor: AppColors.primary.withValues(alpha: 0.45),
        strokeWidth: 2,
      ));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── Dark Navy Header (Matching Reference Image 1) ──
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              18,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with Back button and Radius badge
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Nearby Buses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Editable Current Radius Badge (matching red-marked box)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntrinsicWidth(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                maxWidth: 46,
                              ),
                              child: TextField(
                                controller: _radiusInputCtrl,
                                focusNode: _radiusFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                textAlign: TextAlign.center,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submitCustomRadius(),
                                cursorColor: Colors.white,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'km',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit_rounded,
                            size: 11,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Radius toggle pill row [2 km] [5 km] [10 km] [20 km]
                Row(
                  children: _radiusOptions.map((km) {
                    final isSelected = _radiusKm == km;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _onRadiusSelected(km),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${km.toInt()} km',
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF0A1F44)
                                      : Colors.white,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // ── Real Google Map with Live Bus Flags/Markers ──
          SizedBox(
            height: 240,
            width: double.infinity,
            child: _userPos == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userPos!,
                      zoom: _zoomForRadius(_radiusKm),
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: markers,
                    circles: circles,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                  ),
          ),

          // ── Bottom List: Unified Modern Bus Cards ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _nearbyBuses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_bus_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No buses within ${_radiusKm.toInt()} km',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try selecting a wider search radius above',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fade,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _nearbyBuses.length,
                          itemBuilder: (context, index) {
                            final e = _nearbyBuses[index];
                            final mins = (e.distanceKm / 30.0 * 60).round().clamp(1, 90);
                            return ModernBusCard(
                              bus: e.bus,
                              etaText: '$mins min ETA',
                              onTrack: () => _navigateToTracking(e.bus),
                              onTap: () => _showBusDetail(e),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Bus detail bottom sheet ───────────────────────────────────────────────────
class _BusDetailSheet extends StatelessWidget {
  final _NearbyBusEntry entry;
  final LatLng? userPos;
  final VoidCallback onTrack;

  const _BusDetailSheet({
    required this.entry,
    required this.userPos,
    required this.onTrack,
  });

  String _eta() {
    final mins = (entry.distanceKm / 30.0 * 60).round();
    if (mins < 1) return '< 1 min';
    if (mins == 1) return '~1 min';
    return '~$mins mins';
  }

  bool _passesNearUser() => entry.distanceKm < 5.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bus = entry.bus;
    final isActive = bus.isActive;
    final passesNear = _passesNearUser();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header row
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bus.number,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isActive ? '● LIVE' : '○ IDLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bus.route,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Stats grid
          Row(
            children: [
              _InfoTile(
                icon: Icons.straighten_rounded,
                label: 'DISTANCE',
                value: '${entry.distanceKm.toStringAsFixed(1)} km',
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.speed_rounded,
                label: 'SPEED',
                value: '${entry.location.speed?.toStringAsFixed(0) ?? '35'} km/h',
              ),
              const SizedBox(width: 10),
              _InfoTile(
                icon: Icons.access_time_rounded,
                label: 'EST. ARRIVAL',
                value: _eta(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Passes near banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: passesNear
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: passesNear
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  passesNear
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: passesNear
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    passesNear
                        ? 'This bus passes through your road or nearby stop'
                        : 'This bus is currently active on an adjacent corridor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: passesNear
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Track Bus Full Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onTrack,
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: const Text(
                'Track On Full Map',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: const Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A1F44),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
