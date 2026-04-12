import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_user_selection_provider.dart';

void main() {
  group('AdminUserSelectionNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty set', () {
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('toggle adds user to selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(adminUserSelectionProvider), {'user-1'});
    });

    test('toggle removes user from selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('toggle with multiple users', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      container.read(adminUserSelectionProvider.notifier).toggle('user-2');
      container.read(adminUserSelectionProvider.notifier).toggle('user-3');
      expect(
        container.read(adminUserSelectionProvider),
        {'user-1', 'user-2', 'user-3'},
      );
    });

    test('toggle removes one user from multiple', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      container.read(adminUserSelectionProvider.notifier).toggle('user-2');
      container.read(adminUserSelectionProvider.notifier).toggle('user-3');
      container.read(adminUserSelectionProvider.notifier).toggle('user-2');
      expect(
        container.read(adminUserSelectionProvider),
        {'user-1', 'user-3'},
      );
    });

    test('selectAll replaces existing selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('old-user');
      container.read(adminUserSelectionProvider.notifier).selectAll(
        ['user-a', 'user-b', 'user-c'],
      );
      expect(
        container.read(adminUserSelectionProvider),
        {'user-a', 'user-b', 'user-c'},
      );
    });

    test('selectAll with empty list clears selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      container.read(adminUserSelectionProvider.notifier).selectAll([]);
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('clear empties selection', () {
      container.read(adminUserSelectionProvider.notifier).selectAll(
        ['user-a', 'user-b', 'user-c'],
      );
      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('clear on already empty selection is idempotent', () {
      container.read(adminUserSelectionProvider.notifier).clear();
      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });
  });

  group('isSelectionActiveProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('is false when selection is empty', () {
      expect(container.read(isSelectionActiveProvider), isFalse);
    });

    test('is true when selection has users', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isTrue);
    });

    test('reverts to false when selection is cleared', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isTrue);

      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(isSelectionActiveProvider), isFalse);
    });

    test('remains true when toggling different users', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isTrue);

      container.read(adminUserSelectionProvider.notifier).toggle('user-2');
      expect(container.read(isSelectionActiveProvider), isTrue);
    });

    test('reverts to false when last user is toggled off', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isTrue);

      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isFalse);
    });
  });

  group('selectedUserCountProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('is 0 when selection is empty', () {
      expect(container.read(selectedUserCountProvider), 0);
    });

    test('reflects count when users are toggled', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(selectedUserCountProvider), 1);

      container.read(adminUserSelectionProvider.notifier).toggle('user-2');
      expect(container.read(selectedUserCountProvider), 2);

      container.read(adminUserSelectionProvider.notifier).toggle('user-3');
      expect(container.read(selectedUserCountProvider), 3);
    });

    test('decrements when users are toggled off', () {
      container.read(adminUserSelectionProvider.notifier).selectAll(
        ['user-a', 'user-b', 'user-c'],
      );
      expect(container.read(selectedUserCountProvider), 3);

      container.read(adminUserSelectionProvider.notifier).toggle('user-b');
      expect(container.read(selectedUserCountProvider), 2);
    });

    test('reflects count from selectAll', () {
      container.read(adminUserSelectionProvider.notifier).selectAll(
        ['a', 'b', 'c', 'd', 'e'],
      );
      expect(container.read(selectedUserCountProvider), 5);
    });

    test('resets to 0 when cleared', () {
      container.read(adminUserSelectionProvider.notifier).selectAll(
        ['user-a', 'user-b', 'user-c'],
      );
      expect(container.read(selectedUserCountProvider), 3);

      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(selectedUserCountProvider), 0);
    });
  });

  group('Selection provider integration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('all providers reflect the same selection state', () {
      final notifier = container.read(adminUserSelectionProvider.notifier);
      notifier.selectAll(['u1', 'u2', 'u3']);

      expect(container.read(adminUserSelectionProvider), {'u1', 'u2', 'u3'});
      expect(container.read(isSelectionActiveProvider), isTrue);
      expect(container.read(selectedUserCountProvider), 3);
    });

    test('derived providers update when selection changes', () {
      final notifier = container.read(adminUserSelectionProvider.notifier);

      notifier.toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isTrue);
      expect(container.read(selectedUserCountProvider), 1);

      notifier.toggle('user-2');
      expect(container.read(selectedUserCountProvider), 2);

      notifier.clear();
      expect(container.read(isSelectionActiveProvider), isFalse);
      expect(container.read(selectedUserCountProvider), 0);
    });

    test('set immutability prevents external mutations', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      final selection = container.read(adminUserSelectionProvider);

      // External modification should not affect the stored state
      expect(selection.contains('user-1'), isTrue);
      expect(container.read(adminUserSelectionProvider).length, 1);
    });
  });
}
