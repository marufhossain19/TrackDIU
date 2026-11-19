import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diu_smartbus/core/error_handler.dart';

void main() {
  group('AppErrorHandler Tests', () {
    test('handles null error gracefully', () {
      final msg = AppErrorHandler.getFriendlyMessage(null);
      expect(msg, 'An unexpected error occurred. Please try again.');
    });

    test('translates network / socket / DNS failures to clean user messages', () {
      final msg = AppErrorHandler.getFriendlyMessage(
        'ClientException with SocketFailed host lookup: api.supabase.co',
      );
      expect(
        msg,
        'Unable to reach the campus transit network. Please check your internet connection and try again.',
      );
    });

    test('translates invalid credentials error', () {
      const authErr = AuthException('Invalid login credentials');
      final msg = AppErrorHandler.getFriendlyMessage(authErr);
      expect(msg, 'Incorrect email or password. Please verify your details.');
    });

    test('translates duplicate user registration error', () {
      const authErr = AuthException('User already registered');
      final msg = AppErrorHandler.getFriendlyMessage(authErr);
      expect(
        msg,
        'An account with this email address already exists. Please sign in instead.',
      );
    });

    test('translates database duplicate key error', () {
      const dbErr = PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );
      final msg = AppErrorHandler.getFriendlyMessage(dbErr);
      expect(msg, 'A record with this information already exists.');
    });

    test('translates session expired error', () {
      const dbErr = PostgrestException(
        message: 'JWT expired',
        code: 'PGRST301',
      );
      final msg = AppErrorHandler.getFriendlyMessage(dbErr);
      expect(msg, 'Your session has expired. Please sign in again.');
    });
  });
}
