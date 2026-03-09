import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';

void main() {
  group('HealthRecordFormState', () {
    test('initial state has default values', () {
      const state = HealthRecordFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = HealthRecordFormState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith updates error', () {
      const state = HealthRecordFormState();
      final updated = state.copyWith(error: 'Something went wrong');
      expect(updated.error, 'Something went wrong');
    });

    test('copyWith clears error when null', () {
      final state = const HealthRecordFormState().copyWith(error: 'err');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith updates isSuccess', () {
      const state = HealthRecordFormState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const state = HealthRecordFormState(isLoading: true);
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
    });
  });
}
