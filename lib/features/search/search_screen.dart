// ====================================================
// features/search/search_screen.dart — Modern Bus Search + Filter
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/modern_bus_card.dart';
import '../map/map_tracking_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedTimeFilter = 'All Times';
  final List<String> _timeFilters = const ['All Times', '7:00 AM', '12:00 PM', '5:00 PM'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  bool _matchesTime(List<String> departures, String filter) {
    if (filter == 'All Times') return true;
    final f = filter.toLowerCase().replaceAll(' ', '');
    for (final d in departures) {
      final formatted = _formatTime(d).toLowerCase().replaceAll(' ', '');
      if (formatted == f || formatted.contains(f.replaceAll(':00', ''))) {
        return true;
      }
    }
    return false;
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedulesAsync = ref.watch(busSchedulesProvider);
    final fallbackBusesAsync = ref.watch(busListProvider);
    final queryText = _searchCtrl.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── Dark Navy Top Header (Matching Reference Image 4) ──
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with back button
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Buses',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Filter by destination stop or departure slot',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Search box
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search destination or stop, e.g., Mirpur, Uttara, Dh',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Time filter pills row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _timeFilters.map((filter) {
                      final isSelected = _selectedTimeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTimeFilter = filter;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF0A1F44)
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Results Content ──
          Expanded(
            child: schedulesAsync.when(
              data: (schedules) {
                // If schedules are empty, use fallback buses
                final items = schedules.isNotEmpty
                    ? schedules
                    : fallbackBusesAsync.asData?.value
                            .map((b) => BusWithSchedule(
                                  bus: b,
                                  departureTimes: const ['07:00', '12:00', '17:00'],
                                ))
                            .toList() ??
                        [];

                // Filter items
                final filtered = items.where((item) {
                  final bus = item.bus;
                  // Time filter
                  if (!_matchesTime(item.departureTimes, _selectedTimeFilter)) {
                    return false;
                  }
                  // Query filter
                  if (queryText.isEmpty) return true;
                  final matchRoute = bus.route.toLowerCase().contains(queryText);
                  final matchNumber = bus.number.toLowerCase().contains(queryText);
                  final matchStop = bus.stops.any((s) => s.toLowerCase().contains(queryText));
                  return matchRoute || matchNumber || matchStop;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subheader: AVAILABLE BUSES (X)   All Times
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AVAILABLE BUSES (${filtered.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            _selectedTimeFilter,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List of ModernBusCard
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    queryText.isNotEmpty
                                        ? 'No buses found for "$queryText"'
                                        : 'No buses matching "$_selectedTimeFilter"',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ModernBusCard(
                                  bus: item.bus,
                                  departureTimes: item.departureTimes,
                                  onTrack: () => _navigateToTracking(item.bus),
                                  onTap: () => _navigateToTracking(item.bus),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  height: 160,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              error: (_, __) => fallbackBusesAsync.when(
                data: (buses) {
                  final filtered = buses.where((bus) {
                    if (queryText.isEmpty) return true;
                    final matchRoute = bus.route.toLowerCase().contains(queryText);
                    final matchNumber = bus.number.toLowerCase().contains(queryText);
                    final matchStop = bus.stops.any((s) => s.toLowerCase().contains(queryText));
                    return matchRoute || matchNumber || matchStop;
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bus = filtered[index];
                      return ModernBusCard(
                        bus: bus,
                        onTrack: () => _navigateToTracking(bus),
                        onTap: () => _navigateToTracking(bus),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Error loading buses. Check connection.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
