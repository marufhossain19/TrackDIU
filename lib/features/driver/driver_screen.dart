// ====================================================
// features/driver/driver_screen.dart — GPS driver (instant sharing)
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/animated_button.dart';

class DriverScreen extends ConsumerStatefulWidget {
  const DriverScreen({super.key});

  @override
  ConsumerState<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends ConsumerState<DriverScreen>
    with TickerProviderStateMixin {
  double? _lat, _lng, _speed;

  DriverProfileModel? _profile;
  bool _isTracking = false;
  bool _isLoading  = true;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    _loadData().then((_) {
      // Auto-resume tracking if it was enabled previously
      final isSharing = Hive.box(AppConstants.settingsBox).get('is_sharing_location', defaultValue: false);
      if (isSharing == true) {
        // Only auto-resume if they can share (have bus/profile)
        final canShare = _profile?.busNumber != null && (_profile?.name.isNotEmpty ?? false);
        if (canShare) {
          _beginTracking();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    ref.read(locationServiceProvider).stopTracking();
    super.dispose();
  }

  Future<void> _loadData() async {
    final svc  = ref.read(supabaseServiceProvider);
    final user = svc.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }

    final profile = await svc.fetchDriverProfile(user.id);

    if (mounted) {
      setState(() {
        _profile   = profile;
        _isLoading = false;
      });
      ref.read(driverProfileProvider.notifier).state = profile;
    }
  }

  // Resolve busId: use profile.busId if set, else look it up by busNumber
  Future<String?> _resolveBusId() async {
    if (_profile?.busId != null) return _profile!.busId;
    final busNumber = _profile?.busNumber;
    if (busNumber == null) return null;
    final buses = await ref.read(supabaseServiceProvider).fetchBuses();
    return buses
        .where((b) => b.number.toUpperCase() == busNumber.toUpperCase())
        .firstOrNull
        ?.id;
  }

  Future<void> _beginTracking() async {
    // Resolve busId — from profile or by looking up busNumber in buses table
    final busId = await _resolveBusId();

    if (busId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Bus not found in system. Ask admin to add your bus first.'),
          duration: Duration(seconds: 4),
        ));
      }
      return;
    }

    setState(() => _isTracking = true);
    ref.read(isTrackingProvider.notifier).state = true;
    
    // Save state to Hive
    Hive.box(AppConstants.settingsBox).put('is_sharing_location', true);

    ref.read(locationServiceProvider).startTracking(
      onUpdate: (pos) async {
        if (mounted) {
          setState(() {
            _lat   = pos.latitude;
            _lng   = pos.longitude;
            _speed = pos.speed * 3.6;
          });
        }
        try {
          await ref.read(supabaseServiceProvider).upsertBusLocation(
            busId: busId,
            lat  : pos.latitude,
            lng  : pos.longitude,
            speed: pos.speed * 3.6,
          );
        } catch (_) {}
      },
    );
  }

  void _stopTracking() {
    ref.read(locationServiceProvider).stopTracking();
    ref.read(isTrackingProvider.notifier).state = false;
    setState(() {
      _isTracking = false;
      _lat = null; _lng = null; _speed = null;
    });
    
    // Clear state from Hive
    Hive.box(AppConstants.settingsBox).put('is_sharing_location', false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // canShare only needs busNumber + name — busId is resolved at tracking time
    final canShare = _profile?.busNumber != null &&
        _profile!.name.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Mode')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [

                    // ── Profile Summary Card ─────────────────
                    if (_profile != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile!.name.isNotEmpty
                                        ? _profile!.name
                                        : 'No name set',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 3),
                                  if (_profile!.busNumber != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_bus_rounded,
                                            size: 14, color: AppColors.success),
                                        const SizedBox(width: 4),
                                        Text('Bus ${_profile!.busNumber!}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.success,
                                            )),
                                      ],
                                    )
                                  else
                                    const Text('No bus assigned yet',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── No profile / bus warning ─────────────
                    if (!canShare) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppColors.warning, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Go to Profile → set your name and request a '
                                'bus number. Once the admin approves, you can '
                                'share your location.',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Status Circle ────────────────────────
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _isTracking ? _pulseAnim.value : 1.0,
                        child: child,
                      ),
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isTracking
                                ? [AppColors.success, const Color(0xFF059669)]
                                : canShare
                                    ? [AppColors.primary, const Color(0xFF1E40AF)]
                                    : [Colors.grey.shade400, Colors.grey.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isTracking
                                      ? AppColors.success
                                      : canShare
                                          ? AppColors.primary
                                          : Colors.grey)
                                  .withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: _isTracking ? 10 : 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isTracking
                                  ? Icons.gps_fixed_rounded
                                  : Icons.share_location_rounded,
                              color: Colors.white, size: 48),
                            const SizedBox(height: 10),
                            Text(
                              _isTracking ? 'Sharing Live' : 'Location Off',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── GPS Info ─────────────────────────────
                    if (_isTracking && _lat != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _InfoRow(icon: Icons.location_on_rounded,
                                label: 'Latitude',
                                value: _lat!.toStringAsFixed(6),
                                color: AppColors.info),
                            const Divider(height: 24),
                            _InfoRow(icon: Icons.location_on_rounded,
                                label: 'Longitude',
                                value: _lng!.toStringAsFixed(6),
                                color: AppColors.info),
                            const Divider(height: 24),
                            _InfoRow(icon: Icons.speed_rounded,
                                label: 'Speed',
                                value: '${_speed?.toStringAsFixed(1) ?? '0'} km/h',
                                color: AppColors.success),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Action Button ─────────────────────────
                    if (_isTracking)
                      AnimatedButton(
                        onTap: _stopTracking,
                        gradient: const LinearGradient(
                          colors: [AppColors.error, Color(0xFFDC2626)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        width: double.infinity,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stop_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text('Stop Sharing',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                )),
                          ],
                        ),
                      )
                    else
                      AnimatedButton(
                        onTap: canShare ? _beginTracking : null,
                        gradient: LinearGradient(
                          colors: canShare
                              ? [AppColors.success, const Color(0xFF059669)]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        width: double.infinity,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_location_rounded,
                                color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text('Share Your Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                )),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Info Note ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.info.withOpacity(0.25)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.info, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tap the button to instantly share your live '
                              'location with students. Updates every 30 s '
                              'or when moved 10+ metres.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
