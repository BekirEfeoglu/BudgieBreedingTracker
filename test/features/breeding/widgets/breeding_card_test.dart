import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_footer.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_header.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_progress.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

BreedingPair _buildPair({
  String id = 'pair-1',
  String userId = 'user-1',
  String? maleId,
  String? femaleId,
  String? cageNumber,
  DateTime? pairingDate,
  BreedingStatus status = BreedingStatus.active,
}) {
  return BreedingPair(
    id: id,
    userId: userId,
    maleId: maleId,
    femaleId: femaleId,
    cageNumber: cageNumber,
    pairingDate: pairingDate,
    status: status,
  );
}

Incubation _buildIncubation({
  String id = 'incubation-1',
  IncubationStatus status = IncubationStatus.active,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Incubation(
    id: id,
    userId: 'user-1',
    status: status,
    breedingPairId: 'pair-1',
    startDate: startDate,
    endDate: endDate,
  );
}

Egg _buildEgg({String id = 'egg-1', EggStatus status = EggStatus.laid}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2026, 2, 1),
    status: status,
  );
}

void main() {
  group('BreedingCard', () {
    testWidgets('renders without crashing', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      expect(find.byType(BreedingCard), findsOneWidget);
    });

    testWidgets('shows BreedingCardHeader', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      expect(find.byType(BreedingCardHeader), findsOneWidget);
    });

    testWidgets('shows BreedingCardFooter', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      expect(find.byType(BreedingCardFooter), findsOneWidget);
    });

    testWidgets('shows BreedingCardProgress when incubation is present', (
      tester,
    ) async {
      final pair = _buildPair();
      final incubation = _buildIncubation(startDate: DateTime(2026, 2, 1));

      await _pump(tester, BreedingCard(pair: pair, incubation: incubation));

      expect(find.byType(BreedingCardProgress), findsOneWidget);
    });

    testWidgets('does not show BreedingCardProgress when no incubation', (
      tester,
    ) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      expect(find.byType(BreedingCardProgress), findsNothing);
    });

    testWidgets('shows EggSummaryRow when eggs are present', (tester) async {
      final pair = _buildPair();
      final eggs = [
        _buildEgg(id: 'egg-1', status: EggStatus.laid),
        _buildEgg(id: 'egg-2', status: EggStatus.hatched),
      ];

      await _pump(tester, BreedingCard(pair: pair, eggs: eggs));

      expect(find.byType(EggSummaryRow), findsOneWidget);
    });

    testWidgets('does not show EggSummaryRow when no eggs', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      expect(find.byType(EggSummaryRow), findsNothing);
    });

    testWidgets('shows all sections when incubation and eggs present', (
      tester,
    ) async {
      final pair = _buildPair();
      final incubation = _buildIncubation(startDate: DateTime(2026, 2, 1));
      final eggs = [_buildEgg()];

      await _pump(
        tester,
        BreedingCard(pair: pair, incubation: incubation, eggs: eggs),
      );

      expect(find.byType(BreedingCardHeader), findsOneWidget);
      expect(find.byType(BreedingCardProgress), findsOneWidget);
      expect(find.byType(EggSummaryRow), findsOneWidget);
      expect(find.byType(BreedingCardFooter), findsOneWidget);
    });

    testWidgets('wraps content in a Card widget', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('card has antiAlias clip behavior', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.clipBehavior, Clip.antiAlias);
    });

    testWidgets('has InkWell for tap interaction', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('calls custom onTap callback when provided', (tester) async {
      final pair = _buildPair();
      var tapped = false;

      await _pump(tester, BreedingCard(pair: pair, onTap: () => tapped = true));

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('exposes parent names as an actionable semantic button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final pair = _buildPair(maleId: 'male-1', femaleId: 'female-1');
        final birdsMap = <String, Bird>{
          'male-1': const Bird(
            id: 'male-1',
            userId: 'user-1',
            name: 'Mavi',
            gender: BirdGender.male,
          ),
          'female-1': const Bird(
            id: 'female-1',
            userId: 'user-1',
            name: 'Limon',
            gender: BirdGender.female,
          ),
        };

        await _pump(
          tester,
          BreedingCard(pair: pair, birdsMap: birdsMap, onTap: () {}),
        );

        final semanticFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.onTap != null,
        );
        final node = tester.getSemantics(semanticFinder.first);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.label, contains('Mavi'));
        expect(node.label, contains('Limon'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('has left border decoration for stage color', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCard(pair: pair));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(
        border.left,
        BorderSide(color: IncubationCalculator.getStageColor(0), width: 4),
      );
    });

    testWidgets('shows completed stage color when incubation is complete', (
      tester,
    ) async {
      final pair = _buildPair();
      final incubation = _buildIncubation(
        status: IncubationStatus.completed,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 19),
      );

      await _pump(tester, BreedingCard(pair: pair, incubation: incubation));

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(
        border.left,
        BorderSide(
          color: IncubationCalculator.getCompletedStageColor(),
          width: 4,
        ),
      );
    });
  });
}
