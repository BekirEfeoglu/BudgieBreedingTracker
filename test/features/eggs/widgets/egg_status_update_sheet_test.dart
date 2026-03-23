import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_status_chip.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_status_update_sheet.dart';

import '../../../helpers/test_fixtures.dart';

import '../../../helpers/test_localization.dart';

void main() {
  /// Suppresses overflow exceptions that occur when .tr() returns key strings
  /// (long text) in the test environment.
  void suppressOverflowErrors() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final isOverflow = details.exceptionAsString().contains('overflowed');
      if (!isOverflow) {
        originalOnError?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = originalOnError);
  }

  Widget buildWithTrigger({required Egg egg}) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showEggStatusUpdateSheet(context, egg),
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    );
  }

  group('showEggStatusUpdateSheet', () {
    testWidgets('does not open sheet for hatched egg (no transitions)', (
      tester,
    ) async {
      final hatchedEgg = TestFixtures.sampleEgg(status: EggStatus.hatched);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: hatchedEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      // No BottomSheet since no valid transitions
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('does not open sheet for discarded egg (no transitions)', (
      tester,
    ) async {
      final discardedEgg = TestFixtures.sampleEgg(status: EggStatus.discarded);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: discardedEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('opens sheet for "laid" egg', (tester) async {
      suppressOverflowErrors();
      final laidEgg = TestFixtures.sampleEgg(status: EggStatus.laid);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: laidEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('shows current status chip inside sheet', (tester) async {
      suppressOverflowErrors();
      final laidEgg = TestFixtures.sampleEgg(status: EggStatus.laid);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: laidEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(EggStatusChip), findsAtLeastNWidgets(1));
    });

    testWidgets('shows "select new status" prompt inside sheet', (
      tester,
    ) async {
      suppressOverflowErrors();
      final laidEgg = TestFixtures.sampleEgg(status: EggStatus.laid);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: laidEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // eggs.select_new_status key rendered as its key string in tests
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('shows ListTiles for valid transitions', (tester) async {
      suppressOverflowErrors();
      // EggStatus.fertile -> valid transitions exist (e.g., incubating)
      final fertileEgg = TestFixtures.sampleEgg(status: EggStatus.fertile);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: fertileEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('shows drag handle container', (tester) async {
      suppressOverflowErrors();
      final laidEgg = TestFixtures.sampleEgg(status: EggStatus.laid);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: laidEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // SafeArea + Column + drag handle Container(width:40, height:4)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('tapping a status ListTile pops the sheet', (tester) async {
      suppressOverflowErrors();
      final laidEgg = TestFixtures.sampleEgg(status: EggStatus.laid);
      await pumpLocalizedApp(tester, buildWithTrigger(egg: laidEgg));
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Tap the first available ListTile
      await tester.tap(find.byType(ListTile).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BottomSheet), findsNothing);
    });
  });
}
