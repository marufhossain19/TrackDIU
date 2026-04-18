// ====================================================
// features/auth/role_selection_screen.dart
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/animated_button.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // ── Header ────────────────────────────
                const Text(
                  'Welcome to\nTrackDIU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your role to continue',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 48),
                // ── Role Cards ────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      _RoleCard(
                        title: 'Student',
                        subtitle: 'Track buses & view schedules',
                        icon: Icons.school_rounded,
                        role: UserRole.student,
                        delay: 0,
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        title: 'Driver',
                        subtitle: 'Share your live GPS location',
                        icon: Icons.drive_eta_rounded,
                        role: UserRole.driver,
                        delay: 100,
                      ),
                      const SizedBox(height: 16),
                      _RoleCard(
                        title: 'Admin',
                        subtitle: 'Manage buses & system',
                        icon: Icons.admin_panel_settings_rounded,
                        role: UserRole.admin,
                        delay: 200,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final UserRole role;
  final int delay;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.role,
    required this.delay,
  });

  @override
  ConsumerState<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends ConsumerState<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
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
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedButton(
          onTap: () {
            ref.read(userRoleProvider.notifier).state = widget.role;
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, anim, __) => const LoginScreen(),
                transitionsBuilder: (_, anim, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0), end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  );
                },
                transitionDuration: AppConstants.medAnim,
              ),
            );
          },
          color: Colors.white,
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
