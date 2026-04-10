import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Egg _buildEgg({
  String id = 'egg-1',
  EggStatus status = EggStatus.laid,
}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2026, 2, 1),
    status: status,
  );
}

void main() {
  group('EggSummaryRow', () {
    testWidgets('renders without crashing', (tester) async {
      final eggs = [_buildEgg()];

      await tester.pumpWidget(_wrap(EggSummaryRow(eggs: eggs)));
      await tester.pump();

      expect(find.byType(EggSummaryRow), findsOneWidget);
    });

    testWidgets('delegates to EggSummaryRow', (tester) async {
      final eggs = [_buildEgg()];

      await tester.pumpWidget(_wrap(EggSummaryRow(eggs: eggs)));
      await tester.pump();

      expect(find.byType(EggSummaryRow), findsOneWidget);
    });

    testWidgets('passes eggs to EggSummaryRow', (tester) async {
      final eggs = [
        _buildEgg(id: 'egg-1', status: EggStatus.laid),
        _buildEgg(id: 'egg-2', status: EggStatus.hatched),
      ];

      await tester.pumpWidget(_wrap(EggSummaryRow(eggs: eggs)));
      await tester.pump();

      final summaryRow = tester.widget<EggSummaryRow>(
        find.byType(EggSummaryRow),
      );
      expect(summaryRow.eggs, eggs);
    });

    testWidgets('shows egg icons for each egg', (tester) async {
      final eggs = [
        _buildEgg(id: 'egg-1', status: EggStatus.laid),
        _buildEgg(id: 'egg-2', status: EggStatus.laid),
        _buildEgg(id: 'egg-3', status: EggStatus.hatched),
      ];

      await tester.pumpWidget(_wrap(EggSummaryRow(eggs: eggs)));
      await tester.pump();

      expect(find.byType(AppIcon), findsNWidgets(3));
    });

    testWidgets('shows no eggs text for empty list via EggSummaryRow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const EggSummaryRow(eggs: [])),
      );
      await tester.pump();

      expect(find.text(l10n('eggs.summary_no_eggs')), findsOneWidget);
    });

    testWidgets('shows single egg with laid status', (tester) async {
      final eggs = [_buildEgg(id: 'egg-1', status: EggStatus.laid)];

      await tester.pumpWidget(_wrap(EggSummaryRow(eggs: eggs)));
      await tester.pump();

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('shows mixed egg statuses', (tester) async {
      final eggs = [
        _buildEgg(id: 'egg-1', status: EggStatus.laid),
        _buildEgg(id: 'egg-2', status: EggStatus.hatched),
      ];

      // Wrap in a SizedBox to prevent Row overflow
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: EggSummaryRow(eggs: eggs),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppIcon), findsNWidgets(2));
    });
  });
}
