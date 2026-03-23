import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/repositories/feedback_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';

// -- Fake FeedbackRepository --

class _FakeFeedbackRepository implements FeedbackRepository {
  final Object? _error;

  _FakeFeedbackRepository({Object? error}) : _error = error;

  @override
  Future<List<Map<String, dynamic>>> fetchByUser(String userId) async {
    if (_error != null) throw _error;
    return [];
  }

  @override
  Future<String> submit({
    required String userId,
    required String categoryValue,
    required String subject,
    required String message,
    String? email,
    String? appVersion,
    String? deviceInfo,
  }) async {
    if (_error != null) throw _error;
    return 'fake-feedback-id';
  }

  @override
  Future<void> notifyFounders({
    required String feedbackId,
    required String notificationTitle,
    required String subject,
  }) async {
    // No-op in tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedbackFormState', () {
    test('has correct defaults', () {
      const state = FeedbackFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = FeedbackFormState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.error, isNull);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith updates error', () {
      const state = FeedbackFormState();
      final updated = state.copyWith(error: 'Something went wrong');
      expect(updated.error, 'Something went wrong');
      expect(updated.isLoading, isFalse);
    });

    test('copyWith clears error when not specified', () {
      final state = const FeedbackFormState().copyWith(error: 'Old error');
      final cleared = state.copyWith(isLoading: true);
      // error parameter defaults to null when not specified
      expect(cleared.error, isNull);
    });

    test('copyWith updates isSuccess', () {
      const state = FeedbackFormState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      final state = const FeedbackFormState().copyWith(
        isLoading: true,
        error: 'Error',
        isSuccess: false,
      );
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isLoading, isTrue); // preserved
      expect(updated.error, isNull); // error always cleared unless specified
      expect(updated.isSuccess, isTrue); // updated
    });

    test('loading state pattern', () {
      const state = FeedbackFormState();
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
      const state = FeedbackFormState();
      final success = state.copyWith(isLoading: false, isSuccess: true);
      expect(success.isLoading, isFalse);
      expect(success.isSuccess, isTrue);
    });

    test('error state pattern', () {
      const state = FeedbackFormState();
      final errorState = state.copyWith(
        isLoading: false,
        error: 'Network error',
      );
      expect(errorState.isLoading, isFalse);
      expect(errorState.error, 'Network error');
      expect(errorState.isSuccess, isFalse);
    });
  });

  group('FeedbackCategory', () {
    test('has correct values', () {
      expect(FeedbackCategory.bug.value, 'bug');
      expect(FeedbackCategory.feature.value, 'feature');
      expect(FeedbackCategory.general.value, 'general');
    });

    test('has non-empty labels', () {
      for (final cat in FeedbackCategory.values) {
        expect(cat.label, isNotEmpty, reason: '${cat.name} label is empty');
      }
    });

    test('has icons', () {
      for (final cat in FeedbackCategory.values) {
        expect(cat.icon, isNotNull, reason: '${cat.name} icon is null');
      }
    });

    test('has colors', () {
      for (final cat in FeedbackCategory.values) {
        expect(cat.color, isA<Color>(), reason: '${cat.name} color is null');
      }
    });

    test('has non-empty descriptions', () {
      for (final cat in FeedbackCategory.values) {
        expect(
          cat.description,
          isNotEmpty,
          reason: '${cat.name} description is empty',
        );
      }
    });
  });

  group('FeedbackFormNotifier', () {
    late ProviderContainer container;

    ProviderContainer createContainer({Object? repoError}) {
      return ProviderContainer(
        overrides: [
          feedbackRepositoryProvider.overrideWithValue(
            _FakeFeedbackRepository(error: repoError),
          ),
          currentUserIdProvider.overrideWithValue('test-user'),
        ],
      );
    }

    tearDown(() {
      container.dispose();
    });

    test('submit sets loading then success on success', () async {
      container = createContainer();

      final states = <FeedbackFormState>[];
      container.listen<FeedbackFormState>(
        feedbackFormStateProvider,
        (_, state) => states.add(state),
        fireImmediately: false,
      );

      await container
          .read(feedbackFormStateProvider.notifier)
          .submit(
            category: FeedbackCategory.bug,
            subject: 'Test subject',
            message: 'Test message body',
          );

      // Should have at least loading -> success transitions
      expect(states.length, greaterThanOrEqualTo(2));

      // First state change: loading
      expect(states.first.isLoading, isTrue);
      expect(states.first.error, isNull);
      expect(states.first.isSuccess, isFalse);

      // Last state change: success
      expect(states.last.isLoading, isFalse);
      expect(states.last.isSuccess, isTrue);
      expect(states.last.error, isNull);
    });

    test('submit sets loading then error on failure', () async {
      container = createContainer(repoError: Exception('Network failure'));

      final states = <FeedbackFormState>[];
      container.listen<FeedbackFormState>(
        feedbackFormStateProvider,
        (_, state) => states.add(state),
        fireImmediately: false,
      );

      await container
          .read(feedbackFormStateProvider.notifier)
          .submit(
            category: FeedbackCategory.feature,
            subject: 'Test subject',
            message: 'Test message body',
          );

      expect(states.length, greaterThanOrEqualTo(2));

      // First: loading
      expect(states.first.isLoading, isTrue);

      // Last: error
      expect(states.last.isLoading, isFalse);
      expect(states.last.isSuccess, isFalse);
      expect(states.last.error, isNotNull);
      expect(states.last.error, contains('Network failure'));
    });

    test('reset clears state', () async {
      container = createContainer();

      // Submit first to change state
      await container
          .read(feedbackFormStateProvider.notifier)
          .submit(
            category: FeedbackCategory.general,
            subject: 'Test',
            message: 'Test message body',
          );

      final stateBeforeReset = container.read(feedbackFormStateProvider);
      expect(stateBeforeReset.isSuccess, isTrue);

      // Reset
      container.read(feedbackFormStateProvider.notifier).reset();

      final stateAfterReset = container.read(feedbackFormStateProvider);
      expect(stateAfterReset.isLoading, isFalse);
      expect(stateAfterReset.error, isNull);
      expect(stateAfterReset.isSuccess, isFalse);
    });
  });
}
