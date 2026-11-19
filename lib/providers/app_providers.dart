// ====================================================
// providers/app_providers.dart — Riverpod state providers
// ====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../models/bus_model.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';

// ── Theme Mode ───────────────────────────────────────
final themeModeProvider = StateProvider<bool>((ref) => false); // false = light

// ── User Role ────────────────────────────────────────
final userRoleProvider = StateProvider<UserRole>(
  (ref) => UserRole.student,
);

// ── Auth State ───────────────────────────────────────
final isLoggedInProvider = StateProvider<bool>((ref) => false);

// ── Services (singleton) ─────────────────────────────
final supabaseServiceProvider = Provider<SupabaseService>(
  (ref) => SupabaseService(),
);
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

// ── Buses List ───────────────────────────────────────
final busListProvider = FutureProvider<List<BusModel>>((ref) async {
  return await ref.read(supabaseServiceProvider).fetchBuses();
});

// ── Bus Schedules ────────────────────────────────────
final busSchedulesProvider = FutureProvider<List<BusWithSchedule>>((ref) async {
  return await ref.read(supabaseServiceProvider).fetchAllBusesWithSchedules();
});

// ── Search Query ─────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Search Results ───────────────────────────────────
final searchResultsProvider = FutureProvider<List<BusModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return await ref.read(supabaseServiceProvider).searchBuses(query);
});

// ── Selected Bus ─────────────────────────────────────
final selectedBusProvider = StateProvider<BusModel?>((ref) => null);

// ── Bus Location ─────────────────────────────────────
final busLocationProvider = StateProvider<BusLocationModel?>((ref) => null);

// ── User Location ────────────────────────────────────
final userLocationProvider = StateProvider<Position?>((ref) => null);

// ── Driver Tracking Active ───────────────────────────
final isTrackingProvider = StateProvider<bool>((ref) => false);

// ── Driver Bus ID ────────────────────────────────────
final driverBusIdProvider = StateProvider<String?>((ref) => null);

// ── All Bus Locations (for nearby) ───────────────────
final allBusLocationsProvider = FutureProvider<List<BusLocationModel>>((ref) async {
  return await ref.read(supabaseServiceProvider).fetchAllBusLocations();
});

// ── Chatbot Messages ─────────────────────────────────
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => [
  ChatMessage(
    text: '👋 Welcome to TrackDIU Assistant!\n\nI can help you with bus routes and schedules. Try asking:\n• "bus to mirpur"\n• "schedule"\n• "route"',
    isUser: false,
    timestamp: DateTime.now(),
  ),
]);

// ── Active Buses (Admin) ──────────────────────────────
final activeBusesProvider = FutureProvider<List<BusModel>>((ref) async {
  return await ref.read(supabaseServiceProvider).fetchActiveBuses();
});

// ── Driver Profile ────────────────────────────────────
final driverProfileProvider = StateProvider<DriverProfileModel?>((ref) => null);

// ── Location Sharing Approval State ──────────────────
// 'none' | 'pending' | 'approved'
final locationSharingStateProvider = StateProvider<String>((ref) => 'none');

// ── Transport Notifications ───────────────────────────
final transportNotificationsProvider =
    FutureProvider<List<TransportNotification>>((ref) async {
  return await ref.read(supabaseServiceProvider).fetchNotifications();
});
