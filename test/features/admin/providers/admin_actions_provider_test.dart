import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';

void main() {
  group('AdminActionState', () {
    test('default values', () {
      const state = AdminActionState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.successMessage, isNull);
    });

    test('copyWith updates isLoading', () {
      const state = AdminActionState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.error, isNull);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith updates isSuccess', () {
      const state = AdminActionState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith sets error', () {
      const state = AdminActionState();
      final updated = state.copyWith(error: 'Something went wrong');
      expect(updated.error, 'Something went wrong');
    });

    test('copyWith clears error when null passed', () {
      const state = AdminActionState(error: 'prev error');
      final updated = state.copyWith(error: null);
      expect(updated.error, isNull);
    });

    test('copyWith updates successMessage', () {
      const state = AdminActionState();
      final updated = state.copyWith(successMessage: 'Export done');
      expect(updated.successMessage, 'Export done');
    });

    test('preserves unset fields on copyWith', () {
      const state = AdminActionState(isLoading: true, isSuccess: false);
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
    });
  });

  group('AdminActionsNotifier', () {
    test('initial state is default AdminActionState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(adminActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('reset() returns state to default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Manually set state to non-default
      container.read(adminActionsProvider.notifier).reset();
      final state = container.read(adminActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('notifier type is AdminActionsNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminActionsProvider.notifier);
      expect(notifier, isA<AdminActionsNotifier>());
    });

    test('state is initially not loading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(adminActionsProvider).isLoading, isFalse);
    });

    test('state can be read multiple times without side effect', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state1 = container.read(adminActionsProvider);
      final state2 = container.read(adminActionsProvider);
      expect(state1.isLoading, state2.isLoading);
      expect(state1.error, state2.error);
      expect(state1.isSuccess, state2.isSuccess);
    });
  });
}
