import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/progress_bar.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_progress.dart';

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

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('BreedingCardProgress', () {
    testWidgets('renders without error', (tester) async {
      final incubation = _buildIncubation(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 5),
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      expect(find.byType(BreedingCardProgress), findsOneWidget);
    });

    testWidgets('shows progress bar', (tester) async {
      final incubation = _buildIncubation(
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 5),
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      expect(find.byType(AppProgressBar), findsOneWidget);
    });

    testWidgets('progress bar has correct value for active incubation',
        (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.active,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 10),
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      expect(progressBar.value, incubation.percentageComplete);
    });

    testWidgets('shows correct stage label for active incubation',
        (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.active,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );
      final expectedLabel = IncubationCalculator.getStageLabel(
        incubation.daysElapsed,
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      expect(find.text(expectedLabel), findsOneWidget);
    });

    testWidgets('stage label has correct color for active incubation',
        (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.active,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );
      final expectedColor = IncubationCalculator.getStageColor(
        incubation.daysElapsed,
      );
      final expectedLabel = IncubationCalculator.getStageLabel(
        incubation.daysElapsed,
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      final stageLabelText = tester.widget<Text>(find.text(expectedLabel));
      expect(stageLabelText.style?.color, expectedColor);
    });

    testWidgets('progress bar color matches stage color', (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.active,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );
      final expectedColor = IncubationCalculator.getStageColor(
        incubation.daysElapsed,
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      expect(progressBar.color, expectedColor);
    });

    testWidgets('displays day count information', (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.active,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 9),
      );
      final dayProgressText = 'breeding.day_progress'.tr(
        args: [
          incubation.daysElapsed.toString(),
          IncubationConstants.incubationPeriodDays.toString(),
        ],
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      expect(find.text(dayProgressText), findsOneWidget);
    });

    testWidgets('shows completed label for completed incubation',
        (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.completed,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 24),
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      expect(find.text('breeding.completed'.tr()), findsOneWidget);
    });

    testWidgets('uses completed stage color for completed incubation',
        (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.completed,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 24),
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      expect(progressBar.color, AppColors.stageCompleted);
    });

    testWidgets('completed incubation shows clamped progress value at 1.0',
        (tester) async {
      final incubation = _buildIncubation(
        status: IncubationStatus.completed,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 2, 24),
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      // 23 days elapsed > 18 day period, clamped to 1.0
      expect(progressBar.value, 1.0);
    });

    testWidgets('shows zero progress when start date is null', (tester) async {
      final incubation = _buildIncubation(
        startDate: null,
      );

      await _pump(tester, BreedingCardProgress(incubation: incubation));

      final progressBar = tester.widget<AppProgressBar>(
        find.byType(AppProgressBar),
      );
      expect(progressBar.value, 0.0);
    });
  });
}
