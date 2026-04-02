import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/api/remote_source_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockCommunitySocialRemoteSource mockSocialSource;
  late MockCommunityProfileCache mockProfileCache;

  setUp(() {
    mockSocialSource = MockCommunitySocialRemoteSource();
    mockProfileCache = MockCommunityProfileCache();
  });

  ProviderContainer createContainer({String userId = 'user-1'}) {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        communitySocialRemoteSourceProvider
            .overrideWithValue(mockSocialSource),
        communityProfileCacheProvider.overrideWithValue(mockProfileCache),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('followedUsersProvider', () {
    test('returns empty list for anonymous user', () async {
      final container = createContainer(userId: 'anonymous');

      final result = await container.read(followedUsersProvider.future);
      expect(result, isEmpty);

      verifyNever(() => mockSocialSource.fetchFollowedUserIds(any()));
    });

    test('returns empty list when no followed users', () async {
      when(() => mockSocialSource.fetchFollowedUserIds('user-1'))
          .thenAnswer((_) async => <String>{});

      final container = createContainer();

      final result = await container.read(followedUsersProvider.future);
      expect(result, isEmpty);

      verifyNever(() => mockProfileCache.getProfiles(any()));
    });

    test('returns followed user profiles', () async {
      when(() => mockSocialSource.fetchFollowedUserIds('user-1'))
          .thenAnswer((_) async => {'u2', 'u3'});

      when(() => mockProfileCache.getProfiles({'u2', 'u3'}))
          .thenAnswer((_) async => {
                'u2': {
                  'id': 'u2',
                  'display_name': 'Alice',
                  'full_name': 'Alice Smith',
                  'email': 'alice@test.com',
                  'avatar_url': 'https://example.com/alice.jpg',
                },
                'u3': {
                  'id': 'u3',
                  'display_name': null,
                  'full_name': 'Bob Jones',
                  'email': 'bob@test.com',
                  'avatar_url': null,
                },
              });

      final container = createContainer();

      final result = await container.read(followedUsersProvider.future);
      expect(result, hasLength(2));

      // First user: display_name available
      expect(result[0]['id'], 'u2');
      expect(result[0]['display_name'], 'Alice');
      expect(result[0]['avatar_url'], 'https://example.com/alice.jpg');

      // Second user: falls back to full_name
      expect(result[1]['id'], 'u3');
      expect(result[1]['display_name'], 'Bob Jones');
      expect(result[1]['avatar_url'], isNull);
    });

    test('falls back to email prefix when names are null', () async {
      when(() => mockSocialSource.fetchFollowedUserIds('user-1'))
          .thenAnswer((_) async => {'u4'});

      when(() => mockProfileCache.getProfiles({'u4'}))
          .thenAnswer((_) async => {
                'u4': {
                  'id': 'u4',
                  'display_name': null,
                  'full_name': null,
                  'email': 'charlie@test.com',
                  'avatar_url': null,
                },
              });

      final container = createContainer();

      final result = await container.read(followedUsersProvider.future);
      expect(result, hasLength(1));
      expect(result[0]['display_name'], 'charlie');
    });

    test('returns empty list on error', () async {
      when(() => mockSocialSource.fetchFollowedUserIds('user-1'))
          .thenThrow(Exception('network error'));

      final container = createContainer();

      final result = await container.read(followedUsersProvider.future);
      expect(result, isEmpty);
    });
  });
}
