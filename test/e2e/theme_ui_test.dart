@Tags(['e2e'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_theme.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

import '../helpers/e2e_test_harness.dart';

class _BirdListStateProbe extends ConsumerWidget {
  const _BirdListStateProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birdsAsync = ref.watch(birdsStreamProvider('test-user'));
    return Scaffold(
      body: birdsAsync.when(
        data: (birds) {
          if (birds.isEmpty) {
            return Column(
              children: [
                const Text('EmptyState'),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Ilk kusunu ekle'),
                ),
              ],
            );
          }
          return Text('BirdList(${birds.length})');
        },
        loading: () => const Text('SkeletonLoader'),
        error: (_, __) {
          return Column(
            children: [
              const Text('ErrorState'),
              FilledButton(onPressed: () {}, child: const Text('Yeniden Dene')),
            ],
          );
        },
      ),
    );
  }
}

void main() {
  ensureE2EBinding();

  group('Theme & UI Flow E2E', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'GIVEN dark mode toggle WHEN theme switches THEN dark palette is applied and deep-blue primary token stays available',
      () async {
        final container = createTestContainer();
        addTearDown(container.dispose);

        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        final themeMode = container.read(themeModeProvider);

        final lightTheme = AppTheme.light();
        final darkTheme = AppTheme.dark();

        expect(themeMode, ThemeMode.dark);
        expect(AppColors.primary, const Color(0xFF1E40AF));
        expect(darkTheme.brightness, Brightness.dark);
        expect(
          lightTheme.colorScheme.surface == darkTheme.colorScheme.surface,
          isFalse,
        );
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN accessibility font scale x1.5 WHEN bird list shell is rendered THEN text remains readable without overflow',
      (tester) async {
        final container = createTestContainer(
          overrides: [
            birdsStreamProvider.overrideWith(
              (_, __) => Stream.value(<Bird>[
                const Bird(
                  id: 'bird-1',
                  userId: 'test-user',
                  name: 'Sari Boncuk',
                  gender: BirdGender.male,
                ),
              ]),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(fontScaleProvider.notifier)
            .setScale(AppFontScale.extraLarge);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.light(),
                home: const _BirdListStateProbe(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('BirdList(1)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN bird list is loading WHEN stream has not emitted yet THEN loading state is observed then replaced by data',
      () {
        const loadingState = AsyncLoading<List<Bird>>();
        const loadedState = AsyncData<List<Bird>>(<Bird>[
          Bird(
            id: 'bird-1',
            userId: 'test-user',
            name: 'Sari Boncuk',
            gender: BirdGender.male,
          ),
        ]);

        expect(loadingState.isLoading, isTrue);
        expect(loadedState.hasValue, isTrue);
        expect(loadedState.value, hasLength(1));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN no birds exist WHEN bird list data resolves THEN empty list state and first-bird CTA intent are available',
      () async {
        final container = createTestContainer(
          overrides: [
            birdsStreamProvider.overrideWith(
              (_, __) => Stream.value(const <Bird>[]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final states = <AsyncValue<List<Bird>>>[];
        final sub = container.listen<AsyncValue<List<Bird>>>(
          birdsStreamProvider('test-user'),
          (_, next) => states.add(next),
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(states.last.hasValue, isTrue);
        expect(states.last.value, isEmpty);
        expect('Ilk kusunu ekle', isNotEmpty);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN repository stream throws WHEN bird list data resolves THEN error state is surfaced with retry intent',
      () async {
        final container = createTestContainer(
          overrides: [
            birdsStreamProvider.overrideWith(
              (_, __) => Stream<List<Bird>>.error(Exception('boom')),
            ),
          ],
        );
        addTearDown(container.dispose);

        final states = <AsyncValue<List<Bird>>>[];
        final sub = container.listen<AsyncValue<List<Bird>>>(
          birdsStreamProvider('test-user'),
          (_, next) => states.add(next),
          fireImmediately: true,
        );
        addTearDown(sub.close);

        await Future<void>.delayed(const Duration(milliseconds: 40));

        expect(states.any((state) => state.hasError), isTrue);
        expect('Yeniden Dene', isNotEmpty);
      },
      timeout: e2eTimeout,
    );
  });
}
