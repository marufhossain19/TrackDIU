// ====================================================
// core/theme.dart — App theme (light + dark)
// ====================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────
  static const Color primary     = Color(0xFF0A1F44);
  static const Color primaryLight= Color(0xFF1A3A6E);
  static const Color accent      = Color(0xFFFFC107);
  static const Color accentDark  = Color(0xFFE6A800);

  // ── Backgrounds ────────────────────────────────────
  static const Color bgLight     = Color(0xFFF5F7FA);
  static const Color bgDark      = Color(0xFF0D1117);
  static const Color surfaceLight= Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF161B24);
  static const Color cardDark    = Color(0xFF1E2533);

  // ── Text ───────────────────────────────────────────
  static const Color textDark    = Color(0xFF1A1A2E);
  static const Color textLight   = Color(0xFFFFFFFF);
  static const Color textMuted   = Color(0xFF6B7280);
  static const Color textMutedDark = Color(0xFF9CA3AF);

  // ── Semantic ───────────────────────────────────────
  static const Color success     = Color(0xFF10B981);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color error       = Color(0xFFEF4444);
  static const Color info        = Color(0xFF3B82F6);

  // ── Gradients ──────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static TextTheme _buildTextTheme(Color bodyColor, Color displayColor) {
    return TextTheme(
      displayLarge : GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: displayColor),
      displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: displayColor),
      displaySmall : GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: displayColor),
      headlineLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: displayColor),
      headlineMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: displayColor),
      headlineSmall: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: displayColor),
      titleLarge   : GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: displayColor),
      titleMedium  : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: bodyColor),
      titleSmall   : GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: bodyColor),
      bodyLarge    : GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: bodyColor),
      bodyMedium   : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor),
      bodySmall    : GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: bodyColor),
      labelLarge   : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: bodyColor),
      labelMedium  : GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: bodyColor),
      labelSmall   : GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: bodyColor),
    );
  }

  // ── Light Theme ────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary  : AppColors.primary,
        secondary: AppColors.accent,
        surface  : AppColors.surfaceLight,
        error    : AppColors.error,
        onPrimary: Colors.white,
        onSecondary: AppColors.textDark,
        onSurface: AppColors.textDark,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: _buildTextTheme(AppColors.textDark, AppColors.primary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 2,
        shadowColor: Color.fromRGBO(10, 31, 68, 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Color.fromRGBO(10, 31, 68, 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary  : AppColors.primaryLight,
        secondary: AppColors.accent,
        surface  : AppColors.surfaceDark,
        error    : AppColors.error,
        onPrimary: Colors.white,
        onSecondary: AppColors.textDark,
        onSurface: AppColors.textLight,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _buildTextTheme(AppColors.textLight, AppColors.accent),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        hintStyle: const TextStyle(color: Colors.white60),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIconColor: Colors.white70,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2D3748)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
