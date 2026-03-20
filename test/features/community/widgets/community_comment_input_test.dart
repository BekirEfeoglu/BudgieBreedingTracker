import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

      expect(find.text('community.add_comment'), findsOneWidget);
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
