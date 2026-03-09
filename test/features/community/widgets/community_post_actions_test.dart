import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_social_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_actions.dart';

class MockCommunitySocialRepository extends Mock
    implements CommunitySocialRepository {}

CommunityPost _testPost({
  String id = 'post-1',
  bool isLikedByMe = false,
  bool isBookmarkedByMe = false,
  int likeCount = 0,
  int commentCount = 0,
}) {
  return CommunityPost(
    id: id,
    userId: 'user-1',
    username: 'TestUser',
    content: 'Test content',
    likeCount: likeCount,
    commentCount: commentCount,
    isLikedByMe: isLikedByMe,
    isBookmarkedByMe: isBookmarkedByMe,
    createdAt: DateTime.now(),
  );
}

void main() {
  late MockCommunitySocialRepository mockSocialRepo;

  setUp(() {
    mockSocialRepo = MockCommunitySocialRepository();
  });

  Widget createSubject(
    CommunityPost post, {
    String currentUserId = 'test-user',
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        communitySocialRepositoryProvider.overrideWithValue(mockSocialRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CommunityPostActions(post: post),
        ),
      ),
    );
  }

  group('CommunityPostActions', () {
    testWidgets('renders 4 action buttons', (tester) async {
      await tester.pumpWidget(createSubject(_testPost()));
      await tester.pump();

      // Like, comment, share, bookmark = 4 InkWell
      expect(find.byType(InkWell), findsNWidgets(4));
    });

    testWidgets('tap like button calls toggleLike', (tester) async {
      when(() => mockSocialRepo.toggleLike(
            userId: any(named: 'userId'),
            postId: any(named: 'postId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(createSubject(_testPost(id: 'p-1')));
      await tester.pump();

      // First InkWell is the like button
      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      verify(() => mockSocialRepo.toggleLike(
            userId: 'test-user',
            postId: 'p-1',
          )).called(1);
    });

    testWidgets('tap bookmark button calls toggleBookmark', (tester) async {
      when(() => mockSocialRepo.toggleBookmark(
            userId: any(named: 'userId'),
            postId: any(named: 'postId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(createSubject(_testPost(id: 'p-2')));
      await tester.pump();

      // Last InkWell is the bookmark button
      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.last);
      await tester.pumpAndSettle();

      verify(() => mockSocialRepo.toggleBookmark(
            userId: 'test-user',
            postId: 'p-2',
          )).called(1);
    });

    testWidgets('anonymous user like does nothing', (tester) async {
      await tester.pumpWidget(createSubject(
        _testPost(id: 'p-3'),
        currentUserId: 'anonymous',
      ));
      await tester.pump();

      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      verifyNever(() => mockSocialRepo.toggleLike(
            userId: any(named: 'userId'),
            postId: any(named: 'postId'),
          ));
    });

    testWidgets('anonymous user bookmark does nothing', (tester) async {
      await tester.pumpWidget(createSubject(
        _testPost(id: 'p-4'),
        currentUserId: 'anonymous',
      ));
      await tester.pump();

      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.last);
      await tester.pumpAndSettle();

      verifyNever(() => mockSocialRepo.toggleBookmark(
            userId: any(named: 'userId'),
            postId: any(named: 'postId'),
          ));
    });

    testWidgets('like button handles error gracefully', (tester) async {
      when(() => mockSocialRepo.toggleLike(
            userId: any(named: 'userId'),
            postId: any(named: 'postId'),
          )).thenThrow(Exception('Server error'));

      await tester.pumpWidget(createSubject(_testPost(id: 'p-5')));
      await tester.pump();

      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      // Should not crash — error is caught in provider
      expect(find.byType(CommunityPostActions), findsOneWidget);
    });
  });
}
