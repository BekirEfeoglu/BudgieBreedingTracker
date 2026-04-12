import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/ai_predictions_screen.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_welcome_screen.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

void main() {
  group('AiPredictionsScreen', () {
    GoRouter buildRouter({int initialTab = 0, String? birdId}) {
      final queryParams = <String, String>{};
      if (initialTab == 1) queryParams['tab'] = 'sex';
      if (birdId != null) queryParams['birdId'] = birdId;

      final uri = Uri(
        path: AppRoutes.aiPredictions,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      return GoRouter(
        initialLocation: uri.toString(),
        routes: [
          GoRoute(
            path: AppRoutes.aiPredictions,
            builder: (_, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final tab = switch (tabParam) {
                'sex' => 1,
                _ => 0,
              };
              return AiPredictionsScreen(
                initialTab: tab,
                initialBirdId: state.uri.queryParameters['birdId'],
              );
            },
          ),
        ],
      );
    }

    Widget buildSubject({int initialTab = 0, String? birdId}) {
      return ProviderScope(
        child: MaterialApp.router(
          routerConfig: buildRouter(initialTab: initialTab, birdId: birdId),
        ),
      );
    }

    group('with configured AI', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({
          AppPreferences.keyLocalAiProvider: 'openRouter',
          AppPreferences.keyLocalAiBaseUrl: 'https://openrouter.ai',
          AppPreferences.keyLocalAiModel: 'google/gemma-4-26b-a4b-it:free',
          AppPreferences.keyLocalAiApiKey: 'test-key',
        });
      });

      testWidgets('renders tab bar with 2 tabs', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(TabBar), findsOneWidget);
        expect(find.text(l10n('genetics.ai_tab_mutation')), findsOneWidget);
        expect(find.text(l10n('genetics.ai_tab_sex')), findsOneWidget);
      });

      testWidgets('shows mutation tab by default', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(AiMutationTab), findsOneWidget);
      });

      testWidgets('shows sex tab when initialTab is 1', (tester) async {
        await tester.pumpWidget(buildSubject(initialTab: 1));
        await tester.pumpAndSettle();

        expect(find.byType(AiSexEstimationTab), findsOneWidget);
      });
    });

    group('without configured AI', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      testWidgets('shows welcome screen when no config', (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(AiWelcomeScreen), findsOneWidget);
        expect(find.byType(TabBar), findsNothing);
      });
    });
  });
}
