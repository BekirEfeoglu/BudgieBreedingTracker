import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_card_body.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_helpers.dart';

CommunityPost _post({
  CommunityPostType postType = CommunityPostType.general,
  String content = 'Hello budgies',
  String? title,
  List<String> imageUrls = const [],
  bool isPinned = false,
}) => CommunityPost(
  id: 'p1',
  userId: 'u1',
  username: 'alice',
  avatarUrl: null,
  content: content,
  title: title,
  postType: postType,
  createdAt: DateTime(2026, 4, 17),
  likeCount: 0,
  commentCount: 0,
  isLikedByMe: false,
  isFollowingAuthor: false,
  imageUrls: imageUrls,
  mutationTags: const [],
  tags: const [],
  isPinned: isPinned,
);

void main() {
  group('CommunityPostCardBody', () {
    testWidgets('renders post content', (tester) async {
      await pumpWidgetSimple(
        tester,
        CommunityPostCardBody(
          post: _post(content: 'The canary sings'),
          authorName: 'alice',
          authorAvatarUrl: null,
          showFullContent: false,
          maxContentLines: 3,
          isOwnPost: false,

          onEdit: null,
          onDelete: null,
          onReport: () {},
          onBlock: () {},
          onSendMessage: () {},
          onFollowToggle: () {},
          onDoubleTapMedia: () {},
          onOpenImage: (_) {},
        ),
      );
      expect(find.textContaining('canary'), findsOneWidget);
    });

    testWidgets('renders guide lead block for guide type', (tester) async {
      await pumpWidgetSimple(
        tester,
        CommunityPostCardBody(
          post: _post(postType: CommunityPostType.guide, title: 'Guide'),
          authorName: 'alice',
          authorAvatarUrl: null,
          showFullContent: false,
          maxContentLines: 3,
          isOwnPost: false,

          onEdit: null,
          onDelete: null,
          onReport: () {},
          onBlock: () {},
          onSendMessage: () {},
          onFollowToggle: () {},
          onDoubleTapMedia: () {},
          onOpenImage: (_) {},
        ),
      );
      // Guide lead block shows the guide tab label
      expect(find.textContaining('Guide', findRichText: true), findsWidgets);
    });

    testWidgets('renders pinned badge for general post without title', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        CommunityPostCardBody(
          post: _post(isPinned: true),
          authorName: 'alice',
          authorAvatarUrl: null,
          showFullContent: false,
          maxContentLines: 3,
          isOwnPost: false,
          onEdit: null,
          onDelete: null,
          onReport: () {},
          onBlock: () {},
          onSendMessage: () {},
          onFollowToggle: () {},
          onDoubleTapMedia: () {},
          onOpenImage: (_) {},
        ),
      );

      expect(find.text('community.pinned'), findsOneWidget);
    });
  });
}
