import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_quick_composer.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('CommunityQuickComposer', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
            onCreateTypedPost: (_) {},
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
            onCreateTypedPost: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('shows placeholder hint text', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
            onCreateTypedPost: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.quick_hint')), findsOneWidget);
    });

    testWidgets('shows quick action icon buttons', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
            onCreateTypedPost: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.byIcon(LucideIcons.helpCircle), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
    });

    testWidgets('calls onCreatePost when hint area is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () => called = true,
            onCreateTypedPost: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('community.quick_hint')));
      expect(called, isTrue);
    });

    testWidgets('calls typed callback for question shortcut', (tester) async {
      CommunityPostType? selectedType;
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
            onCreateTypedPost: (type) => selectedType = type,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.helpCircle));

      expect(selectedType, CommunityPostType.question);
    });
  });
}
