// ====================================================
// features/map/track_bus_screen.dart — Bus selector for live tracking
// ====================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/error_handler.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/modern_bus_card.dart';
import 'map_tracking_screen.dart';

class TrackBusScreen extends ConsumerStatefulWidget {
  const TrackBusScreen({super.key});

  @override
  ConsumerState<TrackBusScreen> createState() => _TrackBusScreenState();
}

class _TrackBusScreenState extends ConsumerState<TrackBusScreen>
    with TickerProviderStateMixin {
  List<BusModel> _buses = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0; // 0 = Active on Route, 1 = Idle

  late AnimationController _fadeCtrl;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loadBuses();
    // Auto-refresh every 30 s to update active status
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadBuses(silent: true);
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBuses({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final buses =
          await ref.read(supabaseServiceProvider).fetchBuses();
      // Sort: active buses first, then alphabetically by number
      buses.sort((a, b) {
        if (a.isActive == b.isActive) {
          return a.number.compareTo(b.number);
        }
        return a.isActive ? -1 : 1;
      });
      if (mounted) {
        setState(() {
          _buses = buses;
          _isLoading = false;
          _error = null;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppErrorHandler.getFriendlyMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _trackBus(BusModel bus) {
    ref.read(selectedBusProvider.notifier).state = bus;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const MapTrackingScreen(),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: AppConstants.medAnim,
    ));
  }

  void _showBusDetails(BusModel bus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BusDetailSheet(
        bus: bus,
        onTrack: () {
          Navigator.pop(ctx); // Close sheet
          _trackBus(bus);     // Navigate to map
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCount = _buses.where((b) => b.isActive).length;
    final idleCount = _buses.length - activeCount;

    final displayedBuses = _selectedTab == 0
        ? _buses.where((b) => b.isActive).toList()
        : _buses.where((b) => !b.isActive).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bgDark : const Color(0xFFF6F8FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sliver App Bar with Segmented Control (Image 3) ────────
          SliverAppBar(
            expandedHeight: 184,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadBuses,
                tooltip: 'Refresh',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Track Bus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$activeCount buses currently active on route',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Segmented Tab Bar: [ ● Active on Route ] [ Scheduled / Idle ]
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              // Tab 0
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 0),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 0
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Active on Route ($activeCount)',
                                          style: TextStyle(
                                            color: _selectedTab == 0
                                                ? const Color(0xFF0A1F44)
                                                : Colors.white
                                                    .withValues(alpha: 0.85),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Tab 1
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 1),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Text(
                                      'Idle ($idleCount)',
                                      style: TextStyle(
                                        color: _selectedTab == 1
                                            ? const Color(0xFF0A1F44)
                                            : Colors.white
                                                .withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content List of Modern Bus Cards ──────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: _isLoading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const _SkeletonBusCard(),
                      childCount: 4,
                    ),
                  )
                : _error != null
                    ? SliverFillRemaining(
                        child: _ErrorState(
                          message: _error!,
                          onRetry: _loadBuses,
                        ),
                      )
                    : displayedBuses.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedTab == 0
                                        ? Icons.directions_bus_rounded
                                        : Icons.schedule_rounded,
                                    size: 48,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedTab == 0
                                        ? 'No buses currently on route'
                                        : 'No idle buses at this time',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final b = displayedBuses[i];
                                return ModernBusCard(
                                  bus: b,
                                  onTrack: () => _trackBus(b),
                                  onTap: () => _showBusDetails(b),
                                );
                              },
                              childCount: displayedBuses.length,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}



// ── Animated Bus Card ─────────────────────────────────────────────────────────

class _AnimatedBusCard extends StatefulWidget {
  final BusModel bus;
  final int index;
  final VoidCallback onTrack;
  final VoidCallback onCardTap;

  const _AnimatedBusCard({
    required this.bus,
    required this.index,
    required this.onTrack,
    required this.onCardTap,
  });

  @override
  State<_AnimatedBusCard> createState() => _AnimatedBusCardState();
}

class _AnimatedBusCardState extends State<_AnimatedBusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
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
        child: _BusTrackCard(
            bus: widget.bus,
            onTrack: widget.onTrack,
            onCardTap: widget.onCardTap),
      ),
    );
  }
}

// ── Bus Track Card ─────────────────────────────────────────────────────────────

class _BusTrackCard extends StatefulWidget {
  final BusModel bus;
  final VoidCallback onTrack;
  final VoidCallback onCardTap;

  const _BusTrackCard({
    required this.bus,
    required this.onTrack,
    required this.onCardTap,
  });

  @override
  State<_BusTrackCard> createState() => _BusTrackCardState();
}

class _BusTrackCardState extends State<_BusTrackCard>
    with SingleTickerProviderStateMixin {
  // Pulsing dot for active buses
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
        lowerBound: 0.6,
        upperBound: 1.0);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    if (widget.bus.isActive) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bus = widget.bus;
    final isActive = bus.isActive;

    final cardColor =
        isDark ? AppColors.cardDark : Colors.white;
    const statusLive = Color(0xFF059669);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onCardTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF242C3D)
                  : (isActive
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : const Color(0xFFEDF2F7)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.22)
                    : AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Bus number badge ───────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFFFC107).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      bus.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Route info ─────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bus.route,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0x1810B981)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive)
                                  ScaleTransition(
                                    scale: _pulse,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: statusLive,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? 'Live' : 'Idle',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? statusLive
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Stops preview
                      Text(
                        bus.stops.join(' → '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // ── Track button ───────────────────────
                GestureDetector(
                  onTap: widget.onTrack,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Track',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

// ── Skeleton loader ────────────────────────────────────────────────────────────

class _SkeletonBusCard extends StatefulWidget {
  const _SkeletonBusCard();

  @override
  State<_SkeletonBusCard> createState() => _SkeletonBusCardState();
}

class _SkeletonBusCardState extends State<_SkeletonBusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _shimmer = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final shimmerColor = isDark
            ? Color.lerp(
                const Color(0xFF2D3748), const Color(0xFF3D4B60), _shimmer.value)!
            : Color.lerp(
                const Color(0xFFE8EBF5), const Color(0xFFF6F8FF), _shimmer.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: shimmerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12, width: 160,
                      decoration: BoxDecoration(
                        color: shimmerColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10, width: 220,
                      decoration: BoxDecoration(
                        color: shimmerColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 70, height: 38,
                decoration: BoxDecoration(
                  color: shimmerColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bus detail bottom sheet ───────────────────────────────────────────────────

class _BusDetailSheet extends StatelessWidget {
  final BusModel bus;
  final VoidCallback onTrack;

  const _BusDetailSheet({required this.bus, required this.onTrack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = bus.isActive;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
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
                                ? AppColors.success.withValues(alpha: 0.12)
                                : Colors.grey.withValues(alpha: 0.1),
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
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : isLast
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: e.key == 0
                              ? AppColors.primary
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
          const SizedBox(height: 24),
          
          // Track button inside sheet
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTrack,
              icon: const Icon(Icons.gps_fixed_rounded, size: 20),
              label: const Text('Track on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
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

