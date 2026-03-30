import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_history_card.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}
GeneticsHistory _makeEntry({
  String? notes,
  DateTime? createdAt,
  bool useNullDate = false,
  Map<String, String>? fatherGenotype,
  Map<String, String>? motherGenotype,
  String? resultsJson,
}) {
  return GeneticsHistory(
    id: 'test-history-id',
    userId: 'test-user-id',
    fatherGenotype: fatherGenotype ?? const {'blue': 'visual'},
    motherGenotype: motherGenotype ?? const {'opaline': 'visual'},
    resultsJson: resultsJson ??
        '[{"phenotype":"Normal Green","probability":0.5,"sex":"both","isCarrier":false},'
            '{"phenotype":"Blue","probability":0.25,"sex":"both","isCarrier":false},'
            '{"phenotype":"Opaline","probability":0.25,"sex":"both","isCarrier":false}]',
    notes: notes,
    createdAt: useNullDate ? null : (createdAt ?? DateTime(2025, 6, 15, 14, 30)),
    updatedAt: DateTime(2025, 6, 15, 14, 30),
  );
}

void main() {
  group('GeneticsHistoryCard', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byType(GeneticsHistoryCard), findsOneWidget);
    });

    testWidgets('shows Card widget', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows formatted date', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(createdAt: DateTime(2025, 3, 10, 9, 5)),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.text('10.03.2025 09:05'), findsOneWidget);
    });

    testWidgets('shows clock icon in header', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);
    });

    testWidgets('shows delete button when not in selection mode',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(AppIcon), findsAtLeastNWidgets(1));
    });

    testWidgets('shows checkbox in selection mode', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: true,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('checkbox is checked when isSelected is true', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: true,
            isSelectionMode: true,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('hides delete button in selection mode', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: true,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('shows total_variations text', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(
        find.textContaining(l10nContains('genetics.total_variations')),
        findsOneWidget,
      );
    });

    testWidgets('shows result chips when results exist', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byType(Chip), findsAtLeastNWidgets(1));
    });

    testWidgets('shows notes when present', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(notes: 'Test note for calculation'),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.text('Test note for calculation'), findsOneWidget);
    });

    testWidgets('does not show notes when null', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(notes: null),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      // Only the mandatory card texts should be present, no italic notes
      expect(find.text('Test note for calculation'), findsNothing);
    });

    testWidgets('shows parent mutation summary with icon chips',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      // Parent chips show AppIcon for male and female icons
      expect(find.byType(AppIcon), findsAtLeastNWidgets(2));
    });

    testWidgets('shows X cross icon between parents', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byIcon(LucideIcons.x), findsAtLeastNWidgets(1));
    });

    testWidgets('card has higher elevation when selected', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: true,
            isSelectionMode: true,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(4));
    });

    testWidgets('card has lower elevation when not selected', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(1));
    });

    testWidgets('onLongPress callback is registered on InkWell',
        (tester) async {
      var longPressed = false;

      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () => longPressed = true,
          ),
        ),
      );
      await tester.longPress(find.byType(InkWell).first);
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('onSelect callback fires in selection mode when tapped',
        (tester) async {
      var selected = false;

      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: true,
            onSelect: () => selected = true,
            onLongPress: () {},
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      expect(selected, isTrue);
    });

    testWidgets('shows delete dialog when delete button tapped',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n('common.confirm_delete')), findsOneWidget);
      expect(find.text(l10n('genetics.delete_history_confirm')), findsOneWidget);
    });

    testWidgets('shows date as dash when createdAt is null', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(useNullDate: true),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets(
        'shows mutation_normal for parent with empty genotype',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          GeneticsHistoryCard(
            entry: _makeEntry(
              fatherGenotype: const {},
              motherGenotype: const {},
            ),
            isSelected: false,
            isSelectionMode: false,
            onSelect: () {},
            onLongPress: () {},
          ),
        ),
      );
      // Both father and mother should show "Normal" when no mutations
      expect(
        find.text(l10n('genetics.mutation_normal')),
        findsNWidgets(2),
      );
    });
  });
}
