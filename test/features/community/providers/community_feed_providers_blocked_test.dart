import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_social_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';

class _MockCommunitySocialRepository extends Mock
    implements CommunitySocialRepository {}

void main() {
  late _MockCommunitySocialRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _MockCommunitySocialRepository();
    when(
      () => repository.fetchBlockedUserIds(any()),
    ).thenAnswer((_) async => const []);
    when(
      () => repository.blockUser(
        userId: any(named: 'userId'),
        blockedUserId: any(named: 'blockedUserId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.unblockUser(
        userId: any(named: 'userId'),
        blockedUserId: any(named: 'blockedUserId'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer createContainer({String userId = 'user-1'}) {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        communitySocialRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  group('BlockedUsersNotifier - build', () {
    test('initial state is empty list', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(blockedUsersProvider);
      expect(state, isEmpty);
    });
  });

  group('BlockedUsersNotifier - load', () {
    test('loads local IDs from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['local-1', 'local-2'],
      });

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();

      final state = container.read(blockedUsersProvider);
      expect(state, containsAll(['local-1', 'local-2']));
    });

    test('merges local and server IDs without duplicates', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['shared-1', 'local-only'],
      });
      when(
        () => repository.fetchBlockedUserIds('user-1'),
      ).thenAnswer((_) async => ['shared-1', 'server-only']);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();

      final state = container.read(blockedUsersProvider);
      expect(state.toSet(), {'shared-1', 'local-only', 'server-only'});
    });

    test('skips server fetch for anonymous user', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['local-1'],
      });

      final container = createContainer(userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();

      expect(container.read(blockedUsersProvider), ['local-1']);
      verifyNever(() => repository.fetchBlockedUserIds(any()));
    });

    test('handles server fetch failure gracefully', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['local-1'],
      });
      when(
        () => repository.fetchBlockedUserIds(any()),
      ).thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();

      // Should still have local data despite server failure
      expect(container.read(blockedUsersProvider), ['local-1']);
    });
  });

  group('BlockedUsersNotifier - block', () {
    test('adds user ID optimistically', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      expect(container.read(blockedUsersProvider), contains('blocked-1'));
    });

    test('persists to SharedPreferences', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList(AppPreferences.keyBlockedUserIds),
        contains('blocked-1'),
      );
    });

    test('pushes block to server', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      verify(
        () => repository.blockUser(
          userId: 'user-1',
          blockedUserId: 'blocked-1',
        ),
      ).called(1);
    });

    test('does not duplicate already-blocked user', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      container.read(blockedUsersProvider.notifier).state = ['blocked-1'];
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      // No server call if already blocked
      verifyNever(
        () => repository.blockUser(
          userId: any(named: 'userId'),
          blockedUserId: any(named: 'blockedUserId'),
        ),
      );
    });

    test('does not push to server for anonymous user', () async {
      final container = createContainer(userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      // Should add locally but not push to server
      expect(container.read(blockedUsersProvider), contains('blocked-1'));
      verifyNever(
        () => repository.blockUser(
          userId: any(named: 'userId'),
          blockedUserId: any(named: 'blockedUserId'),
        ),
      );
    });

    test('keeps local state when server push fails', () async {
      when(
        () => repository.blockUser(
          userId: 'user-1',
          blockedUserId: 'blocked-1',
        ),
      ).thenThrow(Exception('server error'));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      expect(container.read(blockedUsersProvider), contains('blocked-1'));
    });
  });

  group('BlockedUsersNotifier - unblock', () {
    test('removes user ID optimistically', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['blocked-1', 'blocked-2'],
      });

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      container.read(blockedUsersProvider.notifier).state = [
        'blocked-1',
        'blocked-2',
      ];
      await container
          .read(blockedUsersProvider.notifier)
          .unblock('blocked-1');

      expect(
        container.read(blockedUsersProvider),
        isNot(contains('blocked-1')),
      );
      expect(container.read(blockedUsersProvider), contains('blocked-2'));
    });

    test('pushes unblock to server', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['blocked-1'],
      });

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      container.read(blockedUsersProvider.notifier).state = ['blocked-1'];
      await container
          .read(blockedUsersProvider.notifier)
          .unblock('blocked-1');

      verify(
        () => repository.unblockUser(
          userId: 'user-1',
          blockedUserId: 'blocked-1',
        ),
      ).called(1);
    });

    test('keeps local removal when server push fails', () async {
      when(
        () => repository.unblockUser(
          userId: 'user-1',
          blockedUserId: 'blocked-1',
        ),
      ).thenThrow(Exception('server error'));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      container.read(blockedUsersProvider.notifier).state = ['blocked-1'];
      await container
          .read(blockedUsersProvider.notifier)
          .unblock('blocked-1');

      expect(
        container.read(blockedUsersProvider),
        isNot(contains('blocked-1')),
      );
    });
  });
}
