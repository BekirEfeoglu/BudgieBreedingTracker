@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockCommunityPostRepository mockCommunityPostRepo;

  setUp(() {
    mockCommunityPostRepo = MockCommunityPostRepository();
  });

  ProviderContainer createContainer({String userId = 'user-1'}) {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        communityPostRepositoryProvider.overrideWithValue(
          mockCommunityPostRepo,
        ),
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

      verifyNever(
        () => mockCommunityPostRepo.getFollowedUserSummaries(
          currentUserId: any(named: 'currentUserId'),
        ),
      );
    });

    test('returns empty list when no followed users', () async {
      when(
        () => mockCommunityPostRepo.getFollowedUserSummaries(
          currentUserId: 'user-1',
        ),
      ).thenAnswer((_) async => []);

      final container = createContainer();

      final result = await container.read(followedUsersProvider.future);
      expect(result, isEmpty);
    });

    test('returns followed user profiles', () async {
      when(
        () => mockCommunityPostRepo.getFollowedUserSummaries(
          currentUserId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'u2',
            'display_name': 'Alice',
            'avatar_url': 'https://example.com/alice.jpg',
          },
          {'id': 'u3', 'display_name': 'Bob Jones', 'avatar_url': null},
        ],
      );

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
      when(
        () => mockCommunityPostRepo.getFollowedUserSummaries(
          currentUserId: 'user-1',
        ),
      ).thenAnswer(
        (_) async => [
          {'id': 'u4', 'display_name': 'charlie', 'avatar_url': null},
        ],
      );

      final container = createContainer();

      final result = await container.read(followedUsersProvider.future);
      expect(result, hasLength(1));
      expect(result[0]['display_name'], 'charlie');
    });

    test('returns empty list on error', () async {
      when(
        () => mockCommunityPostRepo.getFollowedUserSummaries(
          currentUserId: 'user-1',
        ),
      ).thenThrow(Exception('network error'));

      final container = createContainer();

      final result = await container.read(followedUsersProvider.future);
      expect(result, isEmpty);
    });
  });
}
