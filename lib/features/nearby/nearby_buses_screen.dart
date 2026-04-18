// ====================================================
// features/nearby/nearby_buses_screen.dart
// ====================================================
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../services/location_service.dart';

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

  // Radius control
  final _kmCtrl = TextEditingController(text: '10');
  double _radiusKm = 10.0;

  // Fade animation
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _kmCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final locService = ref.read(locationServiceProvider);
    final pos = await locService.getCurrentPosition();
    if (pos == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final userLatLng = LatLng(pos.latitude, pos.longitude);

    final allLocations =
        await ref.read(supabaseServiceProvider).fetchAllBusLocations();
    
    // Heartbeat Filter: Only consider locations updated in the last 10 minutes
    final now = DateTime.now();
    final locations = allLocations.where((loc) {
      return now.difference(loc.updatedAt).inMinutes < 10;
    }).toList();

    final buses = await ref.read(supabaseServiceProvider).fetchBuses();
    final busMap = {for (var b in buses) b.id: b};

    final nearby = <_NearbyBusEntry>[];
    for (final loc in locations) {
      final distKm = LocationService.distanceKm(
        pos.latitude, pos.longitude,
        loc.latitude, loc.longitude,
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
          target: _userPos ?? const LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
          zoom: _zoomForRadius(_radiusKm),
        )
      ));
    }
  }

  void _onSearchPressed() {
    final km = double.tryParse(_kmCtrl.text.trim()) ?? 10.0;
    setState(() => _radiusKm = km.clamp(1.0, 20.0));
    _kmCtrl.text = _radiusKm.toStringAsFixed(0);
    _loadData();
  }

  void _showBusDetail(_NearbyBusEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusDetailSheet(
        entry: entry,
        userPos: _userPos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {};
    if (_userPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('userLoc'),
        position: _userPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    
    for (int i = 0; i < _nearbyBuses.length; i++) {
        final e = _nearbyBuses[i];
        markers.add(Marker(
            markerId: MarkerId('bus_'+e.bus.id),
            position: LatLng(e.location.latitude, e.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                e.bus.isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: e.bus.number),
            onTap: () => _showBusDetail(e),
        ));
    }

    final Set<Circle> circles = {};
    if (_userPos != null) {
        circles.add(Circle(
            circleId: const CircleId('radius_circle'),
            center: _userPos!,
            radius: _radiusKm * 1000,
            fillColor: AppColors.info.withOpacity(0.07),
            strokeColor: AppColors.info.withOpacity(0.4),
            strokeWidth: 2,
        ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Buses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  // ── Range Input Panel ──────────────
                  _RangeInputPanel(
                    controller: _kmCtrl,
                    onSearch: _onSearchPressed,
                    radiusKm: _radiusKm,
                  ),

                  // ── Mini Map ───────────────────────
                  SizedBox(
                    height: 240,
                    child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                            target: _userPos ?? const LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
                            zoom: _zoomForRadius(_radiusKm),
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        markers: markers,
                        circles: circles,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                    ),
                  ),

                  // ── Count badge ─────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          _nearbyBuses.isEmpty
                              ? 'No buses within ${_radiusKm} km'
                              : '${_nearbyBuses.length} bus(es) within ${_radiusKm} km',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall,
                        ),
                        const Spacer(),
                        if (_nearbyBuses.isNotEmpty)
                          Text('Tap a marker for details',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted)),
                      ],
                    ),
                  ),

                  // ── Bus list ────────────────────────
                  Expanded(
                    child: _nearbyBuses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                        Icon(Icons.directions_bus_rounded,
                                            size: 64,
                                            color: Colors.grey.shade300)
                                    ]
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No buses within ${_radiusKm.toStringAsFixed(0)} km',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _nearbyBuses.length,
                            itemBuilder: (_, i) => _NearbyBusCard(
                              entry: _nearbyBuses[i],
                              index: i,
                              onTap: () => _showBusDetail(_nearbyBuses[i]),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  double _zoomForRadius(double km) {
    if (km <= 2) return 14.5;
    if (km <= 5) return 13.0;
    if (km <= 10) return 12.0;
    return 11.0;
  }
}


