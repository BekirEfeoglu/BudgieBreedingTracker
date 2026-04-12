import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/ai_predictions_screen.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_card.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppPreferences.keyLocalAiProvider: 'openRouter',
      AppPreferences.keyLocalAiBaseUrl: 'https://openrouter.ai',
      AppPreferences.keyLocalAiModel: 'google/gemma-4-26b-a4b-it:free',
      AppPreferences.keyLocalAiApiKey: '',
    });
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: AppRoutes.aiPredictions,
      routes: [
        GoRoute(
          path: AppRoutes.aiPredictions,
          builder: (_, __) => const AiPredictionsScreen(),
        ),
        GoRoute(
          path: AppRoutes.genetics,
          builder: (_, __) => const Scaffold(body: Text('Genetics Route')),
        ),
      ],
    );
  }

  Widget buildSubject({ProviderContainer? container}) {
    final child = MaterialApp.router(routerConfig: buildRouter());
    if (container != null) {
      return UncontrolledProviderScope(container: container, child: child);
    }
    return ProviderScope(child: child);
  }

  group('AiPredictionsScreen', () {
    testWidgets('renders overview and all AI cards', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(AiPredictionsScreen), findsOneWidget);
      expect(find.text(l10n('more.ai_predictions')), findsWidgets);
      expect(
        find.text(l10n('genetics.local_ai_genetics_comment')),
        findsOneWidget,
      );
      expect(find.byType(AiMutationCard), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(l10n('genetics.run_sex_ai')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiSexEstimationCard), findsOneWidget);
    });

    testWidgets('shows genetics shortcut when pair is not ready', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.local_ai_pair_required')), findsWidgets);
      expect(
        find.widgetWithText(OutlinedButton, l10n('genetics.title')),
        findsOneWidget,
      );

      final runFinder = find.widgetWithText(
        FilledButton,
        l10n('genetics.run_genetics_ai'),
      );
      expect(tester.widget<FilledButton>(runFinder).onPressed, isNull);
    });

    testWidgets('navigates to genetics calculator from overview action', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n('genetics.title')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Genetics Route'), findsOneWidget);
    });

    testWidgets('uses current genetics selection to enable AI genetics action', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(fatherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.male,
        mutations: const {'blue': AlleleState.visual},
      );
      container.read(motherGenotypeProvider.notifier).state = ParentGenotype(
        gender: BirdGender.female,
        mutations: const {'ino': AlleleState.visual},
      );
      container.read(selectedFatherBirdNameProvider.notifier).state = 'Atlas';
      container.read(selectedMotherBirdNameProvider.notifier).state = 'Luna';

      await tester.pumpWidget(buildSubject(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Atlas x Luna'), findsWidgets);

      final runFinder = find.widgetWithText(
        FilledButton,
        l10n('genetics.run_genetics_ai'),
      );
      expect(tester.widget<FilledButton>(runFinder).onPressed, isNotNull);
    });
  });
}
