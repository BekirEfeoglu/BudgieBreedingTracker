import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/ai_predictions_screen.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_welcome_screen.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

// ── Fake notifier to bypass FlutterSecureStorage ──

class _FakeConfig extends LocalAiConfigNotifier {
  _FakeConfig(this._initial);
  final AsyncValue<LocalAiConfig> _initial;

  @override
  Future<LocalAiConfig> build() async => _initial.requireValue;
}

// ── Test config values ──

const _configuredConfig = LocalAiConfig(
  provider: LocalAiProvider.openRouter,
  baseUrl: 'https://openrouter.ai',
  model: 'google/gemma-4-26b-a4b-it:free',
  apiKey: 'test-key',
);

const _unconfiguredConfig = LocalAiConfig(
  provider: LocalAiProvider.ollama,
  baseUrl: 'http://127.0.0.1:11434',
  model: '',
);

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

    Widget buildSubject({
      int initialTab = 0,
      String? birdId,
      LocalAiConfig config = _configuredConfig,
    }) {
      final container = ProviderContainer(
        overrides: [
          localAiConfigProvider.overrideWith(
            () => _FakeConfig(AsyncData(config)),
          ),
        ],
      );
      addTearDown(container.dispose);

      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig:
              buildRouter(initialTab: initialTab, birdId: birdId),
        ),
      );
    }

    group('with configured AI', () {
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
      testWidgets('shows welcome screen when no config', (tester) async {
        await tester.pumpWidget(
          buildSubject(config: _unconfiguredConfig),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AiWelcomeScreen), findsOneWidget);
        expect(find.byType(TabBar), findsNothing);
      });
    });
  });
}