// ── Range Input Panel ─────────────────────────────────────────────────────────

class _RangeInputPanel extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final double radiusKm;

  const _RangeInputPanel({
    required this.controller,
    required this.onSearch,
    required this.radiusKm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? Colors.white : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.radar_rounded, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search Radius',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _MaxValueFormatter(20),
                        ],
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: accentColor),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('km',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                    const SizedBox(width: 4),
                    Text('(1–20)',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, size: 16),
            label: const Text('Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
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

  const _BusDetailSheet({required this.entry, required this.userPos});

  // Very simple ETA: distance / 30 km/h average
  String _eta() {
    final mins = (entry.distanceKm / 30.0 * 60).round();
    if (mins < 1) return '< 1 min';
    if (mins == 1) return '~1 min';
    return '~$mins mins';
  }

  // Whether this bus route passes near the user (simplified: true if dist < 5km)
  bool _passesNearUser() => entry.distanceKm < 5.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bus = entry.bus;
    final isActive = bus.isActive;
    final passesNear = _passesNearUser();
    final accentColor = isDark ? const Color(0xFF93C5FD) : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header row
          Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(colors: [
                          AppColors.success,
                          AppColors.success.withOpacity(0.7),
                        ])
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive
                              ? AppColors.success
                              : AppColors.primary)
                          .withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_bus_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bus.number,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? '● On Route' : '○ Idle',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(bus.route,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Info grid
          Row(
            children: [
              _InfoTile(
                icon: Icons.straighten_rounded,
                label: 'Distance',
                value: '${entry.distanceKm.toStringAsFixed(2)} km',
                color: AppColors.info,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                icon: Icons.access_time_rounded,
                label: 'Est. Arrival',
                value: _eta(),
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route near user banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: passesNear
                  ? AppColors.success.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: passesNear
                    ? AppColors.success.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  passesNear
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: passesNear ? AppColors.success : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    passesNear
                        ? 'This bus passes through your road or nearby road'
                        : 'This bus is in your area but on a different route',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: passesNear
                          ? AppColors.success
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stops
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Stops',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: bus.stops.asMap().entries.map((e) {
                final isLast = e.key == bus.stops.length - 1;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: e.key == 0
                            ? accentColor.withOpacity(0.14)
                            : isLast
                                ? AppColors.accent.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: e.key == 0
                              ? accentColor
                              : isLast
                                  ? AppColors.accentDark
                                  : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward_ios_rounded,
                            size: 9, color: AppColors.textMuted),
                      ),
                  ],
                );
              }).toList(),
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
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nearby Bus List Card ───────────────────────────────────────────────────────

class _NearbyBusCard extends StatefulWidget {
  final _NearbyBusEntry entry;
  final int index;
  final VoidCallback onTap;

  const _NearbyBusCard({
    required this.entry,
    required this.index,
    required this.onTap,
  });

  @override
  State<_NearbyBusCard> createState() => _NearbyBusCardState();
}

class _NearbyBusCardState extends State<_NearbyBusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final e = widget.entry;
    final isActive = e.bus.isActive;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppColors.success.withOpacity(0.25)
                    : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(colors: [
                            AppColors.success,
                            AppColors.success.withOpacity(0.7),
                          ])
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(e.bus.number,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.success.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'On Route' : 'Idle',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? AppColors.success
                                      : AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(e.bus.route,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.straighten_rounded,
                              size: 13, color: AppColors.info),
                          const SizedBox(width: 4),
                          Text(
                            '${e.distanceKm.toStringAsFixed(2)} km · ~${(e.distanceKm / 30.0 * 60).round()} mins',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _NearbyBusEntry {
  final BusModel bus;
  final BusLocationModel location;
  final double distanceKm;

  const _NearbyBusEntry({
    required this.bus,
    required this.location,
    required this.distanceKm,
  });
}

// ── Input formatter that caps value to max ────────────────────────────────────

class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  const _MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final val = int.tryParse(newValue.text);
    if (val == null) return oldValue;
    if (val > max) {
      return TextEditingValue(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    }
    return newValue;
  }
}
