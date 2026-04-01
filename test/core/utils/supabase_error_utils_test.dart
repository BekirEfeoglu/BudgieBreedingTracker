import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/utils/supabase_error_utils.dart';

void main() {
  group('isSupabaseUnavailableError', () {
    test('returns true for missing initialization error', () {
      final error = StateError(
        'You must initialize the supabase instance before calling Supabase.instance',
      );

      expect(isSupabaseUnavailableError(error), isTrue);
    });

    test('returns true for provider in error state message', () {
      final error = Exception(
        'Tried to read a provider that is in error state after startup failure',
      );

      expect(isSupabaseUnavailableError(error), isTrue);
    });

    test('returns false for unrelated errors', () {
      expect(isSupabaseUnavailableError(Exception('Network timeout')), isFalse);
    });

    test('returns false for empty messages', () {
      expect(isSupabaseUnavailableError(Exception('')), isFalse);
    });
  });
}
