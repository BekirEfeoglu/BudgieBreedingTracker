import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/home/widgets/section_header.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('renders title text', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const SectionHeader(title: 'My Section'),
      );

      expect(find.text('My Section'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const SectionHeader(
          title: 'With Icon',
          icon: Icon(Icons.star),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('does not render icon when null', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const SectionHeader(title: 'No Icon'),
      );

      // When icon is null, no Icon widget is rendered inside the header
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows view all button when onViewAll is provided',
        (tester) async {
      await pumpLocalizedWidget(
        tester,
        SectionHeader(title: 'Section', onViewAll: () {}),
      );

      // Localized key rendered as raw key in test
      expect(find.text('common.view_all'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('hides view all button when onViewAll is null',
        (tester) async {
      await pumpLocalizedWidget(
        tester,
        const SectionHeader(title: 'Section'),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('taps view all callback', (tester) async {
      var tapped = false;
      await pumpLocalizedWidget(
        tester,
        SectionHeader(title: 'Section', onViewAll: () => tapped = true),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('applies bold font weight to title', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const SectionHeader(title: 'Bold Title'),
      );

      final textWidget = tester.widget<Text>(find.text('Bold Title'));
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
