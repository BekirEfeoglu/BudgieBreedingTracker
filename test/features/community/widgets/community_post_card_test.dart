import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_card.dart';

CommunityPost createTestPost({
  String username = 'Test User',
  String content = 'Test content',
  String? avatarUrl,
  String? imageUrl,
  int likeCount = 5,
  int commentCount = 2,
}) {
  return CommunityPost(
    id: 'post-1',
    userId: 'user-1',
    username: username,
    avatarUrl: avatarUrl,
    content: content,
    imageUrl: imageUrl,
    likeCount: likeCount,
    commentCount: commentCount,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

void main() {
  Widget createSubject(CommunityPost post) {
    return ProviderScope(
      overrides: [
        supabaseInitializedProvider.overrideWithValue(false),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CommunityPostCard(post: post)),
        ),
      ),
    );
  }

  group('CommunityPostCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(createTestPost()));
      await tester.pump();

      expect(find.byType(CommunityPostCard), findsOneWidget);
    });

    testWidgets('shows username', (tester) async {
      await tester.pumpWidget(
        createSubject(createTestPost(username: 'John Doe')),
      );
      await tester.pump();

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('shows post content', (tester) async {
      await tester.pumpWidget(
        createSubject(createTestPost(content: 'Hello World!')),
      );
      await tester.pump();

      expect(find.text('Hello World!'), findsOneWidget);
    });

    testWidgets('shows like count', (tester) async {
      await tester.pumpWidget(createSubject(createTestPost(likeCount: 42)));
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows comment count', (tester) async {
      await tester.pumpWidget(createSubject(createTestPost(commentCount: 7)));
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows avatar initial when no avatarUrl', (tester) async {
      await tester.pumpWidget(createSubject(createTestPost(username: 'Alice')));
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows question mark initial when username is empty', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(createTestPost(username: '')));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows Card widget', (tester) async {
      await tester.pumpWidget(createSubject(createTestPost()));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows time info in relative format (hours)', (tester) async {
      await tester.pumpWidget(createSubject(createTestPost()));
      await tester.pump();

      // 2 hours ago → shows localized relative time
      expect(find.textContaining('2'), findsWidgets);
    });
  });
}
