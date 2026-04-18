// ====================================================
// features/profile/profile_screen.dart
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../features/auth/role_selection_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  DriverProfileModel? _profile;
  DriverRequestModel? _pendingBusReq;

  final _nameCtrl   = TextEditingController();
  final _busCtrl    = TextEditingController();
  bool _savingName  = false;
  bool _sendingBus  = false;
  bool _isLoading   = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _busCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final svc  = ref.read(supabaseServiceProvider);
    final user = svc.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }

    final role = ref.read(userRoleProvider);
    final profile = await svc.fetchDriverProfile(user.id);
    List<DriverRequestModel> reqs = [];
    if (role == UserRole.driver) {
      reqs = await svc.fetchMyRequests(user.id);
    }

    final pendingBus = reqs.where(
        (r) => r.type == 'bus_assignment' && r.isPending).firstOrNull;

    if (mounted) {
      setState(() {
        _profile     = profile;
        _pendingBusReq = pendingBus;
        _isLoading   = false;
        _nameCtrl.text = profile?.name ?? '';
        _busCtrl.text  = '';
      });
      ref.read(driverProfileProvider.notifier).state = profile;
      _fadeCtrl.forward();
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final svc  = ref.read(supabaseServiceProvider);
    final user = svc.currentUser;
    if (user == null) return;
    setState(() => _savingName = true);
    final updated = DriverProfileModel(
      id: _profile?.id ?? '',
      userId: user.id,
      name: name,
      busNumber: _profile?.busNumber,
      busId: _profile?.busId,
    );
    await svc.upsertDriverProfile(updated);
    await _loadProfile();
    setState(() => _savingName = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name saved!')));
    }
  }

  Future<void> _requestBus() async {
    final bus  = _busCtrl.text.trim().toUpperCase();
    if (bus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bus number')));
      return;
    }
    final name = _profile?.name ?? _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save your name first')));
      return;
    }
    final svc  = ref.read(supabaseServiceProvider);
    final user = svc.currentUser;
    if (user == null) return;
    setState(() => _sendingBus = true);
    await svc.submitRequest(
      driverUserId: user.id,
      driverName  : name,
      type        : 'bus_assignment',
      requestedBus: bus,
    );
    _busCtrl.clear();
    await _loadProfile();
    setState(() => _sendingBus = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus number request sent to admin!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role    = ref.watch(userRoleProvider);
    final isDark  = ref.watch(themeModeProvider);
    final svc     = ref.read(supabaseServiceProvider);
    final user    = svc.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // ── Avatar ──────────────────────
                    Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.email ?? 'Not logged in',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    // ── Driver-only section ──────────────────
                    if (role == UserRole.driver) ...[
                      const SizedBox(height: 28),
                      _SectionHeader(title: 'Driver Info'),
                      const SizedBox(height: 14),

                      // Confirmed bus number badge
                      if (_profile?.busNumber != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.success.withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_bus_rounded,
                                    color: AppColors.success, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Assigned Bus',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    _profile!.busNumber!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.verified_rounded,
                                  color: AppColors.success, size: 22),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Pending bus request banner
                      if (_pendingBusReq != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFF59E0B).withOpacity(0.45)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded,
                                  color: Color(0xFFF59E0B), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your bus number request (${_pendingBusReq!.requestedBus}) '
                                  'is waiting for admin approval.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Name input
                      _InputCard(
                        label: 'Your Name',
                        controller: _nameCtrl,
                        icon: Icons.badge_rounded,
                        hint: 'Enter your full name',
                        action: _savingName
                            ? null
                            : _saveName,
                        actionLabel: _savingName ? 'Saving...' : 'Save Name',
                        actionColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),

                      // Bus number input — always visible unless a request is pending
                      if (_pendingBusReq == null)
                        _InputCard(
                          label: _profile?.busNumber != null
                              ? 'Change Bus Number'
                              : 'Request Bus Number',
                          controller: _busCtrl,
                          icon: Icons.directions_bus_rounded,
                          hint: _profile?.busNumber != null
                              ? 'Current: ${_profile!.busNumber!}  →  New: e.g. B-02'
                              : 'e.g. B-01',
                          action: _sendingBus ? null : _requestBus,
                          actionLabel: _sendingBus ? 'Sending...' : 'Send Request',
                          actionColor: AppColors.warning,
                        ),
                    ],

                    const SizedBox(height: 28),

                    // ── Settings ─────────────────────────────
                    _SectionHeader(title: 'Settings'),
                    const SizedBox(height: 14),
                    _SettingsTile(
                      icon: isDark
                          ? Icons.wb_sunny_rounded
                          : Icons.nightlight_round,
                      label: isDark ? 'Light Mode' : 'Dark Mode',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (v) =>
                            ref.read(themeModeProvider.notifier).state = v,
                        activeColor: AppColors.primary,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'App Version',
                      trailing: const Text('1.0.0',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                    _SettingsTile(
                      icon: Icons.school_rounded,
                      label: 'University',
                      trailing: const Text('Daffodil International',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ),
                    const SizedBox(height: 24),

                    // ── Logout ─────────────────────────────
                    GestureDetector(
                      onTap: () async {
                        await ref.read(supabaseServiceProvider).signOut();
                        ref.read(isLoggedInProvider.notifier).state = false;
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const RoleSelectionScreen()),
                            (_) => false,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: AppColors.error, size: 20),
                            SizedBox(width: 10),
                            Text('Logout',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.primary,
          )),
    );
  }
}

// ── Input Card ───────────────────────────────────────────────
class _InputCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final VoidCallback? action;
  final String actionLabel;
  final Color actionColor;

  const _InputCard({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    required this.action,
    required this.actionLabel,
    required this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    prefixIcon: Icon(icon, color: iconColor, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: actionColor, width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: Text(actionLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          trailing,
        ],
      ),
    );
  }
}
