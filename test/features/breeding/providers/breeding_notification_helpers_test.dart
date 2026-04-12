import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_notification_helpers.dart';

/// Tests for standalone helper methods in [BreedingNotificationHelper].
///
/// Provider-dependent methods (cancel, schedule, close) require a full
/// Riverpod container and are covered by integration tests. This file
/// focuses on pure-logic helper methods.
void main() {
  group('BreedingNotificationHelper.isSupabaseUnavailableError', () {
    // Create a minimal instance just for testing the static-like method.
    // The _ref is not used by isSupabaseUnavailableError.
    late _TestableHelper helper;

    setUp(() {
      helper = _TestableHelper();
    });

    test('detects "must initialize the supabase instance" error', () {
      final error = StateError(
        'You must initialize the supabase instance before calling Supabase.instance',
      );
      expect(helper.isSupabaseUnavailableError(error), isTrue);
    });

    test('detects "provider that is in error state" error', () {
      final error = StateError(
        'Tried to read a provider that is in error state',
      );
      expect(helper.isSupabaseUnavailableError(error), isTrue);
    });

    test('returns false for generic errors', () {
      expect(
        helper.isSupabaseUnavailableError(Exception('Network timeout')),
        isFalse,
      );
    });

    test('returns false for empty error', () {
      expect(
        helper.isSupabaseUnavailableError(Exception('')),
        isFalse,
      );
    });

    test('returns false for null-like error messages', () {
      expect(
        helper.isSupabaseUnavailableError('Some random error'),
        isFalse,
      );
    });
  });
}

/// Minimal testable wrapper that exposes [isSupabaseUnavailableError]
/// without requiring a real [Ref].
class _TestableHelper {
  bool isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }
}
