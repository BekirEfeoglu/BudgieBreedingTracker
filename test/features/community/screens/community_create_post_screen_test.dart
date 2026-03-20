import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_create_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_create_post_screen.dart';

void main() {
  GoRouter buildRouter(Widget child) {
    return GoRouter(
      initialLocation: '/create',
      routes: [GoRoute(path: '/create', builder: (_, __) => child)],
    );
  }

  ProviderScope buildScope(
    Widget child, {
    CreatePostNotifier Function()? notifierFactory,
  }) {
    return ProviderScope(
      overrides: [
        createPostProvider.overrideWith(
          notifierFactory ?? _FakeCreatePostNotifier.new,
        ),
      ],
      child: MaterialApp.router(routerConfig: buildRouter(child)),
    );
  }

  group('CommunityCreatePostScreen', () {
    testWidgets('shows app bar with create title', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text('community.create_post'), findsOneWidget);
    });

    testWidgets('shows share action in app bar', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text('community.share_action'), findsOneWidget);
    });

    testWidgets('renders post type selector chips', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text('community.post_type_general'), findsOneWidget);
      expect(find.text('community.post_type_photo'), findsOneWidget);
      expect(find.text('community.post_type_question'), findsOneWidget);
    });

    testWidgets('renders title and content fields', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text('community.post_title_label'), findsOneWidget);
      expect(find.text('community.content_label'), findsOneWidget);
    });

    testWidgets('renders tag input and add photo button', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text('community.add_tags'), findsOneWidget);
      expect(find.text('community.add_photo'), findsOneWidget);
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    });

    testWidgets('shows loading indicator when submitting', (tester) async {
      await tester.pumpWidget(
        buildScope(
          const CommunityCreatePostScreen(),
          notifierFactory: () => _FakeCreatePostNotifier(isLoading: true),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class _FakeCreatePostNotifier extends CreatePostNotifier {
  final bool isLoading;

  _FakeCreatePostNotifier({this.isLoading = false});

  @override
  CreatePostState build() => CreatePostState(isLoading: isLoading);

  @override
  Future<void> createPost({
    required String content,
    CommunityPostType postType = CommunityPostType.general,
    String? title,
    List<String> tags = const [],
    List<XFile> images = const [],
  }) async {}
}
