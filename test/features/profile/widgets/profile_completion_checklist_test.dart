import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_completion_checklist.dart';

ProfileCompletion _buildCompletion({required List<CompletionItem> items}) {
  final completed = items.where((i) => i.isCompleted).length;
  final pct = items.isEmpty ? 0.0 : completed / items.length;
  return ProfileCompletion(percentage: pct, items: items);
}

void main() {
  group('SetNameBanner', () {
    testWidgets('shows message text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetNameBanner(message: 'Lütfen adınızı girin', onTap: () {}),
          ),
        ),
      );

      expect(find.text('Lütfen adınızı girin'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetNameBanner(
              message: 'Tap Banner',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('shows default icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetNameBanner(message: 'Test', onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.userPlus), findsOneWidget);
    });

    testWidgets('shows custom icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetNameBanner(
              message: 'Test',
              onTap: () {},
              icon: Icons.camera,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera), findsOneWidget);
    });

    testWidgets('shows chevron right arrow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetNameBanner(message: 'Test', onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });
  });

  group('CompletionCheckItem', () {
    testWidgets('shows item label key as text', (tester) async {
      const item = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCheckItem(item: item, onTap: () {}),
          ),
        ),
      );

      // Without easy_localization setup, key itself is displayed
      expect(find.text('profile.completion_name'), findsOneWidget);
    });

    testWidgets('shows circle icon when not completed', (tester) async {
      const item = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCheckItem(item: item, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.circle), findsOneWidget);
    });

    testWidgets('shows checkCircle2 icon when completed', (tester) async {
      const item = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCheckItem(item: item, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('shows chevron when not completed', (tester) async {
      const item = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCheckItem(item: item, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('does not show chevron when completed', (tester) async {
      const item = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCheckItem(item: item, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });

    testWidgets('calls onTap when not completed and tapped', (tester) async {
      var tapped = false;
      const item = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCheckItem(item: item, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when completed (disabled)', (
      tester,
    ) async {
      var tapped = false;
      const item = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCheckItem(item: item, onTap: () => tapped = true),
          ),
        ),
      );

      // onTap is null when completed — tapping should do nothing
      await tester.tap(find.byType(InkWell), warnIfMissed: false);
      expect(tapped, isFalse);
    });
  });

  group('CompletionChecklist', () {
    testWidgets('shows completion title key', (tester) async {
      final completion = _buildCompletion(
        items: [
          const CompletionItem(
            labelKey: 'profile.completion_name',
            isCompleted: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompletionChecklist(
                completion: completion,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      // Without l10n setup, shows raw key
      expect(find.text('profile.completion_title'), findsOneWidget);
    });

    testWidgets('shows one CompletionCheckItem per completion item', (
      tester,
    ) async {
      final completion = _buildCompletion(
        items: [
          const CompletionItem(
            labelKey: 'profile.completion_name',
            isCompleted: false,
          ),
          const CompletionItem(
            labelKey: 'profile.completion_avatar',
            isCompleted: true,
          ),
          const CompletionItem(
            labelKey: 'profile.completion_first_bird',
            isCompleted: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompletionChecklist(
                completion: completion,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CompletionCheckItem), findsNWidgets(3));
    });

    testWidgets('calls onItemTap with correct item', (tester) async {
      CompletionItem? tappedItem;
      const targetItem = CompletionItem(
        labelKey: 'profile.completion_name',
        isCompleted: false,
      );
      final completion = _buildCompletion(items: [targetItem]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompletionChecklist(
                completion: completion,
                onItemTap: (item) => tappedItem = item,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).last);
      expect(tappedItem?.labelKey, 'profile.completion_name');
    });

    testWidgets('renders empty list without error', (tester) async {
      final completion = _buildCompletion(items: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompletionChecklist(
                completion: completion,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CompletionChecklist), findsOneWidget);
      expect(find.byType(CompletionCheckItem), findsNothing);
    });
  });
}
