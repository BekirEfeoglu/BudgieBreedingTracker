import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';

void main() {
  group('PendingMfaFactorIdNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(pendingMfaFactorIdProvider), isNull);
    });

    test('state can be set to a factor ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingMfaFactorIdProvider.notifier).state = 'factor-123';
      expect(container.read(pendingMfaFactorIdProvider), 'factor-123');
    });

    test('state can be cleared back to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingMfaFactorIdProvider.notifier).state = 'factor-123';
      container.read(pendingMfaFactorIdProvider.notifier).state = null;
      expect(container.read(pendingMfaFactorIdProvider), isNull);
    });
  });
}
