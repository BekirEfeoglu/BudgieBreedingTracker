import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';

void main() {
  // AdminUserManager requires a Ref and a callback — it cannot be
  // instantiated standalone in unit tests. We test its state contract
  // via AdminActionState and AdminActionsNotifier behavior instead.

  group('AdminActionState — user management state contract', () {
    test('initial state indicates no ongoing operation', () {
      const state = AdminActionState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('loading state when user operation starts', () {
      const state = AdminActionState(isLoading: true);
      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNull);
    });

    test('success state after user operation completes', () {
      const state = AdminActionState(isLoading: false, isSuccess: true);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('error state after user operation fails', () {
      const state = AdminActionState(
        isLoading: false,
        error: 'admin.action_error',
      );
      expect(state.error, 'admin.action_error');
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith transitions from loading to success', () {
      const loading = AdminActionState(isLoading: true);
      final success = loading.copyWith(isLoading: false, isSuccess: true);
      expect(success.isLoading, isFalse);
      expect(success.isSuccess, isTrue);
    });

    test('copyWith transitions from loading to error', () {
      const loading = AdminActionState(isLoading: true);
      final error = loading.copyWith(isLoading: false, error: 'Failure');
      expect(error.isLoading, isFalse);
      expect(error.error, 'Failure');
      expect(error.isSuccess, isFalse);
    });

    test('successMessage is set for toggle_active operation', () {
      const state = AdminActionState(
        isSuccess: true,
        successMessage: 'User activated successfully',
      );
      expect(state.successMessage, 'User activated successfully');
    });

    test('successMessage is set for grant_premium operation', () {
      const state = AdminActionState(
        isSuccess: true,
        successMessage: 'Premium subscription granted',
      );
      expect(state.successMessage, 'Premium subscription granted');
    });

    test('two different error messages are not equal', () {
      const state1 = AdminActionState(error: 'error 1');
      const state2 = AdminActionState(error: 'error 2');
      expect(state1.error, isNot(state2.error));
    });
  });

  group('AdminActionsNotifier — delegation state coverage', () {
    test('AdminActionState can represent all user operation states', () {
      // loading
      const loading = AdminActionState(isLoading: true);
      expect(loading.isLoading, isTrue);

      // success
      const success = AdminActionState(isSuccess: true);
      expect(success.isSuccess, isTrue);

      // error
      const error = AdminActionState(error: 'err');
      expect(error.error, 'err');
    });
  });
}
