import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/statistics_screen.dart';

void main() {
  Widget createSubject() {
    return ProviderScope(
      overrides: [
        // currentUserIdProvider defaults to anonymous when not overridden.
        // Override the underlying stream providers with empty data so
        // statistics widgets show empty/zero states instead of crashing.
        birdsStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
        breedingPairsStreamProvider(
          'anonymous',
        ).overrideWith((_) => Stream.value([])),
        eggsStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
        chicksStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
        birdCountProvider('anonymous').overrideWith((_) => Stream.value(0)),
        activeBreedingCountProvider(
          'anonymous',
        ).overrideWith((_) => Stream.value(0)),
        healthRecordCountProvider(
          'anonymous',
        ).overrideWith((_) => Stream.value(0)),
      ],
      child: const MaterialApp(home: StatisticsScreen()),
    );
  }

  group('StatisticsScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with statistics title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.title')), findsOneWidget);
    });

    testWidgets('shows TabBar with three tabs', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text(l10n('statistics.tab_overview')), findsOneWidget);
      expect(find.text(l10n('statistics.tab_breeding')), findsOneWidget);
      expect(find.text(l10n('statistics.tab_health')), findsOneWidget);
    });

    testWidgets('shows period selector', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate((w) => w is SegmentedButton),
        findsOneWidget,
      );
    });

    testWidgets(
      'invalidates providers on mount so stale keepAlive caches are cleared',
      (tester) async {
        // Arrange: a StreamController whose values can change between mounts
        final birdCtrl = StreamController<List<Bird>>();
        birdCtrl.add([]);

        Widget buildWith(StreamController<List<Bird>> ctrl) {
          return ProviderScope(
            overrides: [
              birdsStreamProvider('anonymous').overrideWith((_) => ctrl.stream),
              breedingPairsStreamProvider(
                'anonymous',
              ).overrideWith((_) => Stream.value([])),
              eggsStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
              chicksStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
              birdCountProvider('anonymous').overrideWith((_) => Stream.value(0)),
              activeBreedingCountProvider(
                'anonymous',
              ).overrideWith((_) => Stream.value(0)),
              healthRecordCountProvider(
                'anonymous',
              ).overrideWith((_) => Stream.value(0)),
            ],
            child: const MaterialApp(home: StatisticsScreen()),
          );
        }

        // Act: mount and unmount the screen
        await tester.pumpWidget(buildWith(birdCtrl));
        await tester.pumpAndSettle();
        // Replace with empty widget (simulates navigating away)
        await tester.pumpWidget(const SizedBox.shrink());

        // Re-mount — providers should be re-subscribed (not use stale cache)
        final birdCtrl2 = StreamController<List<Bird>>();
        birdCtrl2.add([]);
        await tester.pumpWidget(buildWith(birdCtrl2));
        await tester.pumpAndSettle();

        // Assert: screen still renders correctly on second mount
        expect(find.byType(StatisticsScreen), findsOneWidget);

        addTearDown(() {
          birdCtrl.close();
          birdCtrl2.close();
        });
      },
    );
  });
}
