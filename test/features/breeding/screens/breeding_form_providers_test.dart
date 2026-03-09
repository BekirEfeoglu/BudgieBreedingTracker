import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';

void main() {
  group('BreedingFormState', () {
    test('has correct defaults', () {
      const state = BreedingFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = BreedingFormState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.error, isNull);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith updates error', () {
      const state = BreedingFormState();
      final updated = state.copyWith(error: 'Something went wrong');
      expect(updated.error, 'Something went wrong');
      expect(updated.isLoading, isFalse);
    });

    test('copyWith clears error when not specified', () {
      final state = const BreedingFormState().copyWith(error: 'Old error');
      final cleared = state.copyWith(isLoading: true);
      // error parameter defaults to null when not specified
      expect(cleared.error, isNull);
    });

    test('copyWith updates isSuccess', () {
      const state = BreedingFormState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      final state = const BreedingFormState().copyWith(
        isLoading: true,
        error: 'Error',
        isSuccess: false,
      );
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isLoading, isTrue); // preserved
      expect(updated.error, isNull); // error always cleared unless specified
      expect(updated.isSuccess, isTrue); // updated
    });

    test('loading state is typically set with error cleared', () {
      const state = BreedingFormState();
      final loading = state.copyWith(
        isLoading: true,
        error: null,
        isSuccess: false,
      );
      expect(loading.isLoading, isTrue);
      expect(loading.error, isNull);
      expect(loading.isSuccess, isFalse);
    });

    test('success state pattern', () {
      const state = BreedingFormState();
      final success = state.copyWith(isLoading: false, isSuccess: true);
      expect(success.isLoading, isFalse);
      expect(success.isSuccess, isTrue);
    });

    test('error state pattern', () {
      const state = BreedingFormState();
      final errorState = state.copyWith(
        isLoading: false,
        error: 'Network error',
      );
      expect(errorState.isLoading, isFalse);
      expect(errorState.error, 'Network error');
      expect(errorState.isSuccess, isFalse);
    });
  });
}
