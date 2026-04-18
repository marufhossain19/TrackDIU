// ====================================================
// widgets/app_bottom_nav_bar.dart
// bKash-style flat + semi-transparent bottom nav bar
// ====================================================
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single navigation destination descriptor.
class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}

/// The four nav destinations used across the app.
const List<NavItem> kNavItems = [
  NavItem(icon: Icons.home_rounded,        label: 'Home'),
  NavItem(icon: Icons.credit_card_rounded, label: 'Cards'),
  NavItem(icon: Icons.inbox_rounded,       label: 'Inbox'),
  NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
];

/// Active color for **light** mode — matches your existing brand blue.
const Color _kLightActive = Color(0xFF1D4ED8);

/// Active color for **dark** mode — pure white as per spec.
const Color _kDarkActive = Colors.white;

/// Inactive color (same for both modes, differs in lightness via theme).
const Color _kLightInactive = Color(0xFF94A3B8); // slate-400
const Color _kDarkInactive  = Color(0xFF6B7280); // gray-500

/// Background opacity values.
const double _kLightBgOpacity = 0.90;
const double _kDarkBgOpacity  = 0.85;

/// ─────────────────────────────────────────────────────────────
/// [AppBottomNavBar]
///
/// Drop-in replacement for [BottomNavigationBar].
/// Attach directly to [Scaffold.bottomNavigationBar].
///
/// ```dart
/// Scaffold(
///   bottomNavigationBar: AppBottomNavBar(
///     currentIndex: _index,
///     onTap: (i) => setState(() => _index = i),
///   ),
/// )
/// ```
/// ─────────────────────────────────────────────────────────────
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = kNavItems,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // ── Semi-transparent background colour ──────────────
    final bgColor = isDark
        ? Color.fromRGBO(10, 10, 12, _kDarkBgOpacity)
        : Color.fromRGBO(255, 255, 255, _kLightBgOpacity);

    return ClipRect(
      child: BackdropFilter(
        // Subtle backdrop blur — glass feel without heavy frosting.
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          // ── Zero border-radius, no shadow, no elevation ──
          decoration: BoxDecoration(
            color: bgColor,
            // Single top hairline separator that fades gracefully.
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
            ),
          ),
          // Bottom padding = system safe-area so content clears home indicator.
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10 + bottomInset,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              items.length,
              (index) => _NavBarButton(
                item: items[index],
                isActive: index == currentIndex,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Individual tappable nav item — icon + label with smooth
/// animated colour transition (no scale, no lift).
/// ─────────────────────────────────────────────────────────────
class _NavBarButton extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor   = isDark ? _kDarkActive  : _kLightActive;
    final inactiveColor = isDark ? _kDarkInactive : _kLightInactive;
    final targetColor   = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Icon ─────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Icon(
                item.icon,
                key: ValueKey('${item.label}_$isActive'),
                size: 24,
                color: targetColor,
              ),
            ),
            const SizedBox(height: 4),
            // ── Label ────────────────────────────────────
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: targetColor,
                letterSpacing: 0.1,
                height: 1,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
