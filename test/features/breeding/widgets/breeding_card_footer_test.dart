import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_footer.dart';

BreedingPair _buildPair({
  String id = 'pair-1',
  String userId = 'user-1',
  String? maleId = 'male-1',
  String? femaleId = 'female-1',
  DateTime? pairingDate,
  BreedingStatus status = BreedingStatus.active,
}) {
  return BreedingPair(
    id: id,
    userId: userId,
    maleId: maleId,
    femaleId: femaleId,
    pairingDate: pairingDate,
    status: status,
  );
}

Incubation _buildIncubation({
  String id = 'incubation-1',
  String userId = 'user-1',
  IncubationStatus status = IncubationStatus.active,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Incubation(
    id: id,
    userId: userId,
    status: status,
    breedingPairId: 'pair-1',
    startDate: startDate,
    endDate: endDate,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('BreedingCardFooter', () {
    testWidgets('renders without error', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardFooter(pair: pair));

      expect(find.byType(BreedingCardFooter), findsOneWidget);
    });

    testWidgets('shows pairing date when available', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: DateTime(2026, 3, 15),
      );

      await _pump(tester, BreedingCardFooter(pair: pair));

      expect(find.text('15.03.2026'), findsOneWidget);
    });

    testWidgets('shows calendar icon when pairing date is set', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: DateTime(2026, 3, 15),
      );

      await _pump(tester, BreedingCardFooter(pair: pair));

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.calendar,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show pairing date when null', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: null,
      );

      await _pump(tester, BreedingCardFooter(pair: pair));

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.calendar,
        ),
        findsNothing,
      );
    });

    testWidgets('shows expected hatch date when incubation has start date',
        (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: DateTime(2026, 2, 10),
      );
      final incubation = _buildIncubation(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );

      await _pump(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      // Expected hatch date = startDate + 18 days = 2026-02-19
      expect(find.text('19.02.2026'), findsOneWidget);
    });

    testWidgets('shows egg icon when expected hatch date is available',
        (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);
      final incubation = _buildIncubation(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );

      await _pump(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.egg,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show egg icon when incubation has no start date',
        (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);
      final incubation = _buildIncubation(startDate: null);

      await _pump(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.egg,
        ),
        findsNothing,
      );
    });

    testWidgets('shows remaining days text for active incubation',
        (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);
      final incubation = _buildIncubation(
        status: IncubationStatus.active,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );

      await _pump(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      // Active incubation should show a bold text for remaining days
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.style?.fontWeight == FontWeight.w600,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show remaining days text for completed incubation',
        (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);
      final incubation = _buildIncubation(
        status: IncubationStatus.completed,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 24),
      );

      await _pump(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      // Completed incubation should NOT show remaining days (bold text)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.style?.fontWeight == FontWeight.w600,
        ),
        findsNothing,
      );
    });

    testWidgets('does not show remaining days when incubation is null',
        (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: DateTime(2026, 3, 1),
      );

      await _pump(tester, BreedingCardFooter(pair: pair));

      // Without incubation, no bold remaining-days text
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.style?.fontWeight == FontWeight.w600,
        ),
        findsNothing,
      );
    });

    testWidgets('shows both pairing date and expected hatch date together',
        (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: DateTime(2026, 3, 10),
      );
      final incubation = _buildIncubation(
        startDate: DateTime(2026, 3, 5),
      );

      await _pump(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      // Pairing date
      expect(find.text('10.03.2026'), findsOneWidget);
      // Expected hatch date = 2026-03-05 + 18 days = 2026-03-23
      expect(find.text('23.03.2026'), findsOneWidget);
      // Both icons present
      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.calendar,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppIcon && widget.asset == AppIcons.egg,
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles all null date fields gracefully', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: null,
      );

      await _pump(tester, BreedingCardFooter(pair: pair));

      // No icons and no date text rendered — only a Spacer in the Row
      expect(
        find.byWidgetPredicate((widget) => widget is AppIcon),
        findsNothing,
      );
    });
  });
}
