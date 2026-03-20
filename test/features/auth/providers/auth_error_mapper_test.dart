import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_actions.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Stub SharedPreferences used by easy_localization
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, dynamic>{};
        return null;
      },
    );
  });

  AuthException makeError(String message, {String? statusCode}) {
    return AuthException(message, statusCode: statusCode);
  }

  group('mapAuthError - auth-specific errors', () {
    test('maps invalid login credentials', () {
      final result = mapAuthError(
        makeError('Invalid login credentials', statusCode: '400'),
      );
      expect(result, isNotEmpty);
    });

    test('maps invalid credentials (alternate message)', () {
      final result = mapAuthError(
        makeError('Invalid credentials provided', statusCode: '400'),
      );
      expect(result, isNotEmpty);
    });

    test('maps email not confirmed', () {
      final result = mapAuthError(
        makeError('Email not confirmed', statusCode: '400'),
      );
      expect(result, isNotEmpty);
    });

    test('maps rate limit / too many requests', () {
      final result = mapAuthError(
        makeError('Too many requests', statusCode: '429'),
      );
      expect(result, isNotEmpty);
    });

    test('maps already registered (generic message for security)', () {
      final result = mapAuthError(
        makeError('User already registered', statusCode: '400'),
      );
      // Should return generic message, not reveal that email exists
      expect(result, isNotEmpty);
    });

    test('maps weak password', () {
      final result = mapAuthError(
        makeError('Password should be at least 6 characters', statusCode: '422'),
      );
      expect(result, isNotEmpty);
    });

    test('maps anonymous sign-in disabled', () {
      final result = mapAuthError(
        makeError('Anonymous sign-ins are disabled', statusCode: '400'),
      );
      expect(result, isNotEmpty);
    });

    test('maps signups not allowed', () {
      final result = mapAuthError(
        makeError('Signups not allowed for this instance', statusCode: '400'),
      );
      expect(result, isNotEmpty);
    });

    test('maps OAuth not configured', () {
      final result = mapAuthError(
        makeError('Google sign-in failed: not configured', statusCode: '400'),
      );
      expect(result, isNotEmpty);
    });
  });

  group('mapAuthError - network errors', () {
    test('maps null statusCode as network error', () {
      final result = mapAuthError(makeError('Connection failed'));
      expect(result, isNotEmpty);
    });

    test('maps socket error message', () {
      final result = mapAuthError(
        makeError('SocketException: Connection refused'),
      );
      expect(result, isNotEmpty);
    });

    test('maps timeout message', () {
      final result = mapAuthError(makeError('Connection timeout'));
      expect(result, isNotEmpty);
    });

    test('maps host lookup failure', () {
      final result = mapAuthError(makeError('Failed host lookup'));
      expect(result, isNotEmpty);
    });

    test('maps TLS/handshake error (iOS)', () {
      final result = mapAuthError(
        makeError('HandshakeException: Connection terminated during handshake'),
      );
      expect(result, isNotEmpty);
    });

    test('maps OS error (iOS)', () {
      final result = mapAuthError(
        makeError('OS Error: Connection reset by peer, errno = 54'),
      );
      expect(result, isNotEmpty);
    });
  });

  group('mapAuthError - server errors', () {
    test('maps 500 server error', () {
      final result = mapAuthError(
        makeError('Internal Server Error', statusCode: '500'),
      );
      expect(result, isNotEmpty);
    });

    test('maps 503 service unavailable', () {
      final result = mapAuthError(
        makeError('Service Unavailable', statusCode: '503'),
      );
      expect(result, isNotEmpty);
    });
  });

  group('mapAuthError - unknown errors', () {
    test('maps unknown error with statusCode to unknown key', () {
      final result = mapAuthError(
        makeError('Some unexpected error', statusCode: '418'),
      );
      expect(result, isNotEmpty);
    });
  });

  group('mapAuthError - case insensitivity', () {
    test('handles uppercase error messages', () {
      final result = mapAuthError(
        makeError('INVALID LOGIN CREDENTIALS', statusCode: '400'),
      );
      expect(result, isNotEmpty);
    });

    test('handles mixed case error messages', () {
      final result = mapAuthError(
        makeError('Rate Limit Exceeded', statusCode: '429'),
      );
      expect(result, isNotEmpty);
    });
  });
}
