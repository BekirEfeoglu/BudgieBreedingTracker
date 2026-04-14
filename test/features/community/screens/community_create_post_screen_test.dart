@Tags(['community'])
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CommunityCreatePostScreen', () {
    testWidgets('shows app bar with create title', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.create_post')), findsOneWidget);
    });

    testWidgets('shows share action in app bar', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.share_action')), findsOneWidget);
    });

    testWidgets('renders post type selector chips', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.post_type_general')), findsOneWidget);
      expect(find.text(l10n('community.post_type_photo')), findsOneWidget);
      expect(find.text(l10n('community.post_type_question')), findsOneWidget);
    });

    testWidgets('renders title and content fields', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.post_title_label')), findsOneWidget);
      expect(find.text(l10n('community.content_label')), findsOneWidget);
    });

    testWidgets('preselects initial post type when provided', (tester) async {
      await tester.pumpWidget(
        buildScope(
          const CommunityCreatePostScreen(
            initialPostType: CommunityPostType.guide,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final choiceChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, l10n('community.post_type_guide')),
      );

      expect(choiceChip.selected, isTrue);
      expect(find.text(l10n('community.quick_hint')), findsOneWidget);
    });

    testWidgets('renders tag input and add photo button', (tester) async {
      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.add_tags')), findsOneWidget);
      expect(find.text(l10n('community.add_photo')), findsOneWidget);
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

  group('CommunityCreatePostScreen – draft restore', () {
    testWidgets('shows restore dialog when draft exists', (tester) async {
      SharedPreferences.setMockInitialValues({
        'community_post_draft': jsonEncode({
          'title': 'Draft Title',
          'content': 'Draft Content',
          'postType': 'general',
          'tags': <String>[],
        }),
      });

      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.draft_found')), findsOneWidget);
      expect(find.text(l10n('community.draft_found_hint')), findsOneWidget);
    });

    testWidgets('restores draft content when user confirms', (tester) async {
      SharedPreferences.setMockInitialValues({
        'community_post_draft': jsonEncode({
          'title': 'Saved Title',
          'content': 'Saved content here',
          'postType': 'question',
          'tags': ['budgie', 'health'],
        }),
      });

      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text(l10n('community.draft_continue')));
      await tester.pumpAndSettle();

      // Title and content should be restored
      expect(find.text('Saved Title'), findsOneWidget);
      expect(find.text('Saved content here'), findsOneWidget);

      // Tags should be restored
      expect(find.text('budgie'), findsOneWidget);
      expect(find.text('health'), findsOneWidget);
    });

    testWidgets('clears draft when user discards', (tester) async {
      SharedPreferences.setMockInitialValues({
        'community_post_draft': jsonEncode({
          'title': 'Old Title',
          'content': 'Old content',
          'postType': 'general',
          'tags': <String>[],
        }),
      });

      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      // Tap Discard
      await tester.tap(find.text(l10n('community.draft_discard')));
      await tester.pumpAndSettle();

      // No content should be in the fields
      expect(find.text('Old Title'), findsNothing);
      expect(find.text('Old content'), findsNothing);

      // Draft should be cleared from prefs
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('community_post_draft'), isNull);
    });

    testWidgets('does not show restore dialog when no draft exists',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(buildScope(const CommunityCreatePostScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.draft_found')), findsNothing);
    });
  });

  group('CommunityCreatePostScreen – back confirmation', () {
    testWidgets('pops without dialog when content is empty', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const _HomeStub()),
          GoRoute(
            path: '/create',
            builder: (_, __) => ProviderScope(
              overrides: [
                createPostProvider.overrideWith(_FakeCreatePostNotifier.new),
              ],
              child: const CommunityCreatePostScreen(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Navigate to create screen
      navigatorKey.currentContext!.push('/create');
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.create_post')), findsOneWidget);

      // Simulate back — no content, so should just pop
      final NavigatorState navigator = tester.state(find.byType(Navigator).first);
      navigator.pop();
      await tester.pumpAndSettle();

      // Back at home
      expect(find.byType(_HomeStub), findsOneWidget);
    });

    testWidgets('shows unsaved changes dialog when content exists',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const _HomeStub()),
          GoRoute(
            path: '/create',
            builder: (_, __) => ProviderScope(
              overrides: [
                createPostProvider.overrideWith(_FakeCreatePostNotifier.new),
              ],
              child: const CommunityCreatePostScreen(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Navigate to create screen
      navigatorKey.currentContext!.push('/create');
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.create_post')), findsOneWidget);

      // Enter some content to trigger the confirmation dialog
      await tester.enterText(find.byType(TextField).first, 'Some title');
      await tester.pumpAndSettle();

      // Simulate back button via maybePop (triggers PopScope)
      final NavigatorState navigator =
          tester.state(find.byType(Navigator).first);
      navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.unsaved_changes')), findsOneWidget);
      expect(find.text(l10n('community.unsaved_changes_hint')), findsOneWidget);
    });
  });
}

class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Home')));
  }
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
