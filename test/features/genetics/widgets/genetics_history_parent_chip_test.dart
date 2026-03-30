import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_history_parent_chip.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('GeneticsHistoryParentChip', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(GeneticsHistoryParentChip(
          label: 'Father',
          mutations: ['Opaline', 'Cinnamon'],
          color: Colors.blue.shade50,
          icon: const Icon(LucideIcons.bird),
        )),
      );
      await tester.pump();

      expect(find.byType(GeneticsHistoryParentChip), findsOneWidget);
    });

    testWidgets('shows mutations joined by comma', (tester) async {
      await tester.pumpWidget(
        _wrap(GeneticsHistoryParentChip(
          label: 'Father',
          mutations: ['Opaline', 'Cinnamon'],
          color: Colors.blue.shade50,
          icon: const Icon(LucideIcons.bird),
        )),
      );
      await tester.pump();

      expect(find.text('Opaline, Cinnamon'), findsOneWidget);
    });

    testWidgets('shows normal mutation text when mutations list is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(GeneticsHistoryParentChip(
          label: 'Mother',
          mutations: [],
          color: Colors.pink.shade50,
          icon: const Icon(LucideIcons.bird),
        )),
      );
      await tester.pump();

      // Without EasyLocalization, .tr() returns the key
      expect(find.text(l10n('genetics.mutation_normal')), findsOneWidget);
    });

    testWidgets('displays the provided icon', (tester) async {
      await tester.pumpWidget(
        _wrap(GeneticsHistoryParentChip(
          label: 'Father',
          mutations: ['Blue'],
          color: Colors.blue.shade50,
          icon: const Icon(LucideIcons.bird),
        )),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.bird), findsOneWidget);
    });

    testWidgets('applies the given background color', (tester) async {
      final bgColor = Colors.green.shade100;
      await tester.pumpWidget(
        _wrap(GeneticsHistoryParentChip(
          label: 'Father',
          mutations: ['Spangle'],
          color: bgColor,
          icon: const Icon(LucideIcons.bird),
        )),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(bgColor));
    });

    testWidgets('shows single mutation without comma', (tester) async {
      await tester.pumpWidget(
        _wrap(GeneticsHistoryParentChip(
          label: 'Mother',
          mutations: ['Ino'],
          color: Colors.pink.shade50,
          icon: const Icon(LucideIcons.bird),
        )),
      );
      await tester.pump();

      expect(find.text('Ino'), findsOneWidget);
    });

    testWidgets('truncates long mutation list with ellipsis', (tester) async {
      await tester.pumpWidget(
        _wrap(SizedBox(
          width: 100,
          child: GeneticsHistoryParentChip(
            label: 'Father',
            mutations: [
              'Opaline',
              'Cinnamon',
              'Ino',
              'Spangle',
              'Violet',
            ],
            color: Colors.blue.shade50,
            icon: const Icon(LucideIcons.bird),
          ),
        )),
      );
      await tester.pump();

      // Widget has maxLines: 2 + ellipsis, so it renders without overflow
      expect(find.byType(GeneticsHistoryParentChip), findsOneWidget);
    });

    testWidgets('contains Row with icon and text', (tester) async {
      await tester.pumpWidget(
        _wrap(GeneticsHistoryParentChip(
          label: 'Father',
          mutations: ['Blue'],
          color: Colors.blue.shade50,
          icon: const Icon(LucideIcons.bird),
        )),
      );
      await tester.pump();

      expect(find.byType(Row), findsOneWidget);
    });
  });
}
