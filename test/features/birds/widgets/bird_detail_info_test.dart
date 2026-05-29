import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_info.dart';

import '../../../helpers/pump_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// BirdDetailInfo formats dates via [dateFormatProvider], whose default is
/// AppDateFormat.dmy → 'dd.MM.yyyy'. The tests wrap the widget in a bare
/// ProviderScope, so that default format applies.
String _expectedDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BirdDetailInfo', () {
    testWidgets('shows gender InfoCard', (tester) async {
      final bird = createTestBird(gender: BirdGender.male);

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      // gender card shows male label key
      expect(find.text(l10n('birds.male')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows female gender label for female bird', (tester) async {
      final bird = createTestBird(gender: BirdGender.female);

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(l10n('birds.female')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows unknown gender label for unknown bird', (tester) async {
      final bird = createTestBird(gender: BirdGender.unknown);

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(l10n('birds.unknown')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows birth date when set', (tester) async {
      final bird = createTestBird(birthDate: DateTime(2024, 3, 15));

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(_expectedDate(DateTime(2024, 3, 15))), findsOneWidget);
    });

    testWidgets('shows unknown when no birth date', (tester) async {
      final bird = createTestBird(birthDate: null);

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(l10n('birds.unknown')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows cage number when set', (tester) async {
      final bird = createTestBird(cageNumber: 'Kafes-5');

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text('Kafes-5'), findsOneWidget);
    });

    testWidgets('shows ring number card when set', (tester) async {
      final bird = createTestBird(ringNumber: 'TR-2026-042');

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text('TR-2026-042'), findsOneWidget);
      expect(find.text(l10n('birds.ring_number')), findsOneWidget);
    });

    testWidgets('keeps ring and cage cards on the same row when both exist', (
      tester,
    ) async {
      final bird = createTestBird(
        ringNumber: 'TR-2026-042',
        cageNumber: 'Kafes-5',
      );

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      final ringCard = find.ancestor(
        of: find.text('TR-2026-042'),
        matching: find.byType(InfoCard),
      );
      final cageCard = find.ancestor(
        of: find.text('Kafes-5'),
        matching: find.byType(InfoCard),
      );

      expect(tester.getTopLeft(ringCard).dy, tester.getTopLeft(cageCard).dy);
    });

    testWidgets('does not show ring number card when null', (tester) async {
      final bird = createTestBird(ringNumber: null);

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(l10n('birds.ring_number')), findsNothing);
    });

    testWidgets('does not show cage number card when null', (tester) async {
      final bird = createTestBird(cageNumber: null);

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(l10n('birds.cage_number')), findsNothing);
    });

    testWidgets('shows death date card for dead bird with deathDate', (
      tester,
    ) async {
      final bird = createTestBird(
        status: BirdStatus.dead,
        deathDate: DateTime(2025, 6, 1),
      );

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(_expectedDate(DateTime(2025, 6, 1))), findsOneWidget);
    });

    testWidgets('does not show death date card for alive bird', (tester) async {
      final bird = createTestBird(status: BirdStatus.alive);

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(l10n('birds.death_date')), findsNothing);
    });

    testWidgets('shows sold date card for sold bird with soldDate', (
      tester,
    ) async {
      final bird = createTestBird(
        status: BirdStatus.sold,
        soldDate: DateTime(2025, 8, 20),
      );

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(_expectedDate(DateTime(2025, 8, 20))), findsOneWidget);
    });

    testWidgets('contains at least two InfoCards (gender and species)', (
      tester,
    ) async {
      final bird = createTestBird();

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.byType(InfoCard), findsAtLeastNWidgets(2));
    });

    testWidgets('shows common info section title', (tester) async {
      final bird = createTestBird();

      await pumpWidgetSimple(
        tester,
        ProviderScope(
          child: SingleChildScrollView(child: BirdDetailInfo(bird: bird)),
        ),
      );

      expect(find.text(l10n('common.info')), findsOneWidget);
    });
  });
}
