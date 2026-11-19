// ====================================================
// core/error_handler.dart — Professional Business-Ready Error Handler
// ====================================================
import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorHandler {
  /// Converts any technical exception, database error, or network failure
  /// into a clean, professional, human-readable sentence.
  static String getFriendlyMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    final str = error.toString();
    final lower = str.toLowerCase();

    // 1. Network / DNS / Host lookup / Socket errors
    if (lower.contains('socketfailed') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('clientexception') ||
        lower.contains('networkerror') ||
        lower.contains('handshakeexception') ||
        lower.contains('authretryablefetchexception') ||
        lower.contains('errno = 7') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('timeoutexception')) {
      return 'Unable to reach the campus transit network. Please check your internet connection and try again.';
    }

    // 2. Supabase Auth Exceptions
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid email or password') ||
          msg.contains('invalid credentials')) {
        return 'Incorrect email or password. Please verify your details.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('already exists') ||
          msg.contains('unique constraint')) {
        return 'An account with this email address already exists. Please sign in instead.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Please confirm your email address before signing in.';
      }
      if (msg.contains('password should be at least')) {
        return 'Password is too weak. Please use at least 6 characters.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (error.message.isNotEmpty &&
          !error.message.contains('{') &&
          !error.message.contains('Exception:')) {
        return error.message;
      }
    }

    // 3. Postgrest (Database) Exceptions
    if (error is PostgrestException) {
      if (error.code == '42P01') {
        return 'Database service is temporarily undergoing maintenance.';
      }
      if (error.code == '23505') {
        return 'A record with this information already exists.';
      }
      if (error.code == 'PGRST301' ||
          error.code == '401' ||
          error.code == '403') {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.message.isNotEmpty &&
          !error.message.contains('{') &&
          !error.message.contains('uri=')) {
        return error.message;
      }
    }

    // 4. Common keywords
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid password')) {
      return 'Incorrect email or password. Please verify your details.';
    }
    if (lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'An account with this email address already exists. Please sign in instead.';
    }
    if (lower.contains('password') &&
        (lower.contains('weak') || lower.contains('least'))) {
      return 'Password must be at least 6 characters long.';
    }

    // 5. Clean up messy technical exception prefixes
    String cleaned = str
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException(message: ', '')
        .replaceAll('PostgrestException(message: ', '');

    // If it contains raw URLs, trace, or stack dumps, use professional fallback
    if (cleaned.contains('http://') ||
        cleaned.contains('https://') ||
        cleaned.contains('errno =') ||
        cleaned.contains('statusCode:') ||
        cleaned.contains('{')) {
      return 'Unable to complete the request right now. Please try again shortly.';
    }

    if (cleaned.endsWith(')')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    return cleaned.trim().isNotEmpty
        ? cleaned.trim()
        : 'An unexpected issue occurred. Please try again.';
  }
}
