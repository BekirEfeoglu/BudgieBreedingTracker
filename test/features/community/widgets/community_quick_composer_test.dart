import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/community/widgets/community_quick_composer.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CommunityQuickComposer', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommunityQuickComposer), findsOneWidget);
    });

    testWidgets('shows user initial in avatar', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('shows content label hint', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.content_label')), findsOneWidget);
    });

    testWidgets('shows photo and create buttons', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.add_photo')), findsOneWidget);
      expect(find.text(l10n('community.create_post')), findsOneWidget);
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });

    testWidgets('calls onCreatePost when hint area is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () => called = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('community.content_label')));
      expect(called, isTrue);
    });
  });
}
