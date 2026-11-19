// ====================================================
// features/admin/admin_panel_screen.dart — Business-Ready Fleet Console
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/error_handler.dart';
import '../../core/theme.dart';
import '../../models/bus_model.dart';
import '../../providers/app_providers.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0; // 0 = Fleet Buses, 1 = Requests, 2 = Schedules, 3 = Broadcast
  final _busSearchCtrl = TextEditingController();
  int _busFilterStatus = 0; // 0 = All, 1 = Active, 2 = Idle

  int _reqFilterStatus = 0; // 0 = All, 1 = Pending, 2 = Approved, 3 = Rejected

  List<BusModel> _buses = [];
  List<DriverRequestModel> _requests = [];
  bool _busLoading = true;
  bool _reqLoading = true;

  RealtimeChannel? _reqChannel;
  final TextEditingController _notificationCtrl = TextEditingController();
  _NotificationSendMode _notificationSendMode = _NotificationSendMode.replaceOld;
  bool _sendingNotification = false;

  @override
  void initState() {
    super.initState();
    _busSearchCtrl.addListener(() => setState(() {}));
    _loadBuses();
    _loadRequests();

    // Real-time: notify admin when new request arrives
    _reqChannel = ref.read(supabaseServiceProvider).subscribeToAllRequests(
      (newReq) {
        if (mounted) {
          setState(() => _requests.insert(0, newReq));
        }
      },
    );
  }

  @override
  void dispose() {
    _busSearchCtrl.dispose();
    _notificationCtrl.dispose();
    if (_reqChannel != null) {
      ref.read(supabaseServiceProvider).unsubscribe(_reqChannel!);
    }
    super.dispose();
  }

  Future<void> _loadBuses() async {
    setState(() => _busLoading = true);
    try {
      final buses = await ref.read(supabaseServiceProvider).fetchBuses();
      if (mounted) {
        setState(() {
          _buses = buses;
          _busLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _reqLoading = true);
    try {
      final reqs = await ref.read(supabaseServiceProvider).fetchAllRequests();
      if (mounted) {
        setState(() {
          _requests = reqs;
          _reqLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reqLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendTransportNotification() async {
    if (_sendingNotification) return;
    final message = _notificationCtrl.text.trim();
    if (_notificationSendMode != _NotificationSendMode.clearAll &&
        message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an announcement message.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sendingNotification = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      if (_notificationSendMode == _NotificationSendMode.replaceOld) {
        await service.replaceTransportNotifications(message);
      } else if (_notificationSendMode == _NotificationSendMode.keepOldAddNew) {
        await service.addTransportNotification(message);
      } else {
        await service.clearTransportNotifications();
      }

      if (!mounted) return;
      _notificationCtrl.clear();
      ref.invalidate(transportNotificationsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notificationSendMode == _NotificationSendMode.clearAll
                ? 'All announcements cleared.'
                : 'Announcement broadcasted to campus riders.',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.getFriendlyMessage(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingNotification = false);
    }
  }

  void _showBusDialog({BusModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusEditorSheet(
        existing: existing,
        allBuses: _buses,
        onSaved: () {
          Navigator.pop(context);
          _loadBuses();
        },
      ),
    );
  }

  Future<void> _deleteBus(String busId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Bus?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this bus? This will remove it from the system.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(supabaseServiceProvider).deleteBus(busId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bus removed successfully.'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadBuses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppErrorHandler.getFriendlyMessage(e)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showReviewDialog(DriverRequestModel req) {
    final assignCtrl = TextEditingController(text: req.requestedBus ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1F44).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                req.type == 'bus_assignment'
                    ? Icons.directions_bus_rounded
                    : Icons.share_location_rounded,
                color: const Color(0xFF0A1F44),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                req.type == 'bus_assignment'
                    ? 'Review Bus Assignment'
                    : 'Review Live Sharing',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0A1F44),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReqInfoRow(label: 'Driver Name', value: req.driverName),
            if (req.requestedBus != null)
              _ReqInfoRow(label: 'Target Bus', value: req.requestedBus!),
            _ReqInfoRow(label: 'Date', value: req.validDate),
            if (req.type == 'bus_assignment') ...[
              const SizedBox(height: 12),
              const Text(
                'Assign Bus Number:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: assignCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. B-01',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(supabaseServiceProvider).reviewRequest(
                      requestId: req.id,
                      status: 'rejected',
                      driverUserId: req.driverUserId,
                    );
                if (mounted) {
                  Navigator.pop(context);
                  _loadRequests();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppErrorHandler.getFriendlyMessage(e)),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final assignedBus = req.type == 'bus_assignment'
                    ? assignCtrl.text.trim().toUpperCase()
                    : req.requestedBus;

                String? busId;
                if (assignedBus != null) {
                  final buses =
                      await ref.read(supabaseServiceProvider).fetchBuses();
                  busId = buses.where((b) => b.number == assignedBus).firstOrNull?.id;
                }

                await ref.read(supabaseServiceProvider).reviewRequest(
                      requestId: req.id,
                      status: 'approved',
                      assignedBus: assignedBus,
                      assignedBusId: busId,
                      driverUserId: req.driverUserId,
                    );
                if (mounted) {
                  Navigator.pop(context);
                  _loadRequests();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppErrorHandler.getFriendlyMessage(e)),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A1F44),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Approve & Dispatch'),
          ),
        ],
      ),
    );
  }

  void _showScheduleEditor(
      BuildContext ctx, WidgetRef ref, BusWithSchedule bs) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusScheduleEditorSheet(
        busWithSchedule: bs,
        onSaved: () {
          ref.invalidate(busSchedulesProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingCount = _requests.where((r) => r.isPending).length;
    final activeBusesCount = _buses.where((b) => b.isActive).length;
    final totalCorridors = _buses.map((b) => b.route).toSet().length;

    // Filter buses
    final busQuery = _busSearchCtrl.text.trim().toLowerCase();
    final filteredBuses = _buses.where((b) {
      if (_busFilterStatus == 1 && !b.isActive) return false;
      if (_busFilterStatus == 2 && b.isActive) return false;
      if (busQuery.isEmpty) return true;
      return b.number.toLowerCase().contains(busQuery) ||
          b.route.toLowerCase().contains(busQuery) ||
          (b.deviceId?.toLowerCase().contains(busQuery) ?? false);
    }).toList();

    // Filter requests
    final filteredRequests = _requests.where((r) {
      if (_reqFilterStatus == 1 && !r.isPending) return false;
      if (_reqFilterStatus == 2 && r.status != 'approved') return false;
      if (_reqFilterStatus == 3 && r.status != 'rejected') return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── Executive Dark Navy Console Header ──
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 10,
              16,
              16,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Live Sync Refresh
                    GestureDetector(
                      onTap: () {
                        _loadBuses();
                        _loadRequests();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sync_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Live Sync',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Executive Stat Bar (Compact & Sleek) ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CompactStat(
                        icon: Icons.directions_bus_rounded,
                        count: '${_buses.length}',
                        label: 'Buses',
                        color: Colors.white,
                      ),
                      const _StatDivider(),
                      _CompactStat(
                        icon: Icons.bolt_rounded,
                        count: '$activeBusesCount',
                        label: 'Live',
                        color: const Color(0xFF10B981),
                      ),
                      const _StatDivider(),
                      _CompactStat(
                        icon: Icons.pending_actions_rounded,
                        count: '$pendingCount',
                        label: 'Requests',
                        color: pendingCount > 0
                            ? const Color(0xFFF59E0B)
                            : Colors.white70,
                      ),
                      const _StatDivider(),
                      _CompactStat(
                        icon: Icons.alt_route_rounded,
                        count: '$totalCorridors',
                        label: 'Routes',
                        color: const Color(0xFF93C5FD),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Segmented Navigation Tabs ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _AdminTabPill(
                        label: 'Buses (${_buses.length})',
                        icon: Icons.directions_bus_rounded,
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 6),
                      _AdminTabPill(
                        label: 'Requests ($pendingCount)',
                        icon: Icons.inbox_rounded,
                        badgeCount: pendingCount,
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                      const SizedBox(width: 6),
                      _AdminTabPill(
                        label: 'Schedules',
                        icon: Icons.schedule_rounded,
                        isSelected: _selectedTab == 2,
                        onTap: () => setState(() => _selectedTab = 2),
                      ),
                      const SizedBox(width: 6),
                      _AdminTabPill(
                        label: 'Broadcast',
                        icon: Icons.campaign_rounded,
                        isSelected: _selectedTab == 3,
                        onTap: () => setState(() => _selectedTab = 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Content Views ──
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                // TAB 0: BUSES
                _buildBusesTab(context, filteredBuses, isDark),

                // TAB 1: DRIVER REQUESTS
                _buildRequestsTab(context, filteredRequests, pendingCount, isDark),

                // TAB 2: SCHEDULES MATRIX
                _buildSchedulesTab(context, isDark),

                // TAB 3: BROADCAST NOTIFICATIONS
                _buildBroadcastTab(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 0: Buses Builder ───────────────────────────────────────────────────
  Widget _buildBusesTab(
      BuildContext context, List<BusModel> buses, bool isDark) {
    return Column(
      children: [
        // Toolbar: Search + Quick Add
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    controller: _busSearchCtrl,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Filter by bus number or route...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12.5,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      suffixIcon: _busSearchCtrl.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _busSearchCtrl.clear(),
                              child: const Icon(Icons.close_rounded, size: 16),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showBusDialog(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Bus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        // Status Filter Chips: All | Active | Idle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildSmallFilterChip('All (${_buses.length})', 0, _busFilterStatus, (v) {
                setState(() => _busFilterStatus = v);
              }),
              const SizedBox(width: 6),
              _buildSmallFilterChip(
                  'Active (${_buses.where((b) => b.isActive).length})', 1, _busFilterStatus, (v) {
                setState(() => _busFilterStatus = v);
              }),
              const SizedBox(width: 6),
              _buildSmallFilterChip(
                  'Idle (${_buses.where((b) => !b.isActive).length})', 2, _busFilterStatus, (v) {
                setState(() => _busFilterStatus = v);
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Bus Cards List
        Expanded(
          child: _busLoading
              ? const Center(child: CircularProgressIndicator())
              : buses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_bus_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _buses.isEmpty
                                ? 'No buses registered yet.\nTap "+ Add Bus" to register one.'
                                : 'No buses match your filter.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: buses.length,
                      itemBuilder: (context, index) {
                        final bus = buses[index];
                        return _EnterpriseBusCard(
                          bus: bus,
                          onEdit: () => _showBusDialog(existing: bus),
                          onDelete: () => _deleteBus(bus.id),
                          onToggleActive: () async {
                            final updated = bus.copyWith(isActive: !bus.isActive);
                            await ref.read(supabaseServiceProvider).upsertBus(updated);
                            _loadBuses();
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ── TAB 1: Requests Builder ───────────────────────────────────────────────
  Widget _buildRequestsTab(
      BuildContext context, List<DriverRequestModel> requests, int pendingCount, bool isDark) {
    return Column(
      children: [
        // Status filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              _buildSmallFilterChip('All (${_requests.length})', 0, _reqFilterStatus, (v) {
                setState(() => _reqFilterStatus = v);
              }),
              const SizedBox(width: 6),
              _buildSmallFilterChip('Pending ($pendingCount)', 1, _reqFilterStatus, (v) {
                setState(() => _reqFilterStatus = v);
              }),
              const SizedBox(width: 6),
              _buildSmallFilterChip('Approved', 2, _reqFilterStatus, (v) {
                setState(() => _reqFilterStatus = v);
              }),
              const SizedBox(width: 6),
              _buildSmallFilterChip('Rejected', 3, _reqFilterStatus, (v) {
                setState(() => _reqFilterStatus = v);
              }),
            ],
          ),
        ),

        Expanded(
          child: _reqLoading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            _requests.isEmpty
                                ? 'No driver requests recorded.'
                                : 'No requests in this category.',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return _EnterpriseRequestCard(
                          req: req,
                          onReview: req.isPending ? () => _showReviewDialog(req) : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ── TAB 2: Schedules Builder ──────────────────────────────────────────────
  Widget _buildSchedulesTab(BuildContext context, bool isDark) {
    final schedulesAsync = ref.watch(busSchedulesProvider);
    return schedulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading schedules: $e',
            style: const TextStyle(color: Color(0xFF64748B))),
      ),
      data: (schedules) {
        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                const Text(
                  'No bus schedules configured.\nAdd buses first to manage departure slots.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          physics: const BouncingScrollPhysics(),
          itemCount: schedules.length,
          itemBuilder: (ctx, i) {
            final bs = schedules[i];
            return _EnterpriseScheduleCard(
              busWithSchedule: bs,
              onEdit: () => _showScheduleEditor(ctx, ref, bs),
            );
          },
        );
      },
    );
  }

  // ── TAB 3: Broadcast Notifications Builder ────────────────────────────────
  Widget _buildBroadcastTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1F44).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF0A1F44),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Rider Broadcast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    Text(
                      'Send real-time alerts to all students & staff',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Text input
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _notificationCtrl,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Enter announcement text (e.g. "Route B-02 delayed by 15 mins due to Mirpur traffic")...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Modes selection
            const Text(
              'BROADCAST ACTION MODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModeRadioChip('Replace Current Notice', _NotificationSendMode.replaceOld),
                _buildModeRadioChip('Append as Extra Alert', _NotificationSendMode.keepOldAddNew),
                _buildModeRadioChip('Clear All Alerts', _NotificationSendMode.clearAll),
              ],
            ),
            const SizedBox(height: 22),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _sendingNotification ? null : _sendTransportNotification,
                icon: _sendingNotification
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _sendingNotification
                      ? 'Broadcasting...'
                      : (_notificationSendMode == _NotificationSendMode.clearAll
                          ? 'Clear All Notices'
                          : 'Send Broadcast Announcement'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _notificationSendMode == _NotificationSendMode.clearAll
                      ? AppColors.error
                      : const Color(0xFF0A1F44),
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
      ),
    );
  }

  Widget _buildModeRadioChip(String label, _NotificationSendMode mode) {
    final isSelected = _notificationSendMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _notificationSendMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0A1F44)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A1F44) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF334155),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallFilterChip(
      String label, int value, int current, ValueChanged<int> onSelect) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A1F44) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A1F44) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

enum _NotificationSendMode { replaceOld, keepOldAddNew, clearAll }

// ── Compact Executive Stat Chip ──────────────────────────────────────────────
class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const _CompactStat({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 12,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

// ── Tab Navigation Pill ──────────────────────────────────────────────────────
class _AdminTabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminTabPill({
    required this.label,
    required this.icon,
    this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF0A1F44) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0A1F44) : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 5),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Enterprise Fleet Bus Card ────────────────────────────────────────────────
class _EnterpriseBusCard extends StatelessWidget {
  final BusModel bus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _EnterpriseBusCard({
    required this.bus,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = bus.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: [ B-XX ] + Status Pill + Route Activation Switch
          Row(
            children: [
              // Bus Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1F44),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_bus_filled_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      bus.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Live / Idle Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? 'ON ROUTE' : 'IDLE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? const Color(0xFF065F46)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Switch
              Switch(
                value: isActive,
                onChanged: (_) => onToggleActive(),
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFFD1FAE5),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Route Details
          Text(
            bus.route,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),

          // Intermediate Stops preview
          Text(
            bus.stops.isNotEmpty ? bus.stops.join(' → ') : 'No stops configured',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Footer Tags + Action Buttons
          Row(
            children: [
              // Device token tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_android_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      bus.deviceId != null ? 'GPS: ${bus.deviceId}' : 'No device paired',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Edit Button
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1F44).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 13, color: Color(0xFF0A1F44)),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Color(0xFF0A1F44),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 13, color: AppColors.error),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Enterprise Driver Request Card ──────────────────────────────────────────
class _EnterpriseRequestCard extends StatelessWidget {
  final DriverRequestModel req;
  final VoidCallback? onReview;

  const _EnterpriseRequestCard({
    required this.req,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusLabel;
    switch (req.status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'APPROVED';
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'REJECTED';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'PENDING REVIEW';
    }

    final isBusAssignment = req.type == 'bus_assignment';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: req.isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1F44).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBusAssignment
                      ? Icons.assignment_ind_rounded
                      : Icons.share_location_rounded,
                  color: const Color(0xFF0A1F44),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.driverName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isBusAssignment
                          ? 'Bus Assignment Request'
                          : 'Live Location Sharing Request',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (req.requestedBus != null)
                Text(
                  'Requested Bus: ${req.requestedBus}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              Text(
                'Date: ${req.validDate}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),

          if (req.assignedBus != null && req.assignedBus != req.requestedBus)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Assigned Bus: ${req.assignedBus}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A1F44),
                ),
              ),
            ),

          if (onReview != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review_rounded, size: 15),
                label: const Text('Review & Approve Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Enterprise Schedule Card ────────────────────────────────────────────────
class _EnterpriseScheduleCard extends StatelessWidget {
  final BusWithSchedule busWithSchedule;
  final VoidCallback onEdit;

  const _EnterpriseScheduleCard({
    required this.busWithSchedule,
    required this.onEdit,
  });

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
    final bus = busWithSchedule.bus;
    final times = busWithSchedule.departureTimes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1F44),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bus.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bus.route,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                color: const Color(0xFF0A1F44),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'SCHEDULED DEPARTURES',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: times.isEmpty
                ? [
                    const Text(
                      'No departure slots scheduled.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ]
                : times.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(t),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A1F44),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Req Info Row Helper ───────────────────────────────────────────────────────
class _ReqInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReqInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Schedule Editor Bottom Sheet ─────────────────────────────────────────────
class _BusScheduleEditorSheet extends ConsumerStatefulWidget {
  final BusWithSchedule busWithSchedule;
  final VoidCallback onSaved;

  const _BusScheduleEditorSheet({
    required this.busWithSchedule,
    required this.onSaved,
  });

  @override
  ConsumerState<_BusScheduleEditorSheet> createState() =>
      _BusScheduleEditorSheetState();
}

class _BusScheduleEditorSheetState extends ConsumerState<_BusScheduleEditorSheet> {
  late List<ScheduleModel> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final list = await ref
          .read(supabaseServiceProvider)
          .fetchSchedules(widget.busWithSchedule.bus.id);
      if (mounted) {
        setState(() {
          _schedules = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null && mounted) {
      setState(() => _loading = true);
      final timeStr =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

      final bus = widget.busWithSchedule.bus;
      final parts = bus.route.split('→').map((e) => e.trim()).toList();
      final origin = parts.isNotEmpty ? parts[0] : 'Unknown';
      final dest = parts.length > 1 ? parts[1] : 'Unknown';

      try {
        await ref
            .read(supabaseServiceProvider)
            .addScheduleTime(bus.id, timeStr, origin, dest);
        await _loadSchedules();
        widget.onSaved();
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppErrorHandler.getFriendlyMessage(e)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTime(String scheduleId) async {
    setState(() => _loading = true);
    try {
      await ref.read(supabaseServiceProvider).deleteScheduleTime(scheduleId);
      await _loadSchedules();
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bus = widget.busWithSchedule.bus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A1F44),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${bus.number} • ${bus.route}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Departure Waves',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              ElevatedButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Slot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _schedules.isEmpty
                    ? const Center(
                        child: Text(
                          'No departure times set.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _schedules.length,
                        itemBuilder: (_, i) {
                          final s = _schedules[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF0A1F44),
                              ),
                              title: Text(
                                _EnterpriseScheduleCard._formatTime(s.departureTime),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${s.origin} → ${s.destination}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteTime(s.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Bus Editor Bottom Sheet ───────────────────────────────────────────────────
class _BusEditorSheet extends ConsumerStatefulWidget {
  final BusModel? existing;
  final List<BusModel> allBuses;
  final VoidCallback onSaved;

  const _BusEditorSheet({
    this.existing,
    required this.allBuses,
    required this.onSaved,
  });

  @override
  ConsumerState<_BusEditorSheet> createState() => _BusEditorSheetState();
}

class _BusEditorSheetState extends ConsumerState<_BusEditorSheet> {
  late TextEditingController _numCtrl;
  late TextEditingController _originCtrl;
  late TextEditingController _deviceCtrl;
  bool _isActive = false;

  List<TextEditingController> _stopCtrls = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _numCtrl = TextEditingController(text: widget.existing?.number ?? '');

    final routeStr = widget.existing?.route ?? '';
    final originStr =
        routeStr.contains(' → ') ? routeStr.split(' → ').first : routeStr;
    _originCtrl = TextEditingController(text: originStr);

    _deviceCtrl = TextEditingController(text: widget.existing?.deviceId ?? '');
    _isActive = widget.existing?.isActive ?? false;

    if (widget.existing != null) {
      final stops = List<String>.from(widget.existing!.stops);
      if (stops.isNotEmpty && stops.last.toLowerCase().contains('diu campus')) {
        stops.removeLast();
      }
      _stopCtrls = stops.map((s) => TextEditingController(text: s)).toList();
    }
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _originCtrl.dispose();
    _deviceCtrl.dispose();
    for (var c in _stopCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStop(int index) {
    setState(() {
      _stopCtrls.insert(index, TextEditingController(text: ''));
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopCtrls[index].dispose();
      _stopCtrls.removeAt(index);
    });
  }

  Future<void> _save() async {
    final numT = _numCtrl.text.trim();
    final oriT = _originCtrl.text.trim();
    if (numT.isEmpty || oriT.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus Number and Origin are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    List<String> finalStops = _stopCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (finalStops.isEmpty) {
      final match = widget.allBuses.where((b) =>
          b.route.split(' → ').first.toLowerCase() == oriT.toLowerCase() &&
          b.id != widget.existing?.id).firstOrNull;

      if (match != null && match.stops.isNotEmpty) {
        finalStops = List<String>.from(match.stops);
        if (finalStops.isEmpty ||
            !finalStops.last.toLowerCase().contains('diu campus')) {
          finalStops.add('DIU Campus');
        }
      } else {
        finalStops = [oriT, 'DIU Campus'];
      }
    } else {
      finalStops.add('DIU Campus');
    }

    final bus = BusModel(
      id: widget.existing?.id ?? '',
      number: numT,
      route: '$oriT → DIU Campus',
      stops: finalStops,
      isActive: _isActive,
      deviceId: _deviceCtrl.text.trim().isEmpty ? null : _deviceCtrl.text.trim(),
    );

    try {
      await ref
          .read(supabaseServiceProvider)
          .upsertBus(bus, isNew: widget.existing == null);
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getFriendlyMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existing == null ? 'Add New Bus' : 'Edit Bus Information',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A1F44),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _numCtrl,
                          decoration: const InputDecoration(labelText: 'Bus Number (e.g. B-01)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _originCtrl,
                          decoration: const InputDecoration(labelText: 'Origin Terminal (e.g. Mirpur)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deviceCtrl,
                    decoration: const InputDecoration(labelText: 'Assigned Device / Phone ID (optional)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Dispatch to Route Immediately',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const Spacer(),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeThumbColor: const Color(0xFF10B981),
                        activeTrackColor: const Color(0xFFD1FAE5),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Route Intermediate Stops',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      TextButton.icon(
                        onPressed: () => _addStop(_stopCtrls.length),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Stop'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Drag handles to re-order sequence. Final terminal is automatically DIU Campus.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),

                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stopCtrls.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = _stopCtrls.removeAt(oldIndex);
                        _stopCtrls.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        key: ValueKey(_stopCtrls[index]),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_indicator_rounded, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1F44).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF0A1F44),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _stopCtrls[index],
                                decoration: const InputDecoration(
                                  hintText: 'Stop Name',
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded,
                                  color: AppColors.error, size: 20),
                              onPressed: () => _removeStop(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  if (_stopCtrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded,
                              color: Color(0xFF0A1F44)),
                          onPressed: () => _addStop(_stopCtrls.length),
                        ),
                      ),
                    ),

                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F44).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0A1F44).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.school_rounded, color: Color(0xFF0A1F44), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'DIU Campus (Final Destination Terminal)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: Color(0xFF0A1F44),
                            ),
                          ),
                        ),
                        Icon(Icons.lock_rounded, size: 14, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.existing == null ? 'Add Bus' : 'Save Changes',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
