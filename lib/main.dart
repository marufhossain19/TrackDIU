// ====================================================
// main.dart — App entry point
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/auth/splash_screen.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Prevent Google Fonts from blocking main thread ───
  // Fonts use cached version or system fallback — no network on startup
  GoogleFonts.config.allowRuntimeFetching = false;

  // ── Status bar style ────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── Lock portrait orientation ────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Initialize Hive (local cache) ────────────────────
  await Hive.initFlutter();
  // Note: Hive type adapters would be registered here after running
  // build_runner. Using basic boxes without types for now to keep
  // the project runnable without code generation.
  await Hive.openBox(AppConstants.busBox);
  await Hive.openBox(AppConstants.scheduleBox);
  await Hive.openBox(AppConstants.settingsBox);

  // ── Initialize Supabase ──────────────────────────────
  await Supabase.initialize(
    url    : AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );


  runApp(
    // Riverpod ProviderScope wraps the entire app
    const ProviderScope(
      child: DIUSmartBusApp(),
    ),
  );
}

/// Root application widget
class DIUSmartBusApp extends ConsumerWidget {
  const DIUSmartBusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title        : AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme        : AppTheme.light,
      darkTheme    : AppTheme.dark,
      themeMode    : isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home         : const SplashScreen(),
      // ── Global page transition override ──────────────
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling from breaking layouts
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
