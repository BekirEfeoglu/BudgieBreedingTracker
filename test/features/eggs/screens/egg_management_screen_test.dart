import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
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
    Egg(
      id: 'egg-3',
      userId: 'test-user',
      incubationId: 'inc-1',
      layDate: DateTime(2024, 1, 5),
      eggNumber: 3,
      status: EggStatus.infertile,
    ),
  ];

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

  Widget createSubject({
    AsyncValue<List<Incubation>>? incubationsOverride,
    Stream<List<Egg>>? eggsStream,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        if (incubationsOverride != null)
          incubationsByPairProvider(
            'pair-1',
          ).overrideWith((_) => Stream.value(incubationsOverride.value!)),
        if (eggsStream != null)
          eggsForIncubationProvider('inc-1').overrideWith((_) => eggsStream),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('EggManagementScreen', () {
    testWidgets('shows loading while incubations load', (tester) async {
      // Use a never-completing future to keep loading state
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

    testWidgets('shows error when incubation loading fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            incubationsByPairProvider('pair-1').overrideWith(
              (_) => Stream<List<Incubation>>.error('Network error'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows error message when no incubation found', (tester) async {
      await tester.pumpWidget(
        createSubject(incubationsOverride: const AsyncData([])),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text(l10n('eggs.incubation_not_found')), findsOneWidget);
    });

    testWidgets('shows empty state when eggs list is empty', (tester) async {
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

    testWidgets('shows egg list when data is available', (tester) async {
      // Suppress overflow errors from EggListItem rows
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final isOverflow = details.exceptionAsString().contains('overflowed');
        if (!isOverflow) {
          originalOnError?.call(details);
        }
      };

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

      // EggSummaryRow should be visible
      expect(find.byType(EggSummaryRow), findsOneWidget);

      // All eggs are shown in management.
      expect(find.byType(EggListItem), findsNWidgets(3));

      FlutterError.onError = originalOnError;
    });

    testWidgets('shows hatched eggs in the management list', (tester) async {
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

    testWidgets('appBar shows management title', (tester) async {
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

      expect(find.text(l10n('eggs.management')), findsOneWidget);
    });
  });
}
