@Tags(['community'])
library;

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

  ProviderContainer createContainer({String userId = 'user-1'}) {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        communitySocialRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

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

  group('blockedUsersProvider', () {
    test('loads local ids and merges unique server ids', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['local-1', 'shared'],
      });
      when(
        () => repository.fetchBlockedUserIds('user-1'),
      ).thenAnswer((_) async => ['server-1', 'shared']);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      final notifier = container.read(blockedUsersProvider.notifier);
      await notifier.load();

      final state = container.read(blockedUsersProvider);
      final prefs = await SharedPreferences.getInstance();

      expect(state.toSet(), {'local-1', 'shared', 'server-1'});
      expect(prefs.getStringList(AppPreferences.keyBlockedUserIds)?.toSet(), {
        'local-1',
        'shared',
        'server-1',
      });
      verify(
        () => repository.fetchBlockedUserIds('user-1'),
      ).called(greaterThanOrEqualTo(1));
    });

    test('does not fetch server ids for anonymous user', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['local-only'],
      });

      final container = createContainer(userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();

      expect(container.read(blockedUsersProvider), ['local-only']);
      verifyNever(() => repository.fetchBlockedUserIds(any()));
    });

    test(
      'block adds id optimistically, persists it, and pushes to server',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        container.read(blockedUsersProvider);
        await container.read(blockedUsersProvider.notifier).load();
        await container.read(blockedUsersProvider.notifier).block('blocked-1');

        final prefs = await SharedPreferences.getInstance();
        expect(container.read(blockedUsersProvider), ['blocked-1']);
        expect(prefs.getStringList(AppPreferences.keyBlockedUserIds), [
          'blocked-1',
        ]);
        verify(
          () => repository.blockUser(
            userId: 'user-1',
            blockedUserId: 'blocked-1',
          ),
        ).called(1);
      },
    );

    test('block is a no-op when user is already blocked', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyBlockedUserIds: ['blocked-1'],
      });

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      container.read(blockedUsersProvider.notifier).state = ['blocked-1'];
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      expect(container.read(blockedUsersProvider), ['blocked-1']);
      verifyNever(
        () => repository.blockUser(
          userId: any(named: 'userId'),
          blockedUserId: any(named: 'blockedUserId'),
        ),
      );
    });

    test(
      'unblock removes id optimistically, persists it, and pushes to server',
      () async {
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

        final prefs = await SharedPreferences.getInstance();
        expect(container.read(blockedUsersProvider), ['blocked-2']);
        expect(prefs.getStringList(AppPreferences.keyBlockedUserIds), [
          'blocked-2',
        ]);
        verify(
          () => repository.unblockUser(
            userId: 'user-1',
            blockedUserId: 'blocked-1',
          ),
        ).called(1);
      },
    );

    test('rolls back optimistic state when server block call fails', () async {
      when(
        () =>
            repository.blockUser(userId: 'user-1', blockedUserId: 'blocked-1'),
      ).thenThrow(Exception('network failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(blockedUsersProvider);
      await container.read(blockedUsersProvider.notifier).load();
      await container.read(blockedUsersProvider.notifier).block('blocked-1');

      final prefs = await SharedPreferences.getInstance();
      expect(container.read(blockedUsersProvider), isEmpty);
      expect(
        prefs.getStringList(AppPreferences.keyBlockedUserIds),
        isEmpty,
      );
    });
  });
}
