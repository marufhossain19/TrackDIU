// ====================================================
// services/supabase_service.dart — Supabase backend
// ====================================================
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/bus_model.dart';
import '../models/notification_model.dart';

class SupabaseService {
  // Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? get _clientOrNull {
    try { return Supabase.instance.client; } catch (_) { return null; }
  }

  SupabaseClient get _client => Supabase.instance.client;

  // ── Auth ─────────────────────────────────────────────

  /// Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up new user
  Future<AuthResponse> signUp(String email, String password, UserRole role) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': role.name},
    );
    return response;
  }

  /// Sign out
  Future<void> signOut() async => await _client.auth.signOut();

  /// Current user
  User? get currentUser => _client.auth.currentUser;

  /// User role from metadata
  UserRole get currentRole {
    final meta = _client.auth.currentUser?.userMetadata;
    final roleStr = meta?['role'] as String? ?? 'student';
    return UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.student,
    );
  }

  // ── Buses ────────────────────────────────────────────

  /// Fetch all buses
  Future<List<BusModel>> fetchBuses() async {
    try {
      final data = await _client
          .from('buses')
          .select()
          .order('number', ascending: true);
      return (data as List).map((e) => BusModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch active buses only
  Future<List<BusModel>> fetchActiveBuses() async {
    try {
      final data = await _client
          .from('buses')
          .select()
          .eq('is_active', true);
      return (data as List).map((e) => BusModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search buses by route/destination
  Future<List<BusModel>> searchBuses(String query) async {
    try {
      final data = await _client
          .from('buses')
          .select()
          .ilike('route', '%$query%');
      return (data as List).map((e) => BusModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Insert or update a bus (admin)
  Future<void> upsertBus(BusModel bus, {bool isNew = false}) async {
    if (isNew) {
      // Let Supabase auto-generate the UUID — don't send the id field
      final map = bus.toMap()..remove('id');
      await _client.from('buses').insert(map);
    } else {
      await _client.from('buses').upsert(bus.toMap());
    }
  }

  /// Delete a bus (admin)
  Future<void> deleteBus(String busId) async {
    await _client.from('buses').delete().eq('id', busId);
  }

  // ── Bus Locations ────────────────────────────────────

  /// Fetch latest location for a specific bus
  Future<BusLocationModel?> fetchBusLocation(String busId) async {
    try {
      final data = await _client
          .from('bus_locations')
          .select()
          .eq('bus_id', busId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return BusLocationModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// Fetch all active bus locations (for nearby screen)
  Future<List<BusLocationModel>> fetchAllBusLocations() async {
    try {
      final data = await _client
          .from('bus_locations')
          .select()
          .order('updated_at', ascending: false);
      return (data as List).map((e) => BusLocationModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update/insert bus location (driver mode)
  Future<void> upsertBusLocation({
    required String busId,
    required double lat,
    required double lng,
    double? speed,
    String? currentStop,
  }) async {
    await _client.from('bus_locations').upsert({
      'bus_id'      : busId,
      'latitude'    : lat,
      'longitude'   : lng,
      'speed'       : speed,
      'current_stop': currentStop,
      'updated_at'  : DateTime.now().toIso8601String(),
    });
  }

  // ── Realtime Subscriptions ───────────────────────────

  /// Listen to location updates for a specific bus
  RealtimeChannel subscribeToBusLocation(
    String busId,
    void Function(BusLocationModel) onUpdate,
  ) {
    return _client
        .channel('bus_location_$busId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bus_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'bus_id',
            value: busId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) {
              onUpdate(BusLocationModel.fromMap(data));
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribe from a realtime channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // ── Schedules ────────────────────────────────────────

  /// Fetch schedules for a bus
  Future<List<ScheduleModel>> fetchSchedules(String busId) async {
    try {
      final data = await _client
          .from('schedules')
          .select()
          .eq('bus_id', busId)
          .order('departure_time', ascending: true);
      return (data as List).map((e) => ScheduleModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch all buses with their departure times
  Future<List<BusWithSchedule>> fetchAllBusesWithSchedules() async {
    try {
      final data = await _client
          .from('buses')
          .select('*, schedules(departure_time)')
          .order('number', ascending: true);

      return (data as List).map((e) {
        final bus = BusModel.fromMap(e);
        final scheds = e['schedules'] as List?;
        final times = scheds
                ?.map((s) => s['departure_time'] as String)
                .toList() ??
            [];
        // Sort times simply by string (e.g. 07:00, 12:00)
        times.sort();
        return BusWithSchedule(bus: bus, departureTimes: times);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a new schedule time for a bus
  Future<void> addScheduleTime(String busId, String time, String origin, String destination) async {
    await _client.from('schedules').insert({
      'bus_id': busId,
      'departure_time': time,
      'origin': origin,
      'destination': destination,
    });
  }

  /// Delete a schedule time given its ID
  Future<void> deleteScheduleTime(String scheduleId) async {
    await _client.from('schedules').delete().eq('id', scheduleId);
  }

  // ── Admin: Map Device to Bus ─────────────────────────

  Future<void> mapDeviceToBus(String busId, String deviceId) async {
    await _client.from('buses').update({'device_id': deviceId}).eq('id', busId);
  }

  // ── Driver Profile ───────────────────────────────────

  Future<DriverProfileModel?> fetchDriverProfile(String userId) async {
    try {
      final data = await _client
          .from('driver_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return DriverProfileModel.fromMap(data);
    } catch (_) { return null; }
  }

  Future<void> upsertDriverProfile(DriverProfileModel profile) async {
    await _client.from('driver_profiles').upsert(
      {...profile.toMap(), 'updated_at': DateTime.now().toIso8601String()},
      onConflict: 'user_id',
    );
  }

  // ── Driver Requests ──────────────────────────────────

  Future<List<DriverRequestModel>> fetchMyRequests(String userId) async {
    try {
      final data = await _client
          .from('driver_requests')
          .select()
          .eq('driver_user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => DriverRequestModel.fromMap(e)).toList();
    } catch (_) { return []; }
  }

  /// Today's approved location sharing request for driver
  Future<DriverRequestModel?> fetchTodayLocationApproval(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final data = await _client
          .from('driver_requests')
          .select()
          .eq('driver_user_id', userId)
          .eq('type', 'location_sharing')
          .eq('status', 'approved')
          .eq('valid_date', today)
          .maybeSingle();
      if (data == null) return null;
      return DriverRequestModel.fromMap(data);
    } catch (_) { return null; }
  }

  /// Pending location sharing request for today
  Future<DriverRequestModel?> fetchPendingLocationRequest(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final data = await _client
          .from('driver_requests')
          .select()
          .eq('driver_user_id', userId)
          .eq('type', 'location_sharing')
          .eq('status', 'pending')
          .eq('valid_date', today)
          .maybeSingle();
      if (data == null) return null;
      return DriverRequestModel.fromMap(data);
    } catch (_) { return null; }
  }

  Future<void> submitRequest({
    required String driverUserId,
    required String driverName,
    required String type,
    String? requestedBus,
  }) async {
    await _client.from('driver_requests').insert({
      'driver_user_id': driverUserId,
      'driver_name'   : driverName,
      'type'          : type,
      'requested_bus' : requestedBus,
      'status'        : 'pending',
      'valid_date'    : DateTime.now().toIso8601String().substring(0, 10),
    });
  }

  // ── Admin: Fetch All Requests ─────────────────────────

  Future<List<DriverRequestModel>> fetchAllRequests({String? type}) async {
    try {
      var query = _client
          .from('driver_requests')
          .select()
          .order('created_at', ascending: false);
      final data = await query;
      final list = (data as List).map((e) => DriverRequestModel.fromMap(e)).toList();
      if (type != null) return list.where((r) => r.type == type).toList();
      return list;
    } catch (_) { return []; }
  }

  Future<void> reviewRequest({
    required String requestId,
    required String status,         // 'approved' | 'rejected'
    String? assignedBus,
    String? assignedBusId,
    String? driverUserId,           // needed to update driver profile
  }) async {
    await _client.from('driver_requests').update({
      'status'          : status,
      'assigned_bus'    : assignedBus,
      'assigned_bus_id' : assignedBusId,
      'reviewed_at'     : DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    // If bus assignment approved → update driver profile
    if (status == 'approved' && assignedBus != null && driverUserId != null) {
      await _client.from('driver_profiles').update({
        'bus_number': assignedBus,
        'bus_id'    : assignedBusId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', driverUserId);
    }
  }

  // ── Realtime: subscribe to driver_requests (for driver) ──

  RealtimeChannel subscribeToMyRequests(
    String userId,
    void Function(DriverRequestModel) onUpdate,
  ) {
    return _client
        .channel('my_requests_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'driver_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_user_id',
            value: userId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) onUpdate(DriverRequestModel.fromMap(data));
          },
        )
        .subscribe();
  }

  // ── Realtime: subscribe to all driver_requests (for admin) ─

  RealtimeChannel subscribeToAllRequests(
    void Function(DriverRequestModel) onInsert,
  ) {
    return _client
        .channel('admin_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'driver_requests',
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) onInsert(DriverRequestModel.fromMap(data));
          },
        )
        .subscribe();
  }

  // ── Transport Notifications ──────────────────────────

  Future<List<TransportNotification>> fetchNotifications() async {
    try {
      final data = await _client
          .from('transport_notifications')
          .select()
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => TransportNotification.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addTransportNotification(String message) async {
    await _client.from('transport_notifications').insert({
      'message': message.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> replaceTransportNotifications(String message) async {
    await _client.from('transport_notifications').delete().neq('message', '');
    await addTransportNotification(message);
  }

  Future<void> clearTransportNotifications() async {
    await _client.from('transport_notifications').delete().neq('message', '');
  }

  RealtimeChannel subscribeToNotifications(void Function() onChange) {
    return _client
        .channel('transport_notifications_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transport_notifications',
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
