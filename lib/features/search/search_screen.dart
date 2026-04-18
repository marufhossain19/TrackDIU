// ====================================================
// features/search/search_screen.dart — Bus search + results + schedule
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/animated_button.dart';
import '../map/map_tracking_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  TimeOfDay? _selectedTime;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final q = _searchCtrl.text.trim();
    ref.read(searchQueryProvider.notifier).state = q;
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query   = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search Buses')),
      body: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Search Input ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter destination (e.g. Mirpur)',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Time picker
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.cardDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2D3748)
                              : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            _selectedTime?.format(context) ?? 'Time',
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Search Button (white text) ─────────
              AnimatedButton(
                onTap: _search,
                gradient: AppColors.primaryGradient,
                width: double.infinity,
                child: const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Content area ──────────────────────
              Expanded(
                child: query.isEmpty
                    ? _IdleContent(onDestinationTap: (dest) {
                        _searchCtrl.text = dest;
                        ref.read(searchQueryProvider.notifier).state = dest;
                      })
                    : _ResultsContent(results: results, query: query),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Idle state: popular destinations + bus schedule ──────────────────────────

class _IdleContent extends ConsumerWidget {
  final void Function(String) onDestinationTap;
  const _IdleContent({required this.onDestinationTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDark ? const Color(0xFF93C5FD) : AppColors.primary;
    final schedulesAsync = ref.watch(busSchedulesProvider);

    return schedulesAsync.when(
      loading: () => ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => const SkeletonBusCard(),
      ),
      error: (_, __) => const Center(
        child: Text('Could not load schedules. Check connection.',
            style: TextStyle(color: AppColors.textMuted)),
      ),
      data: (busSchedules) {
        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Popular destinations chips (from DB)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Popular Destinations',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: busSchedules
                  .map((bs) => bs.bus.route.split(' → ').first)
                  .toSet() // Remove duplicates
                  .map((dest) {
                return GestureDetector(
                  onTap: () => onDestinationTap(dest),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A8A).withOpacity(0.35)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isDark
                              ? chipColor.withOpacity(0.35)
                              : AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(dest,
                        style: TextStyle(
                          color: chipColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Bus Schedule ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bus Schedule',
                    style: Theme.of(context).textTheme.headlineSmall),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Live',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Buses currently on-route are highlighted in green',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),

            // Schedule cards — one per bus (from DB)
            ...busSchedules
                .map((bs) => _RouteScheduleCard(busWithSchedule: bs)),
          ],
        );
      },
    );
  }
}

// ── Schedule card for one route ───────────────────────────────────────────────

class _RouteScheduleCard extends StatelessWidget {
  final BusWithSchedule busWithSchedule;

  const _RouteScheduleCard({required this.busWithSchedule});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bus = busWithSchedule.bus;
    final routeStr = bus.route;
    final busNumber = bus.number;
    final stops = bus.stops;
    final isActive = bus.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive
              ? AppColors.success.withOpacity(0.35)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [
                        AppColors.success.withOpacity(0.15),
                        AppColors.success.withOpacity(0.05),
                      ]
                    : [
                        AppColors.primary.withOpacity(0.06),
                        AppColors.primary.withOpacity(0.02),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Bus number badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive
                                ? AppColors.success
                                : AppColors.primary)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    busNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    routeStr,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isActive ? 'On Route' : 'Idle',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stops + Schedule body ───────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stops row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stops.asMap().entries.map((e) {
                      final isLast = e.key == stops.length - 1;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: e.key == 0
                                  ? AppColors.primary.withOpacity(0.1)
                                  : isLast
                                      ? AppColors.accent.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 11,
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
                              padding:
                                  EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 9,
                                  color: AppColors.textMuted),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Departure times
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Departures:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    ...busWithSchedule.departureTimes
                        .map((t) => _TimeChip(time: _formatTime(t), isActive: isActive)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formats 24h "07:00" → "7:00 AM", "17:30" → "5:30 PM"
  static String _formatTime(String t) {
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1].padLeft(2, '0');
      final suffix = h < 12 ? 'AM' : 'PM';
      h = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h:$m $suffix';
    } catch (_) {
      return t;
    }
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final bool isActive;
  const _TimeChip({required this.time, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Results content ───────────────────────────────────────────────────────────

class _ResultsContent extends ConsumerWidget {
  final AsyncValue<List<BusModel>> results;
  final String query;
  const _ResultsContent({required this.results, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Results',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Expanded(
          child: results.when(
            data: (buses) {
              if (buses.isEmpty) {
                return _EmptyState(
                    message:
                        'No buses found for "$query"');
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: buses.length,
                itemBuilder: (_, i) => BusCard(
                  busNumber    : buses[i].number,
                  route        : buses[i].route,
                  departureTime: '7:00 AM, 12:00 PM, 5:00 PM',
                  isActive     : buses[i].isActive,
                  animIndex    : i,
                  onTrack      : () {
                    ref.read(selectedBusProvider.notifier).state =
                        buses[i];
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (_, a, __) =>
                          const MapTrackingScreen(),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(opacity: a, child: child),
                      transitionDuration: AppConstants.medAnim,
                    ));
                  },
                ),
              );
            },
            loading: () => ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const SkeletonBusCard(),
            ),
            error: (e, _) => const _EmptyState(
                message: 'Error loading buses. Check connection.'),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
