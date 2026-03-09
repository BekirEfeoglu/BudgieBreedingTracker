import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/progress_bar.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_eggs.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_footer.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_header.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_progress.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _pumpBreedingWidget(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const <dynamic>[],
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
  String? maleId = 'male-1',
  String? femaleId = 'female-1',
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

Egg _buildEgg({String id = 'egg-1', EggStatus status = EggStatus.laid}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2026, 2, 1),
    status: status,
  );
}

void main() {
  group('BreedingCardHeader', () {
    testWidgets('shows fallback names when pair birds are not selected', (
      tester,
    ) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pumpBreedingWidget(tester, BreedingCardHeader(pair: pair));

      expect(find.text('breeding.male_not_selected'), findsOneWidget);
      expect(find.text('breeding.female_not_selected'), findsOneWidget);
    });

    testWidgets('shows bird names from providers when available', (
      tester,
    ) async {
      final pair = _buildPair(maleId: 'male-1', femaleId: 'female-1');
      final birdsById = <String, Bird>{
        'male-1': createTestBird(
          id: 'male-1',
          name: 'Mavi',
          gender: BirdGender.male,
        ),
        'female-1': createTestBird(
          id: 'female-1',
          name: 'Sari',
          gender: BirdGender.female,
        ),
      };

      await _pumpBreedingWidget(
        tester,
        BreedingCardHeader(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith(
            (ref, birdId) => Stream.value(birdsById[birdId]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Mavi'), findsOneWidget);
      expect(find.text('Sari'), findsOneWidget);
    });

    testWidgets('shows cage number and status badge mapping', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        cageNumber: 'C-8',
        status: BreedingStatus.completed,
      );

      await _pumpBreedingWidget(tester, BreedingCardHeader(pair: pair));

      expect(find.text('breeding.cage_label: C-8'), findsOneWidget);

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.label, 'breeding.completed'.tr());
      expect(badge.color, AppColors.success);
    });
  });

  group('BreedingCardFooter', () {
    testWidgets('shows pairing and expected hatch dates with icons', (
      tester,
    ) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: DateTime(2026, 2, 10),
      );
      final incubation = _buildIncubation(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );

      await _pumpBreedingWidget(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      expect(find.text('10.02.2026'), findsOneWidget);
      expect(find.text('19.02.2026'), findsOneWidget);
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
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.style?.fontWeight == FontWeight.w600,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show remaining-days text for inactive incubation', (
      tester,
    ) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        pairingDate: DateTime(2026, 2, 10),
      );
      final incubation = _buildIncubation(
        status: IncubationStatus.completed,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 24),
      );

      await _pumpBreedingWidget(
        tester,
        BreedingCardFooter(pair: pair, incubation: incubation),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.style?.fontWeight == FontWeight.w600,
        ),
        findsNothing,
      );
    });
  });

  group('BreedingCardEggs', () {
    testWidgets('delegates eggs list to EggSummaryRow', (tester) async {
      final eggs = [
        _buildEgg(id: 'egg-1', status: EggStatus.laid),
        _buildEgg(id: 'egg-2', status: EggStatus.hatched),
      ];

      await _pumpBreedingWidget(tester, BreedingCardEggs(eggs: eggs));

      final summaryRow = tester.widget<EggSummaryRow>(
        find.byType(EggSummaryRow),
      );
      expect(summaryRow.eggs, eggs);
      expect(find.byType(AppIcon), findsNWidgets(2));
    });
  });

  group('BreedingCardProgress', () {
    testWidgets('shows active stage label and progress bar values', (
      tester,
    ) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.active,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );

      await _pumpBreedingWidget(
        tester,
        BreedingCardProgress(incubation: incubation),
      );

      final expectedStageLabel = IncubationCalculator.getStageLabel(
        incubation.daysElapsed,
      );
      final expectedStageColor = IncubationCalculator.getStageColor(
        incubation.daysElapsed,
      );

      expect(find.text(expectedStageLabel), findsOneWidget);

      final stageLabelText = tester.widget<Text>(find.text(expectedStageLabel));
      expect(stageLabelText.style?.color, expectedStageColor);

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      expect(progressBar.value, incubation.percentageComplete);
      expect(progressBar.color, expectedStageColor);
    });

    testWidgets('shows completed stage label and completed color', (
      tester,
    ) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.completed,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 24),
      );

      await _pumpBreedingWidget(
        tester,
        BreedingCardProgress(incubation: incubation),
      );

      expect(find.text('breeding.completed'.tr()), findsOneWidget);

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      expect(progressBar.value, 1.0);
      expect(progressBar.color, AppColors.stageCompleted);
    });
  });
}
