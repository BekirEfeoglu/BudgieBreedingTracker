import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/screens/egg_management_screen.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_list_item.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';

void main() {
  final testIncubation = Incubation(
    id: 'inc-1',
    userId: 'test-user',
    status: IncubationStatus.active,
    breedingPairId: 'pair-1',
    startDate: DateTime(2024, 1, 1),
    expectedHatchDate: DateTime(2024, 1, 19),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/breeding/pair-1/eggs',
      routes: [
        GoRoute(
          path: '/breeding/:id/eggs',
          builder: (_, state) =>
              EggManagementScreen(pairId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/chicks',
          builder: (_, __) => const Scaffold(body: Text('Chicks')),
        ),
      ],
    );
  });

  /// Suppresses overflow exceptions that occur when .tr() returns key strings.
  void suppressOverflowErrors(WidgetTester tester) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final isOverflow = details.exceptionAsString().contains('overflowed');
      if (!isOverflow) {
        originalOnError?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = originalOnError);
  }

  group('EggManagementScreen - Empty State', () {
    testWidgets('shows EmptyState when no eggs exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(l10n('eggs.no_eggs')), findsOneWidget);
    });

    testWidgets('empty state shows hint text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n('eggs.no_eggs_hint')), findsOneWidget);
    });

    testWidgets('empty state shows add egg action label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n('eggs.add_egg')), findsAtLeastNWidgets(1));
    });
  });

  group('EggManagementScreen - Loading & Error', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => const Stream<List<Incubation>>.empty()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows ErrorState when incubation loading fails', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider('pair-1').overrideWith(
              (_) => Stream<List<Incubation>>.error('Load failed'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows incubation_not_found when no incubation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value(<Incubation>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text(l10n('eggs.incubation_not_found')), findsOneWidget);
    });

    testWidgets('shows management title in AppBar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n('eggs.management')), findsOneWidget);
    });
  });

  group('EggManagementScreen - Data Display', () {
    testWidgets('shows egg list with multiple eggs', (tester) async {
      suppressOverflowErrors(tester);

      final testEggs = [
        Egg(
          id: 'egg-1',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 1),
          eggNumber: 1,
          status: EggStatus.incubating,
        ),
        Egg(
          id: 'egg-2',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 3),
          eggNumber: 2,
          status: EggStatus.fertile,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(testEggs)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(EggSummaryRow), findsOneWidget);
      expect(find.byType(EggListItem), findsNWidgets(2));
    });

    testWidgets('shows hatched eggs in list display', (tester) async {
      suppressOverflowErrors(tester);

      final testEggs = [
        Egg(
          id: 'egg-1',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 1),
          eggNumber: 1,
          status: EggStatus.incubating,
        ),
        Egg(
          id: 'egg-2',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 3),
          eggNumber: 2,
          status: EggStatus.hatched,
          hatchDate: DateTime(2024, 1, 19),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(testEggs)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(EggListItem), findsNWidgets(2));
      expect(find.byType(EggSummaryRow), findsOneWidget);
    });

    testWidgets('shows hatched egg rows when only hatched eggs exist', (
      tester,
    ) async {
      final hatchedEggs = [
        Egg(
          id: 'egg-h1',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 1),
          eggNumber: 1,
          status: EggStatus.hatched,
          hatchDate: DateTime(2024, 1, 19),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(hatchedEggs)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n('eggs.all_hatched')), findsNothing);
      expect(find.byType(EggListItem), findsOneWidget);
    });

    testWidgets('hides FAB in empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('shows mixed status eggs correctly', (tester) async {
      suppressOverflowErrors(tester);

      final testEggs = [
        Egg(
          id: 'egg-1',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 1),
          eggNumber: 1,
          status: EggStatus.incubating,
        ),
        Egg(
          id: 'egg-2',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 3),
          eggNumber: 2,
          status: EggStatus.infertile,
        ),
        Egg(
          id: 'egg-3',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 5),
          eggNumber: 3,
          status: EggStatus.damaged,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(testEggs)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // All eggs should be shown.
      expect(find.byType(EggListItem), findsNWidgets(3));
    });
  });

  group('EggManagementScreen - FAB & Add Egg Sheet', () {
    testWidgets('FAB has add_egg tooltip', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider('inc-1').overrideWith(
              (_) => Stream.value([
                Egg(
                  id: 'egg-1',
                  userId: 'test-user',
                  incubationId: 'inc-1',
                  layDate: DateTime(2024, 1, 1),
                  eggNumber: 1,
                ),
              ]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, 'eggs.add_egg');
    });

    testWidgets('tapping FAB opens add egg bottom sheet', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider('inc-1').overrideWith(
              (_) => Stream.value([
                Egg(
                  id: 'egg-1',
                  userId: 'test-user',
                  incubationId: 'inc-1',
                  layDate: DateTime(2024, 1, 1),
                  eggNumber: 1,
                ),
              ]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet should appear with add_new_egg title
      expect(find.text(l10n('eggs.add_new_egg')), findsOneWidget);
    });

    testWidgets('add egg sheet shows egg number field', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('eggs.add_egg')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n('eggs.egg_number')), findsOneWidget);
    });

    testWidgets('add egg sheet shows notes field', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('eggs.add_egg')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n('common.notes_optional')), findsOneWidget);
    });

    testWidgets('add egg sheet shows add button', (tester) async {
      suppressOverflowErrors(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider(
              'pair-1',
            ).overrideWith((_) => Stream.value([testIncubation])),
            eggsForIncubationProvider(
              'inc-1',
            ).overrideWith((_) => Stream.value(<Egg>[])),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('eggs.add_egg')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n('common.add')), findsOneWidget);
    });
  });
}
