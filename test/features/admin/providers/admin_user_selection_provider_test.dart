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

    test('toggle adds a user', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(adminUserSelectionProvider), {'user-1'});
    });

    test('toggle removes an existing user', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('toggle supports multiple users', () {
      final notifier = container.read(adminUserSelectionProvider.notifier);
      notifier.toggle('a');
      notifier.toggle('b');
      notifier.toggle('c');
      expect(container.read(adminUserSelectionProvider), {'a', 'b', 'c'});
    });

    test('selectAll replaces current selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('old');
      container
          .read(adminUserSelectionProvider.notifier)
          .selectAll(['new-1', 'new-2']);
      expect(
        container.read(adminUserSelectionProvider),
        {'new-1', 'new-2'},
      );
    });

    test('selectAll with empty list results in empty set', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      container.read(adminUserSelectionProvider.notifier).selectAll([]);
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('clear empties all selections', () {
      container
          .read(adminUserSelectionProvider.notifier)
          .selectAll(['a', 'b']);
      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('clear on empty is idempotent', () {
      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('selectAll deduplicates IDs', () {
      container
          .read(adminUserSelectionProvider.notifier)
          .selectAll(['a', 'a', 'b']);
      expect(container.read(adminUserSelectionProvider), {'a', 'b'});
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

    test('false when no users selected', () {
      expect(container.read(isSelectionActiveProvider), isFalse);
    });

    test('true when users are selected', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isTrue);
    });

    test('becomes false when all users deselected', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
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

    test('returns 0 when empty', () {
      expect(container.read(selectedUserCountProvider), 0);
    });

    test('returns correct count', () {
      final notifier = container.read(adminUserSelectionProvider.notifier);
      notifier.toggle('a');
      notifier.toggle('b');
      expect(container.read(selectedUserCountProvider), 2);
    });

    test('decrements on removal', () {
      final notifier = container.read(adminUserSelectionProvider.notifier);
      notifier.selectAll(['a', 'b', 'c']);
      notifier.toggle('b');
      expect(container.read(selectedUserCountProvider), 2);
    });

    test('returns 0 after clear', () {
      container
          .read(adminUserSelectionProvider.notifier)
          .selectAll(['a', 'b']);
      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(selectedUserCountProvider), 0);
    });
  });

  group('provider integration', () {
    test('all derived providers stay in sync', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminUserSelectionProvider.notifier);
      notifier.selectAll(['u1', 'u2']);

      expect(container.read(adminUserSelectionProvider), {'u1', 'u2'});
      expect(container.read(isSelectionActiveProvider), isTrue);
      expect(container.read(selectedUserCountProvider), 2);

      notifier.clear();

      expect(container.read(adminUserSelectionProvider), isEmpty);
      expect(container.read(isSelectionActiveProvider), isFalse);
      expect(container.read(selectedUserCountProvider), 0);
    });
  });
}
