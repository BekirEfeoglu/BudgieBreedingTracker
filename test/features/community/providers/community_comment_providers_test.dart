@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/community/providers/community_comment_providers.dart';

void main() {
  group('CommentFormState', () {
    test('has sensible defaults', () {
      const state = CommentFormState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = CommentFormState();

      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.error, isNull);

      final errored = state.copyWith(error: 'failed');
      expect(errored.error, 'failed');
      expect(errored.isLoading, isFalse);

      final success = state.copyWith(isSuccess: true);
      expect(success.isSuccess, isTrue);
    });

    test('copyWith clears error when set to null', () {
      final state = const CommentFormState().copyWith(error: 'oops');
      expect(state.error, 'oops');

      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('CommentFormNotifier', () {
    test('reset returns to initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Access to trigger build
      container.read(commentFormProvider);

      // Simulate state change
      container.read(commentFormProvider.notifier).reset();

      final state = container.read(commentFormProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });
}
