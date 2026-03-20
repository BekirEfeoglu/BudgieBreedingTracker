import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_detail_info.dart';

/// Pumps ChickDetailInfo inside a ProviderScope with the chickParentsProvider
/// overridden. By default returns null (no parent info).
Future<void> _pumpChickDetailInfo(
  WidgetTester tester,
  Chick chick, {
  ChickParentsInfo? parentsInfo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chickParentsProvider.overrideWith(
          (ref, eggId) => Future.value(parentsInfo),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ChickDetailInfo(chick: chick)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Chick _createTestChick({
  String id = 'chick-1',
  String userId = 'user-1',
  String? name,
  String? eggId,
  String? birdId,
  BirdGender gender = BirdGender.unknown,
  ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
  DateTime? hatchDate,
  double? hatchWeight,
  DateTime? weanDate,
  DateTime? deathDate,
}) {
  return Chick(
    id: id,
    userId: userId,
    name: name,
    eggId: eggId,
    birdId: birdId,
    gender: gender,
    healthStatus: healthStatus,
    hatchDate: hatchDate,
    hatchWeight: hatchWeight,
    weanDate: weanDate,
    deathDate: deathDate,
  );
}

void main() {
  group('ChickDetailInfo', () {
    testWidgets('renders without error', (tester) async {
      final chick = _createTestChick(name: 'Test');

      await _pumpChickDetailInfo(tester, chick);

      expect(find.byType(ChickDetailInfo), findsOneWidget);
    });

    testWidgets('shows info section title', (tester) async {
      final chick = _createTestChick(name: 'Test');

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.info'), findsOneWidget);
    });

    testWidgets('shows male gender label for male chick', (tester) async {
      final chick = _createTestChick(gender: BirdGender.male);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.male'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows female gender label for female chick', (tester) async {
      final chick = _createTestChick(gender: BirdGender.female);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.female'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows unknown gender label for unknown gender', (
      tester,
    ) async {
      final chick = _createTestChick(gender: BirdGender.unknown);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.unknown_gender'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows hatch date when available', (tester) async {
      final chick = _createTestChick(hatchDate: DateTime(2024, 3, 15));

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('15.03.2024'), findsOneWidget);
    });

    testWidgets('shows fallback when hatch date is null', (tester) async {
      final chick = _createTestChick(hatchDate: null);

      await _pumpChickDetailInfo(tester, chick);

      // The hatch date card shows 'chicks.unknown_gender' as fallback text
      // Gender card also shows it, so at least 2
      expect(find.text('chicks.unknown_gender'), findsAtLeastNWidgets(2));
    });

    testWidgets('shows weight information when available', (tester) async {
      final chick = _createTestChick(hatchWeight: 3.5);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('3.5 g'), findsOneWidget);
    });

    testWidgets('shows fallback when weight is null', (tester) async {
      final chick = _createTestChick(hatchWeight: null);

      await _pumpChickDetailInfo(tester, chick);

      // Weight card shows 'chicks.unknown_gender' as fallback
      expect(find.text('chicks.unknown_gender'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows birth weight subtitle', (tester) async {
      final chick = _createTestChick(hatchWeight: 2.8);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.birth_weight'), findsOneWidget);
    });

    testWidgets('handles null eggId gracefully (no parent info)', (
      tester,
    ) async {
      final chick = _createTestChick(eggId: null);

      await _pumpChickDetailInfo(tester, chick);

      // Should render without error; no parent cards shown
      expect(find.byType(ChickDetailInfo), findsOneWidget);
      expect(find.text('chicks.father'), findsNothing);
      expect(find.text('chicks.mother'), findsNothing);
    });

    testWidgets('shows parent cards when parents info is available', (
      tester,
    ) async {
      final chick = _createTestChick(eggId: 'egg-1');
      const parents = (
        maleName: 'Mavi',
        femaleName: 'Sarı',
        maleId: 'male-1',
        femaleId: 'female-1',
      );

      await _pumpChickDetailInfo(tester, chick, parentsInfo: parents);

      expect(find.text('Mavi'), findsOneWidget);
      expect(find.text('Sarı'), findsOneWidget);
      expect(find.text('chicks.father'), findsOneWidget);
      expect(find.text('chicks.mother'), findsOneWidget);
    });

    testWidgets('shows fallback name when parent name is null', (tester) async {
      final chick = _createTestChick(eggId: 'egg-1');
      const parents = (
        maleName: null,
        femaleName: null,
        maleId: 'male-1',
        femaleId: 'female-1',
      );

      await _pumpChickDetailInfo(tester, chick, parentsInfo: parents);

      // Both parent cards show the unknown_gender fallback text
      // Plus gender card and potentially hatch date card
      expect(find.text('chicks.unknown_gender'), findsAtLeastNWidgets(2));
    });

    testWidgets('shows weaning date when chick is weaned', (tester) async {
      final chick = _createTestChick(weanDate: DateTime(2024, 3, 1));

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('01.03.2024'), findsOneWidget);
      expect(find.text('chicks.weaning'), findsOneWidget);
    });

    testWidgets('shows not yet label when chick is not weaned', (tester) async {
      final chick = _createTestChick(weanDate: null);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.not_yet'), findsOneWidget);
    });

    testWidgets('shows death date when chick is deceased', (tester) async {
      final chick = _createTestChick(
        healthStatus: ChickHealthStatus.deceased,
        deathDate: DateTime(2024, 4, 10),
      );

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('10.04.2024'), findsOneWidget);
      expect(find.text('chicks.death_date'), findsOneWidget);
    });

    testWidgets('does not show death date for healthy chick', (tester) async {
      final chick = _createTestChick(healthStatus: ChickHealthStatus.healthy);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.death_date'), findsNothing);
    });

    testWidgets('shows bird record card when birdId is set', (tester) async {
      final chick = _createTestChick(birdId: 'bird-99');

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.converted_to_bird'), findsOneWidget);
      expect(find.text('chicks.bird_record'), findsOneWidget);
    });

    testWidgets('does not show bird record card when birdId is null', (
      tester,
    ) async {
      final chick = _createTestChick(birdId: null);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.converted_to_bird'), findsNothing);
    });

    testWidgets('contains multiple InfoCards', (tester) async {
      final chick = _createTestChick(name: 'Multi');

      await _pumpChickDetailInfo(tester, chick);

      // At minimum: gender, hatch date, weight, weaning = 4 InfoCards
      expect(find.byType(InfoCard), findsAtLeastNWidgets(4));
    });

    testWidgets('gender subtitle is shown', (tester) async {
      final chick = _createTestChick(gender: BirdGender.male);

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.gender'), findsOneWidget);
    });

    testWidgets('hatch date subtitle is shown', (tester) async {
      final chick = _createTestChick(hatchDate: DateTime(2024, 5, 20));

      await _pumpChickDetailInfo(tester, chick);

      expect(find.text('chicks.hatch_date'), findsOneWidget);
    });
  });

  group('ChickDetailNotes', () {
    testWidgets('renders notes text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChickDetailNotes(notes: 'A healthy chick.')),
        ),
      );

      expect(find.text('A healthy chick.'), findsOneWidget);
    });

    testWidgets('shows notes section title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChickDetailNotes(notes: 'Some notes')),
        ),
      );

      expect(find.text('common.notes'), findsOneWidget);
    });
  });
}
