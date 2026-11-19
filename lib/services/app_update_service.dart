// ====================================================
// services/app_update_service.dart — In-app update checker
// ====================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../widgets/modern_update_dialog.dart';
import 'supabase_service.dart';

class AppUpdateService {
  static bool _hasCheckedThisSession = false;

  /// Checks for app updates against Supabase.
  /// [isManual]: When true, shows user feedback if they are already on the latest version.
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool isManual = false,
  }) async {
    if (!isManual && _hasCheckedThisSession) return;
    _hasCheckedThisSession = true;

    try {
      final latest = await SupabaseService().fetchLatestAppVersion();
      if (!context.mounted) return;

      if (latest != null && latest.versionCode > AppConstants.appBuildNumber) {
        // Newer version exists! Show modern dialog
        await ModernUpdateDialog.show(context, latest);
      } else if (isManual) {
        // User explicitly tapped "Check for updates"
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'TrackDIU is up to date (v${AppConstants.appVersion})',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (isManual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Text(
              'Could not check for updates right now.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ),
        );
      }
    }
  }
}
