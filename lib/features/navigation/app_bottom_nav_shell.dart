// ====================================================
// features/navigation/app_bottom_nav_shell.dart
// Shell that hosts the four root tabs + glass nav bar.
// ====================================================
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/app_providers.dart';
import '../cards/my_transport_card_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../home/home_dashboard.dart';
import '../inbox/inbox_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell widget
// ─────────────────────────────────────────────────────────────────────────────

class AppBottomNavShell extends ConsumerStatefulWidget {
  const AppBottomNavShell({super.key});

  @override
  ConsumerState<AppBottomNavShell> createState() => _AppBottomNavShellState();
}

class _AppBottomNavShellState extends ConsumerState<AppBottomNavShell> {
  static const _lastSeenKey = 'notifications_last_seen_id';

  int _currentIndex = 0;
  String? _lastSeenNotificationId;
  bool _showInboxBadge = false;
  RealtimeChannel? _notificationChannel;

  late final List<Widget> _tabs = [
    const HomeDashboard(),
    const MyTransportCardScreen(),
    InboxScreen(onInboxOpened: _markInboxAsSeen),
    const ChatbotScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadLastSeenNotificationId();
    _notificationChannel =
        ref.read(supabaseServiceProvider).subscribeToNotifications(() async {
      ref.invalidate(transportNotificationsProvider);
      await _refreshBadge();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshBadge());
  }

  @override
  void dispose() {
    if (_notificationChannel != null) {
      ref.read(supabaseServiceProvider).unsubscribe(_notificationChannel!);
    }
    super.dispose();
  }

  Future<void> _loadLastSeenNotificationId() async {
    final settings = Hive.box(AppConstants.settingsBox);
    _lastSeenNotificationId = settings.get(_lastSeenKey) as String?;
    await _refreshBadge();
  }

  Future<void> _refreshBadge() async {
    final items = await ref.read(supabaseServiceProvider).fetchNotifications();
    if (!mounted) return;
    if (items.isEmpty) {
      setState(() => _showInboxBadge = false);
      return;
    }
    setState(() => _showInboxBadge = items.first.id != _lastSeenNotificationId);
  }

  Future<void> _markInboxAsSeen() async {
    final items = await ref.read(supabaseServiceProvider).fetchNotifications();
    if (items.isEmpty) {
      if (mounted) setState(() => _showInboxBadge = false);
      return;
    }
    _lastSeenNotificationId = items.first.id;
    await Hive.box(AppConstants.settingsBox)
        .put(_lastSeenKey, _lastSeenNotificationId);
    if (mounted) setState(() => _showInboxBadge = false);
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    if (index == 2) _markInboxAsSeen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _GlassNavBar(
        currentIndex: _currentIndex,
        showInboxBadge: _showInboxBadge,
        onTap: _onTabSelected,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlassNavBar
// Flat, full-width, zero border-radius, no shadow, no elevation.
// Semi-transparent + BackdropFilter blur (glass feel).
// ─────────────────────────────────────────────────────────────────────────────

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final bool showInboxBadge;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.currentIndex,
    required this.showInboxBadge,
    required this.onTap,
  });

  static const _descriptors = <_NavDescriptor>[
    _NavDescriptor(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDescriptor(
      label: 'Cards',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card_rounded,
    ),
    _NavDescriptor(
      label: 'Notices',
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
    ),
    _NavDescriptor(
      label: 'Chat',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // ── Spec background values ───────────────────────────────────────────────
    //   Light → rgba(255, 255, 255, 0.90)
    //   Dark  → rgba(0, 0, 0, 0.85)
    final bgColor = isDark
        ? const Color(0xFF0A0A0C).withOpacity(0.85)
        : Colors.white.withOpacity(0.90);

    return ClipRect(
      child: BackdropFilter(
        // Subtle glass blur — non-aggressive, fintech-style
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          // Zero border-radius | zero shadow | zero elevation
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
            ),
          ),
          // Top padding + home-indicator safe-area at bottom
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10 + bottomInset,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_descriptors.length, (i) {
              return _NavBarItem(
                descriptor: _descriptors[i],
                isActive: i == currentIndex,
                isDark: isDark,
                showBadge: i == 2 && showInboxBadge,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavDescriptor — immutable data carrier for each tab.
// ─────────────────────────────────────────────────────────────────────────────

class _NavDescriptor {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavDescriptor({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavBarItem — a single tappable destination.
// Colour transition only; no scaling, no lifting (spec).
// ─────────────────────────────────────────────────────────────────────────────

class _NavBarItem extends StatelessWidget {
  final _NavDescriptor descriptor;
  final bool isActive;
  final bool isDark;
  final bool showBadge;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.descriptor,
    required this.isActive,
    required this.isDark,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ── Colour spec ─────────────────────────────────────────────────────────
    //   Light  active:   brand blue (AppColors.primary)
    //   Light  inactive: slate-400 (#94A3B8)
    //   Dark   active:   pure white (#FFFFFF)   ← spec: no brand colour in dark
    //   Dark   inactive: gray-500  (#6B7280)
    final activeColor   = isDark ? Colors.white            : AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);
    final color         = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon + optional notification dot ────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Smooth colour crossfade — no scale, no translate (spec)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Icon(
                    isActive ? descriptor.selectedIcon : descriptor.icon,
                    key: ValueKey<String>('${descriptor.label}_$isActive'),
                    size: 24,
                    color: color,
                  ),
                ),
                if (showBadge)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: _InboxBadge(),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Label — animated weight + colour ────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
                height: 1.0,
              ),
              child: Text(descriptor.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InboxBadge — red notification dot, unchanged from original.
// ─────────────────────────────────────────────────────────────────────────────

class _InboxBadge extends StatelessWidget {
  const _InboxBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.3),
      ),
    );
  }
}
