// ====================================================
// core/constants.dart — App-wide constants
// ====================================================
class AppConstants {
  // ── Supabase ────────────────────────────────────────
  /// Replace with your actual Supabase project URL
  static const String supabaseUrl = 'https://jgxfribxfcuuyhenwxgm.supabase.co';
  /// Supabase anon (public) key
  static const String supabaseAnonKey = 'Use API key here';

  // ── Google API ──────────────────────────────────────
  static const String googleMapsApiKey = 'Use API key here';
  static const String openWeatherApiKey = 'Use API key here';

  // ── App Info ─────────────────────────────────────────
  static const String appName = 'TrackDIU';
  static const String appTagline = 'Campus Transit Tracker';

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

  // ── OpenRouter (demo/testing) ─────────────────────────
  static const String openRouterApiKey = 'Use API key here';
  static const String openRouterModel = 'openrouter/auto';

  // ── bKash Sandbox (demo/testing) ─────────────────────
  static const String bkashBaseSandboxUrl =
      'https://tokenized.sandbox.bka.sh/v1.2.0-beta';
  static const String bkashBaseLiveUrl =
      'https://tokenized.pay.bka.sh/v1.2.0-beta';
  static const String bkashUsername = 'sandboxTokenizedUser02';
  static const String bkashPassword = 'sandboxTokenizedUser02@12345';
  static const String bkashAppKey = 'Use API key here';
  static const String bkashAppSecret = 'Use API key here';

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
  {'trigger': 'contact', 'response': '📞 DIU Transport Office: 01712-345678\n📧 transport@diu.edu.bd'},
  {'trigger': 'hello', 'response': '👋 Hello! I\'m the TrackDIU assistant.\nAsk me about bus routes, schedules, or type a location name!'},
  {'trigger': 'hi', 'response': '👋 Hi there! How can I help you today?\nTry asking: "bus to mirpur" or "schedule"'},
  {'trigger': 'help', 'response': '🆘 I can help you with:\n• Bus routes (type location)\n• Schedules\n• Contact info\n• Route info'},
];
