// ====================================================
// features/admin/admin_panel_screen.dart — Bus CRUD + Requests
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  late TabController _tabCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

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
    _tabCtrl = TabController(length: 3, vsync: this);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
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
    _tabCtrl.dispose();
    _fadeCtrl.dispose();
    _notificationCtrl.dispose();
    if (_reqChannel != null) {
      ref.read(supabaseServiceProvider).unsubscribe(_reqChannel!);
    }
    super.dispose();
  }

  Future<void> _sendTransportNotification() async {
    if (_sendingNotification) return;
    final message = _notificationCtrl.text.trim();
    if (_notificationSendMode != _NotificationSendMode.clearAll &&
        message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a notification message.')),
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
                ? 'All notifications cleared.'
                : 'Notification sent to all users.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification action failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingNotification = false);
    }
  }

  Future<void> _loadBuses() async {
    setState(() => _busLoading = true);
    final buses = await ref.read(supabaseServiceProvider).fetchBuses();
    if (mounted) {
      setState(() { _buses = buses; _busLoading = false; });
      _fadeCtrl.forward(from: 0);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _reqLoading = true);
    final reqs = await ref.read(supabaseServiceProvider).fetchAllRequests();
    if (mounted) setState(() { _requests = reqs; _reqLoading = false; });
  }

  // ── Bus Dialog ────────────────────────────────────────────
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Bus?'),
        content: const Text(
            'This will permanently remove the bus from the system.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(supabaseServiceProvider).deleteBus(busId);
      _loadBuses();
    }
  }

  // ── Request Review Dialog ─────────────────────────────────
  void _showReviewDialog(DriverRequestModel req) {
    final assignCtrl = TextEditingController(
        text: req.requestedBus ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                req.type == 'bus_assignment'
                    ? Icons.directions_bus_rounded
                    : Icons.share_location_rounded,
                color: AppColors.primary, size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                req.type == 'bus_assignment'
                    ? 'Bus Assignment Request'
                    : 'Location Sharing Request',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReqInfoRow(
                label: 'Driver',
                value: req.driverName),
            if (req.requestedBus != null)
              _ReqInfoRow(
                  label: 'Requested Bus',
                  value: req.requestedBus!),
            _ReqInfoRow(
                label: 'Date',
                value: req.validDate),
            if (req.type == 'bus_assignment') ...[
              const SizedBox(height: 12),
              const Text('Assign Bus Number:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: assignCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. B-01',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(supabaseServiceProvider).reviewRequest(
                requestId   : req.id,
                status      : 'rejected',
                driverUserId: req.driverUserId,
              );
              if (mounted) {
                Navigator.pop(context);
                _loadRequests();
              }
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              final assignedBus = req.type == 'bus_assignment'
                  ? assignCtrl.text.trim().toUpperCase()
                  : req.requestedBus;

              // Find bus ID if bus_assignment
              String? busId;
              if (req.type == 'bus_assignment' && assignedBus != null) {
                final buses = await ref
                    .read(supabaseServiceProvider)
                    .fetchBuses();
                busId = buses
                    .where((b) => b.number == assignedBus)
                    .firstOrNull
                    ?.id;
              }

              await ref.read(supabaseServiceProvider).reviewRequest(
                requestId    : req.id,
                status       : 'approved',
                assignedBus  : assignedBus,
                assignedBusId: busId,
                driverUserId : req.driverUserId,
              );
              if (mounted) {
                Navigator.pop(context);
                _loadRequests();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests.where((r) => r.isPending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () { _loadBuses(); _loadRequests(); },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400, fontSize: 12),
          tabs: [
            const Tab(
              icon: Icon(Icons.directions_bus_rounded, size: 22),
              text: 'Buses',
            ),
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.inbox_rounded, size: 22),
                  if (pendingCount > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        width: 9, height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Requests${pendingCount > 0 ? ' ($pendingCount)' : ''}',
            ),
            const Tab(
              icon: Icon(Icons.schedule_rounded, size: 22),
              text: 'Schedules',
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => _tabCtrl.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showBusDialog(),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Add Bus',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Buses Tab ─────────────────────────────
          _busLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                  opacity: _fade,
                  child: _buses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text(
                                  'No buses found.\nTap + to add one.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _buses.length,
                          itemBuilder: (_, i) {
                            final bus = _buses[i];
                            return _AdminBusCard(
                              bus: bus,
                              onEdit: () =>
                                  _showBusDialog(existing: bus),
                              onDelete: () => _deleteBus(bus.id),
                              onToggleActive: () async {
                                final updated = bus.copyWith(
                                    isActive: !bus.isActive);
                                await ref
                                    .read(supabaseServiceProvider)
                                    .upsertBus(updated);
                                _loadBuses();
                              },
                              index: i,
                            );
                          },
                        ),
                ),

          // ── Requests Tab ──────────────────────────
          Column(
            children: [
              _AdminNotificationComposer(
                controller: _notificationCtrl,
                mode: _notificationSendMode,
                isSending: _sendingNotification,
                onModeChanged: (mode) =>
                    setState(() => _notificationSendMode = mode),
                onSend: _sendTransportNotification,
              ),
              Expanded(
                child: _reqLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text('No requests yet.',
                                    style: TextStyle(
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _requests.length,
                            itemBuilder: (_, i) => _RequestCard(
                              req: _requests[i],
                              index: i,
                              onReview: _requests[i].isPending
                                  ? () => _showReviewDialog(_requests[i])
                                  : null,
                            ),
                          ),
              ),
            ],
          ),
          // ── Schedules Tab ─────────────────────────
          Consumer(
            builder: (ctx, ref, _) {
              final schedulesAsync = ref.watch(busSchedulesProvider);
              return schedulesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(
                            color: AppColors.textMuted))),
                data: (busSchedules) {
                  if (busSchedules.isEmpty) {
                    return const Center(
                      child: Text('No buses yet. Add buses first.',
                          style:
                              TextStyle(color: AppColors.textMuted)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: busSchedules.length,
                    itemBuilder: (_, i) => _AdminScheduleCard(
                      busWithSchedule: busSchedules[i],
                      index: i,
                      onEdit: () => _showScheduleEditor(
                          ctx, ref, busSchedules[i]),
                    ),
                  );
                },
              );
            },
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
          // Invalidate provider so Search and Schedules tab both refresh
          ref.invalidate(busSchedulesProvider);
        },
      ),
    );
  }
}

enum _NotificationSendMode { replaceOld, keepOldAddNew, clearAll }

class _AdminNotificationComposer extends StatelessWidget {
  final TextEditingController controller;
  final _NotificationSendMode mode;
  final bool isSending;
  final ValueChanged<_NotificationSendMode> onModeChanged;
  final VoidCallback onSend;

  const _AdminNotificationComposer({
    required this.controller,
    required this.mode,
    required this.isSending,
    required this.onModeChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Send Notification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Write transport update for all users...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _NotificationModeChip(
                label: 'Replace old',
                selected: mode == _NotificationSendMode.replaceOld,
                onTap: () => onModeChanged(_NotificationSendMode.replaceOld),
              ),
              _NotificationModeChip(
                label: 'Keep old + add new',
                selected: mode == _NotificationSendMode.keepOldAddNew,
                onTap: () => onModeChanged(_NotificationSendMode.keepOldAddNew),
              ),
              _NotificationModeChip(
                label: 'Clear all',
                selected: mode == _NotificationSendMode.clearAll,
                onTap: () => onModeChanged(_NotificationSendMode.clearAll),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(isSending ? 'Sending...' : 'Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B215A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.36),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Request Card ──────────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final DriverRequestModel req;
  final int index;
  final VoidCallback? onReview;

  const _RequestCard({
    required this.req,
    required this.index,
    required this.onReview,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
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
      begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 60),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final req    = widget.req;
    final accentColor = isDark ? const Color(0xFF93C5FD) : AppColors.primary;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (req.status) {
      case 'approved':
        statusColor = AppColors.success; statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Approved'; break;
      case 'rejected':
        statusColor = AppColors.error;   statusIcon = Icons.cancel_rounded;
        statusLabel = 'Rejected'; break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon  = Icons.hourglass_top_rounded;
        statusLabel = 'Pending';
    }

    final typeIcon  = req.type == 'bus_assignment'
        ? Icons.directions_bus_rounded
        : Icons.share_location_rounded;
    final typeLabel = req.type == 'bus_assignment'
        ? 'Bus Assignment'
        : 'Location Sharing';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: req.isPending
                ? Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.5))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeIcon,
                        color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(typeLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(req.driverName,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon,
                            color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (req.requestedBus != null)
                _ReqInfoRow(
                    label: 'Requested Bus',
                    value: req.requestedBus!),
              if (req.assignedBus != null && req.assignedBus != req.requestedBus)
                _ReqInfoRow(
                    label: 'Assigned Bus',
                    value: req.assignedBus!),
              _ReqInfoRow(label: 'Date', value: req.validDate),

              if (req.type == 'location_sharing' && req.requestedBus != null)
                _ReqInfoRow(
                    label: 'Bus',
                    value: req.requestedBus!),

              if (widget.onReview != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onReview,
                    icon: const Icon(Icons.rate_review_rounded, size: 16),
                    label: const Text('Review Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Req Info Row ──────────────────────────────────────────────
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
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Admin Bus Card ────────────────────────────────────────────
class _AdminBusCard extends StatefulWidget {
  final BusModel bus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final int index;

  const _AdminBusCard({
    required this.bus,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.index,
  });

  @override
  State<_AdminBusCard> createState() => _AdminBusCardState();
}

class _AdminBusCardState extends State<_AdminBusCard>
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
      begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 60),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bus    = widget.bus;
    final actionColor = isDark ? Colors.white : AppColors.primary;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_bus_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bus.number,
                            style:
                                Theme.of(context).textTheme.titleLarge),
                        Text(bus.route,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Switch(
                    value: bus.isActive,
                    onChanged: (_) => widget.onToggleActive(),
                    activeColor: AppColors.success,
                  ),
                ],
              ),
              if (bus.deviceId != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_android_rounded,
                          color: AppColors.info, size: 14),
                      const SizedBox(width: 6),
                      Text('Device: ${bus.deviceId}',
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: actionColor,
                        side: BorderSide(color: actionColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(
                          Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin Schedule Card ───────────────────────────────────────
class _AdminScheduleCard extends StatelessWidget {
  final BusWithSchedule busWithSchedule;
  final int index;
  final VoidCallback onEdit;

  const _AdminScheduleCard({
    required this.busWithSchedule,
    required this.index,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bus = busWithSchedule.bus;
    final times = busWithSchedule.departureTimes;
    final accentColor = isDark ? const Color(0xFF93C5FD) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.number,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(bus.route,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_calendar_rounded, color: accentColor),
                onPressed: onEdit,
              )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times.isEmpty
                ? [
                    const Text('No schedules listed.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12))
                  ]
                : times.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Bus Schedule Editor Bottom Sheet ──────────────────────────────────
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
    final list = await ref
        .read(supabaseServiceProvider)
        .fetchSchedules(widget.busWithSchedule.bus.id);
    if (mounted) {
      setState(() {
        _schedules = list;
        _loading = false;
      });
    }
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null && mounted) {
      setState(() => _loading = true);
      // store as HH:MM 24h
      final timeStr =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

      final bus = widget.busWithSchedule.bus;
      final parts = bus.route.split('→').map((e) => e.trim()).toList();
      final origin = parts.isNotEmpty ? parts[0] : 'Unknown';
      final dest = parts.length > 1 ? parts[1] : 'Unknown';

      await ref.read(supabaseServiceProvider).addScheduleTime(
          bus.id, timeStr, origin, dest);
      await _loadSchedules();
      widget.onSaved();
    }
  }

  Future<void> _deleteTime(String scheduleId) async {
    setState(() => _loading = true);
    await ref.read(supabaseServiceProvider).deleteScheduleTime(scheduleId);
    await _loadSchedules();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final bus = widget.busWithSchedule.bus;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
              Text('Edit Schedule',
                  style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text('${bus.number} • ${bus.route}',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Departure Times',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              TextButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Time'),
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _schedules.isEmpty
                    ? Center(
                        child: Text('No departure times.',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.textMuted)))
                    : ListView.builder(
                        itemCount: _schedules.length,
                        itemBuilder: (_, i) {
                          final s = _schedules[i];
                          // Sort times client side visually
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.access_time_rounded,
                                  color: AppColors.primary),
                              title: Text(s.departureTime,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text('${s.origin} → ${s.destination}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error),
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
    
    // Parse origin from "Origin → DIU Campus"
    final routeStr = widget.existing?.route ?? '';
    final originStr = routeStr.contains(' → ') ? routeStr.split(' → ').first : routeStr;
    _originCtrl = TextEditingController(text: originStr);
    
    _deviceCtrl = TextEditingController(text: widget.existing?.deviceId ?? '');
    _isActive = widget.existing?.isActive ?? false;

    if (widget.existing != null) {
      final stops = List<String>.from(widget.existing!.stops);
      if (stops.isNotEmpty && stops.last.toLowerCase().contains('diu campus')) {
        stops.removeLast(); // We append it dynamically on save
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

  void _onOriginChanged(String text) {
    // We no longer aggressively auto-fill the UI. 
    // Route inheritance happens exactly on Save if no custom stops are provided.
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

    // Build stops array
    List<String> finalStops = _stopCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    if (finalStops.isEmpty) {
      // 1. ROUTE INHERITANCE: If no custom stops are added, inherit from existing destination
      final match = widget.allBuses.where(
        (b) => b.route.split(' → ').first.toLowerCase() == oriT.toLowerCase() && b.id != widget.existing?.id
      ).firstOrNull;

      if (match != null && match.stops.isNotEmpty) {
        finalStops = List<String>.from(match.stops);
        if (finalStops.isEmpty || !finalStops.last.toLowerCase().contains('diu campus')) {
          finalStops.add('DIU Campus');
        }
      } else {
        // No custom stops & no existing match: Basic route
        finalStops = [oriT, 'DIU Campus'];
      }
    } else {
      // 2. ROUTE OVERRIDE: Admin intentionally added custom stops
      // Enforce DIU Campus as last stop
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
      await ref.read(supabaseServiceProvider).upsertBus(bus, isNew: widget.existing == null);
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving bus: $e'), backgroundColor: AppColors.error),
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
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 20),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.existing == null ? 'Add Bus' : 'Edit Bus',
                  style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
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
                          decoration: const InputDecoration(labelText: 'Bus Number'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _originCtrl,
                          decoration: const InputDecoration(labelText: 'Origin (e.g. Mirpur)'),
                          onChanged: _onOriginChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deviceCtrl,
                    decoration: const InputDecoration(labelText: 'Device ID (optional)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Active (On Route)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: AppColors.success,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Route Stops', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      TextButton.icon(
                        onPressed: () => _addStop(_stopCtrls.length),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Stop'),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Leave stops empty to inherit from existing route, or add stops to override.', 
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  
                  // Reorderable list of intermediate stops
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stopCtrls.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _stopCtrls.removeAt(oldIndex);
                        _stopCtrls.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        key: ValueKey(_stopCtrls[index]),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_handle_rounded, color: AppColors.textMuted),
                            const SizedBox(width: 12),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${index + 1}', 
                                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _stopCtrls[index],
                                decoration: InputDecoration(
                                  hintText: 'Stop Name',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                              onPressed: () => _removeStop(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Add an insert button at the end just before DIU Campus
                  if (_stopCtrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                          onPressed: () => _addStop(_stopCtrls.length),
                        ),
                      ),
                    ),

                  // Fixed DIU Campus Stop
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, color: AppColors.accentDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'DIU Campus (Final Destination)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.accentDark),
                          ),
                        ),
                        const Icon(Icons.lock_rounded, size: 16, color: AppColors.accentDark),
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
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.existing == null ? 'Create Bus' : 'Save Changes', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

