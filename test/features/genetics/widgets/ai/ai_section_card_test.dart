import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_section_card.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiSectionCard', () {
    testWidgets('renders title and subtitle', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiSectionCard(
          title: 'Card Title',
          icon: LucideIcons.image,
          subtitle: 'Card Subtitle',
          infoText: 'Info dialog text',
          child: Text('Child content'),
        ),
      );
      await tester.pump();

      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Subtitle'), findsOneWidget);
      expect(find.text('Child content'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiSectionCard(
          title: 'Title',
          icon: LucideIcons.search,
          subtitle: 'Subtitle',
          infoText: 'Info',
          child: SizedBox.shrink(),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.search), findsOneWidget);
    });

    testWidgets('has info button', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiSectionCard(
          title: 'Title',
          icon: LucideIcons.image,
          subtitle: 'Subtitle',
          infoText: 'Info dialog content',
          child: SizedBox.shrink(),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.info), findsOneWidget);
    });

    testWidgets('info button opens dialog', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiSectionCard(
          title: 'Dialog Title',
          icon: LucideIcons.image,
          subtitle: 'Subtitle',
          infoText: 'Dialog content text',
          child: SizedBox.shrink(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.info));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Dialog content text'), findsOneWidget);
    });

    testWidgets('has left accent bar', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiSectionCard(
          title: 'Title',
          icon: LucideIcons.image,
          subtitle: 'Subtitle',
          infoText: 'Info',
          child: SizedBox.shrink(),
        ),
      );
      await tester.pump();

      // Should have an IntrinsicHeight with a Row containing the accent bar
      expect(find.byType(IntrinsicHeight), findsOneWidget);
    });

    testWidgets('renders custom child widget', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiSectionCard(
          title: 'Title',
          icon: LucideIcons.image,
          subtitle: 'Subtitle',
          infoText: 'Info',
          child: TextField(),
        ),
      );
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
