@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/community/providers/community_create_providers.dart';

void main() {
  group('CreatePostState', () {
    test('has sensible defaults', () {
      const state = CreatePostState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = CreatePostState();

      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.error, isNull);
      expect(loading.isSuccess, isFalse);

      final errored = state.copyWith(error: 'Upload failed');
      expect(errored.error, 'Upload failed');

      final success = state.copyWith(isSuccess: true);
      expect(success.isSuccess, isTrue);
    });

    test('copyWith clears error on new attempt', () {
      final state = const CreatePostState().copyWith(error: 'failed');
      final retrying = state.copyWith(isLoading: true, error: null);

      expect(retrying.isLoading, isTrue);
      expect(retrying.error, isNull);
    });
  });

  group('CreatePostNotifier', () {
    test('reset returns to initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(createPostProvider);
      container.read(createPostProvider.notifier).reset();

      final state = container.read(createPostProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });
}
