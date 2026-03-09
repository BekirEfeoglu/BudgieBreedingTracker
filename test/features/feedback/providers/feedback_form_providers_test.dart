import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';

// -- Fakes for Supabase insert chain --

/// A fake that acts as a Future-like PostgrestFilterBuilder.
/// When awaited (via `.then()`), resolves or rejects based on [_error].
class _FakeFilterBuilder extends Fake implements PostgrestFilterBuilder {
  final Object? _error;

  _FakeFilterBuilder({Object? error}) : _error = error;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(dynamic) onValue, {
    Function? onError,
  }) {
    if (_error != null) {
      final future = Future<dynamic>.error(_error);
      return future.then(onValue, onError: onError);
    }
    return Future.value(onValue(null));
  }
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Object? _error;

  _FakeQueryBuilder({Object? error}) : _error = error;

  @override
  PostgrestFilterBuilder insert(Object values, {bool defaultToNull = true}) {
    return _FakeFilterBuilder(error: _error);
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  final Object? error;

  _FakeSupabaseClient({this.error});

  @override
  SupabaseQueryBuilder from(String table) {
    return _FakeQueryBuilder(error: error);
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

    ProviderContainer createContainer({Object? supabaseError}) {
      return ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(
            _FakeSupabaseClient(error: supabaseError),
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

      // Should have at least loading → success transitions
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
      container = createContainer(supabaseError: Exception('Network failure'));

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
