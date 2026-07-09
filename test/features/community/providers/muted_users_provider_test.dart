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
      () => repository.fetchMutedUserIds(any()),
    ).thenAnswer((_) async => const []);
    when(
      () => repository.muteUser(
        userId: any(named: 'userId'),
        mutedUserId: any(named: 'mutedUserId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.unmuteUser(
        userId: any(named: 'userId'),
        mutedUserId: any(named: 'mutedUserId'),
      ),
    ).thenAnswer((_) async {});
  });

  group('mutedUsersProvider', () {
    test('loads local ids and merges unique server ids', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyMutedUserIds: ['local-1', 'shared'],
      });
      when(
        () => repository.fetchMutedUserIds('user-1'),
      ).thenAnswer((_) async => ['server-1', 'shared']);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(mutedUsersProvider);
      final notifier = container.read(mutedUsersProvider.notifier);
      await notifier.load();

      final state = container.read(mutedUsersProvider);
      final prefs = await SharedPreferences.getInstance();

      expect(state.toSet(), {'local-1', 'shared', 'server-1'});
      expect(prefs.getStringList(AppPreferences.keyMutedUserIds)?.toSet(), {
        'local-1',
        'shared',
        'server-1',
      });
      verify(
        () => repository.fetchMutedUserIds('user-1'),
      ).called(greaterThanOrEqualTo(1));
    });

    test('does not fetch server ids for anonymous user', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyMutedUserIds: ['local-only'],
      });

      final container = createContainer(userId: 'anonymous');
      addTearDown(container.dispose);

      container.read(mutedUsersProvider);
      await container.read(mutedUsersProvider.notifier).load();

      expect(container.read(mutedUsersProvider), ['local-only']);
      verifyNever(() => repository.fetchMutedUserIds(any()));
    });

    test(
      'mute adds id optimistically, persists it, and pushes to server',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        container.read(mutedUsersProvider);
        await container.read(mutedUsersProvider.notifier).load();
        await container.read(mutedUsersProvider.notifier).mute('muted-1');

        final prefs = await SharedPreferences.getInstance();
        expect(container.read(mutedUsersProvider), ['muted-1']);
        expect(prefs.getStringList(AppPreferences.keyMutedUserIds), [
          'muted-1',
        ]);
        verify(
          () => repository.muteUser(userId: 'user-1', mutedUserId: 'muted-1'),
        ).called(1);
      },
    );

    test('mute is a no-op when user is already muted', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyMutedUserIds: ['muted-1'],
      });

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(mutedUsersProvider);
      await container.read(mutedUsersProvider.notifier).load();
      container.read(mutedUsersProvider.notifier).state = ['muted-1'];
      await container.read(mutedUsersProvider.notifier).mute('muted-1');

      expect(container.read(mutedUsersProvider), ['muted-1']);
      verifyNever(
        () => repository.muteUser(
          userId: any(named: 'userId'),
          mutedUserId: any(named: 'mutedUserId'),
        ),
      );
    });

    test(
      'unmute removes id optimistically, persists it, and pushes to server',
      () async {
        SharedPreferences.setMockInitialValues({
          AppPreferences.keyMutedUserIds: ['muted-1', 'muted-2'],
        });

        final container = createContainer();
        addTearDown(container.dispose);

        container.read(mutedUsersProvider);
        await container.read(mutedUsersProvider.notifier).load();
        container.read(mutedUsersProvider.notifier).state = [
          'muted-1',
          'muted-2',
        ];
        await container.read(mutedUsersProvider.notifier).unmute('muted-1');

        final prefs = await SharedPreferences.getInstance();
        expect(container.read(mutedUsersProvider), ['muted-2']);
        expect(prefs.getStringList(AppPreferences.keyMutedUserIds), [
          'muted-2',
        ]);
        verify(
          () => repository.unmuteUser(
            userId: 'user-1',
            mutedUserId: 'muted-1',
          ),
        ).called(1);
      },
    );

    test('rolls back optimistic state when server mute call fails', () async {
      when(
        () => repository.muteUser(userId: 'user-1', mutedUserId: 'muted-1'),
      ).thenThrow(Exception('network failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(mutedUsersProvider);
      await container.read(mutedUsersProvider.notifier).load();
      await container.read(mutedUsersProvider.notifier).mute('muted-1');

      final prefs = await SharedPreferences.getInstance();
      expect(container.read(mutedUsersProvider), isEmpty);
      expect(prefs.getStringList(AppPreferences.keyMutedUserIds), isEmpty);
    });
  });
}
