// ====================================================
// core/constants.dart — App-wide constants
// ====================================================
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // ── Supabase ────────────────────────────────────────
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // ── Google API ──────────────────────────────────────
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ??
      const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  static String get openWeatherApiKey =>
      dotenv.env['OPENWEATHER_API_KEY'] ??
      const String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: '');

  // ── App Info ─────────────────────────────────────────
  static const String appName = 'TrackDIU';
  static const String appTagline = 'Campus Transit Tracker';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ── Map ──────────────────────────────────────────────
  static const double defaultLat = 23.8728;   // DIU main campus lat
  static const double defaultLng = 90.3984;   // DIU main campus lng
  static const double defaultZoom = 15.0;

  // ── Location Tracking ────────────────────────────────
  static const int locationIntervalSeconds = 30;
  static const double locationMinDistance = 10.0; // metres

  // ── Nearby Bus Threshold ─────────────────────────────
  static const double nearbyRadiusKm = 10.0;

  // ── Animation Durations ───────────────────────────────
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration medAnim   = Duration(milliseconds: 400);
  static const Duration longAnim  = Duration(milliseconds: 700);

  // ── OpenRouter ────────────────────────────────────────
  static String get openRouterApiKey =>
      dotenv.env['OPENROUTER_API_KEY'] ??
      const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');

  static String get openRouterModel =>
      dotenv.env['OPENROUTER_MODEL'] ?? 'openrouter/auto';

  // ── bKash Sandbox (demo/testing) ─────────────────────
  static String get bkashBaseSandboxUrl =>
      dotenv.env['BKASH_BASE_SANDBOX_URL'] ??
      'https://tokenized.sandbox.bka.sh/v1.2.0-beta';

  static String get bkashBaseLiveUrl =>
      dotenv.env['BKASH_BASE_LIVE_URL'] ??
      'https://tokenized.pay.bka.sh/v1.2.0-beta';

  static String get bkashUsername =>
      dotenv.env['BKASH_USERNAME'] ?? '';

  static String get bkashPassword =>
      dotenv.env['BKASH_PASSWORD'] ?? '';

  static String get bkashAppKey =>
      dotenv.env['BKASH_APP_KEY'] ?? '';

  static String get bkashAppSecret =>
      dotenv.env['BKASH_APP_SECRET'] ?? '';

  // ── Hive Box Names ────────────────────────────────────
  static const String busBox      = 'buses';
  static const String scheduleBox = 'schedules';
  static const String settingsBox = 'settings';

  // ── Border Radius ─────────────────────────────────────
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
}

// ── User Roles ──────────────────────────────────────────
enum UserRole { student, driver, admin }

// ── DIU Campus Bus Routes Removed (Now dynamic via Supabase) ──────────────

// ── Chatbot Rules ────────────────────────────────────────
const List<Map<String, String>> kChatbotRules = [
  {'trigger': 'mirpur', 'response': '🚌 Bus B-01 goes from Mirpur-1 to DIU Campus.\n⏰ Departure times: 7:00 AM, 12:00 PM, 5:00 PM'},
  {'trigger': 'dhanmondi', 'response': '🚌 Bus B-02 goes from Dhanmondi-27 to DIU Campus.\n⏰ Departure times: 7:30 AM, 12:30 PM, 5:30 PM'},
  {'trigger': 'uttara', 'response': '🚌 Bus B-03 goes from Uttara Sector-7 to DIU Campus.\n⏰ Departure times: 6:45 AM, 11:45 AM, 4:45 PM'},
  {'trigger': 'motijheel', 'response': '🚌 Bus B-04 goes from Motijheel to DIU Campus.\n⏰ Departure times: 7:15 AM, 12:15 PM, 5:15 PM'},
  {'trigger': 'gazipur', 'response': '🚌 Bus B-05 goes from Gazipur to DIU Campus.\n⏰ Departure times: 7:00 AM, 12:00 PM, 5:00 PM'},
  {'trigger': 'schedule', 'response': '📅 All buses depart at 7 AM, 12 PM, and 5 PM.\nType a location name for specific times!'},
  {'trigger': 'route', 'response': '🗺️ Available routes:\nB-01: Mirpur\nB-02: Dhanmondi\nB-03: Uttara\nB-04: Motijheel\nB-05: Gazipur'},
  {'trigger': 'contact', 'response': '📞 DIU Transport Office: +880 9617-888888\n📧 transport@diu.edu.bd'},
  {'trigger': 'hello', 'response': '👋 Hello! I\'m the TrackDIU assistant.\nAsk me about bus routes, schedules, or type a location name!'},
  {'trigger': 'hi', 'response': '👋 Hi there! How can I help you today?\nTry asking: "bus to mirpur" or "schedule"'},
  {'trigger': 'help', 'response': '🆘 I can help you with:\n• Bus routes (type location)\n• Schedules\n• Contact info\n• Route info'},
];
