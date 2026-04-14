@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/community/providers/community_comment_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_comment_input.dart';

void main() {
  Widget wrap(Widget child, CommentFormNotifier Function() notifierFactory) {
    return ProviderScope(
      overrides: [commentFormProvider.overrideWith(notifierFactory)],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CommunityCommentInput', () {
    testWidgets('renders text field and send button', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          _FakeCommentFormNotifier.new,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(LucideIcons.send), findsOneWidget);
    });

    testWidgets('shows hint text', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          _FakeCommentFormNotifier.new,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.add_comment')), findsOneWidget);
    });

    testWidgets('shows loading indicator when submitting', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          () => _FakeCommentFormNotifier(isLoading: true),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(LucideIcons.send), findsNothing);
    });

    testWidgets('text field is disabled during loading', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          () => _FakeCommentFormNotifier(isLoading: true),
        ),
      );
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('send button is dimmed when text is empty', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          _FakeCommentFormNotifier.new,
        ),
      );
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byIcon(LucideIcons.send),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('send button is fully opaque when text is entered',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          _FakeCommentFormNotifier.new,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello world');
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byIcon(LucideIcons.send),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, equals(1.0));
    });

    testWidgets('character counter is hidden below 800 chars', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          _FakeCommentFormNotifier.new,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'A' * 799);
      await tester.pumpAndSettle();

      // Counter text like "799/1000" should not appear
      expect(find.textContaining('/1000'), findsNothing);
    });

    testWidgets('character counter appears at 800+ chars', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          _FakeCommentFormNotifier.new,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'A' * 800);
      await tester.pumpAndSettle();

      expect(find.textContaining('/1000'), findsOneWidget);
    });

    testWidgets('character counter shows error color at 950+ chars',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const CommunityCommentInput(postId: 'post-1'),
          _FakeCommentFormNotifier.new,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'A' * 950);
      await tester.pumpAndSettle();

      final counterText = tester.widget<Text>(
        find.textContaining('/1000'),
      );
      final theme = Theme.of(tester.element(find.byType(TextField)));
      expect(
        counterText.style?.color,
        equals(theme.colorScheme.error),
      );
    });
  });
}

class _FakeCommentFormNotifier extends CommentFormNotifier {
  final bool isLoading;

  _FakeCommentFormNotifier({this.isLoading = false});

  @override
  CommentFormState build() => CommentFormState(isLoading: isLoading);

  @override
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {}
}
