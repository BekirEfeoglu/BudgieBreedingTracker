import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_card_parts.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Widget createContentText({
    required String content,
    bool showFull = false,
    int maxLines = 3,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: ContentText(
            content: content,
            showFull: showFull,
            maxLines: maxLines,
          ),
        ),
      ),
    );
  }

  group('PostTypeBadge', () {
    for (final postType in CommunityPostType.values) {
      if (postType == CommunityPostType.unknown) continue;

      testWidgets('renders label for $postType', (tester) async {
        await tester.pumpWidget(wrap(PostTypeBadge(postType: postType)));
        await tester.pump();

        // Badge should render a Container with text
        expect(find.byType(PostTypeBadge), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });
    }

    testWidgets('unknown type renders general label', (tester) async {
      await tester.pumpWidget(
        wrap(const PostTypeBadge(postType: CommunityPostType.unknown)),
      );
      await tester.pump();

      // unknown maps to same label as general
      final generalWidget = tester.widget<PostTypeBadge>(
        find.byType(PostTypeBadge),
      );
      expect(generalWidget.postType, CommunityPostType.unknown);
    });

    testWidgets('uses primary color styling', (tester) async {
      await tester.pumpWidget(
        wrap(const PostTypeBadge(postType: CommunityPostType.photo)),
      );
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(AppSpacing.radiusFull),
      );
    });
  });

  group('EngagementSummary', () {
    CommunityPost createPost({int likes = 0, int comments = 0}) {
      return CommunityPost(
        id: 'test-post',
        userId: 'user-1',
        likeCount: likes,
        commentCount: comments,
      );
    }

    testWidgets('shows nothing when both counts are zero', (tester) async {
      await tester.pumpWidget(wrap(EngagementSummary(post: createPost())));
      await tester.pump();

      expect(find.byIcon(LucideIcons.heart), findsNothing);
      expect(find.byIcon(LucideIcons.messageCircle), findsNothing);
    });

    testWidgets('shows like count when > 0', (tester) async {
      await tester.pumpWidget(
        wrap(EngagementSummary(post: createPost(likes: 5))),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.heart), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows comment count when > 0', (tester) async {
      await tester.pumpWidget(
        wrap(EngagementSummary(post: createPost(comments: 12))),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('shows both counts when both > 0', (tester) async {
      await tester.pumpWidget(
        wrap(EngagementSummary(post: createPost(likes: 3, comments: 7))),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.heart), findsOneWidget);
      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('hides like icon when likeCount is zero', (tester) async {
      await tester.pumpWidget(
        wrap(EngagementSummary(post: createPost(comments: 1))),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.heart), findsNothing);
      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);
    });

    testWidgets('hides comment icon when commentCount is zero', (tester) async {
      await tester.pumpWidget(
        wrap(EngagementSummary(post: createPost(likes: 1))),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.heart), findsOneWidget);
      expect(find.byIcon(LucideIcons.messageCircle), findsNothing);
    });
  });

  group('ContentText', () {
    testWidgets('short text does not show read more', (tester) async {
      await tester.pumpWidget(createContentText(content: 'Short text'));
      await tester.pump();

      expect(find.text('Short text'), findsOneWidget);
      expect(find.text('community.read_more'), findsNothing);
    });

    testWidgets('long text shows read more', (tester) async {
      // 3 * 45 = 135 chars threshold
      final longContent = 'A' * 200;
      await tester.pumpWidget(createContentText(content: longContent));
      await tester.pump();

      expect(find.text('community.read_more'), findsOneWidget);
    });

    testWidgets('text with many newlines shows read more', (tester) async {
      const multiline = 'Line 1\nLine 2\nLine 3\nLine 4';
      await tester.pumpWidget(createContentText(content: multiline));
      await tester.pump();

      expect(find.text('community.read_more'), findsOneWidget);
    });

    testWidgets('text with few newlines does not show read more', (
      tester,
    ) async {
      const twoLines = 'Line 1\nLine 2';
      await tester.pumpWidget(createContentText(content: twoLines));
      await tester.pump();

      expect(find.text('community.read_more'), findsNothing);
    });

    testWidgets('showFull displays full content without truncation', (
      tester,
    ) async {
      final longContent = 'B' * 200;
      await tester.pumpWidget(
        createContentText(content: longContent, showFull: true),
      );
      await tester.pump();

      expect(find.text('community.read_more'), findsNothing);
      // Full content is shown
      expect(find.text(longContent), findsOneWidget);
    });

    testWidgets('maxLines parameter is respected', (tester) async {
      // With maxLines=1, threshold is 45 chars
      const content = 'This is a medium length text for testing purposes here.';
      await tester.pumpWidget(createContentText(content: content, maxLines: 1));
      await tester.pump();

      expect(find.text('community.read_more'), findsOneWidget);
    });

    testWidgets('empty content renders without error', (tester) async {
      await tester.pumpWidget(createContentText(content: ''));
      await tester.pump();

      expect(find.text('community.read_more'), findsNothing);
    });

    testWidgets('exactly at threshold does not show read more', (tester) async {
      // maxLines * 45 = 135 chars — exactly at threshold should not show
      final exactContent = 'C' * 135;
      await tester.pumpWidget(createContentText(content: exactContent));
      await tester.pump();

      expect(find.text('community.read_more'), findsNothing);
    });

    testWidgets('one char over threshold shows read more', (tester) async {
      final overContent = 'D' * 136;
      await tester.pumpWidget(createContentText(content: overContent));
      await tester.pump();

      expect(find.text('community.read_more'), findsOneWidget);
    });
  });

  group('BirdLinkChip', () {
    testWidgets('shows bird name when provided', (tester) async {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        birdId: 'bird-1',
        birdName: 'Maviş',
      );
      await tester.pumpWidget(wrap(const BirdLinkChip(post: post)));
      await tester.pump();

      expect(find.text('Maviş'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('shows fallback label when birdName is null', (tester) async {
      const post = CommunityPost(id: 'p1', userId: 'u1', birdId: 'bird-1');
      await tester.pumpWidget(wrap(const BirdLinkChip(post: post)));
      await tester.pump();

      // Falls back to localization key (not translated in test)
      expect(find.text('community.linked_bird'), findsOneWidget);
    });

    testWidgets('renders as ActionChip', (tester) async {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        birdId: 'bird-1',
        birdName: 'Sarı',
      );
      await tester.pumpWidget(wrap(const BirdLinkChip(post: post)));
      await tester.pump();

      expect(find.byType(ActionChip), findsOneWidget);
    });
  });

  group('PostTagWrap', () {
    testWidgets('renders mutation tags', (tester) async {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        mutationTags: ['Lutino', 'Albino'],
      );
      await tester.pumpWidget(wrap(const PostTagWrap(post: post)));
      await tester.pump();

      expect(find.text('Lutino'), findsOneWidget);
      expect(find.text('Albino'), findsOneWidget);
    });

    testWidgets('renders hashtags with # prefix', (tester) async {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        tags: ['budgie', 'breeding'],
      );
      await tester.pumpWidget(wrap(const PostTagWrap(post: post)));
      await tester.pump();

      expect(find.text('#budgie'), findsOneWidget);
      expect(find.text('#breeding'), findsOneWidget);
    });

    testWidgets('does not double # prefix on tags', (tester) async {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        tags: ['#alreadyPrefixed'],
      );
      await tester.pumpWidget(wrap(const PostTagWrap(post: post)));
      await tester.pump();

      expect(find.text('#alreadyPrefixed'), findsOneWidget);
      expect(find.text('##alreadyPrefixed'), findsNothing);
    });

    testWidgets('renders both mutation tags and hashtags', (tester) async {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        mutationTags: ['Spangle'],
        tags: ['rare'],
      );
      await tester.pumpWidget(wrap(const PostTagWrap(post: post)));
      await tester.pump();

      expect(find.text('Spangle'), findsOneWidget);
      expect(find.text('#rare'), findsOneWidget);
    });

    testWidgets('renders empty when no tags', (tester) async {
      const post = CommunityPost(id: 'p1', userId: 'u1');
      await tester.pumpWidget(wrap(const PostTagWrap(post: post)));
      await tester.pump();

      expect(find.byType(Wrap), findsOneWidget);
      // No tag chips rendered
      expect(find.byType(Container), findsNothing);
    });
  });
}
