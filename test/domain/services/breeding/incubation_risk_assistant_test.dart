import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/breeding/incubation_risk_assistant.dart';

void main() {
  group('IncubationRiskAssistant', () {
    final now = DateTime(2026, 5, 17);

    test('flags active eggs that passed expected hatch range', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [
          _incubation(
            'inc-1',
            pairId: 'pair-1',
            species: Species.budgie,
            startDate: DateTime(2026, 4, 20),
          ),
        ],
        eggs: [
          _egg(
            'egg-1',
            incubationId: 'inc-1',
            layDate: DateTime(2026, 4, 20),
            eggNumber: 1,
          ),
        ],
        chicks: const [],
      );

      final overdueRisk = summary.risks.singleWhere(
        (risk) => risk.type == IncubationRiskType.overdueEgg,
      );
      expect(overdueRisk.severity, IncubationRiskSeverity.critical);
      expect(overdueRisk.eggId, 'egg-1');
    });

    test('handles short egg ids when building overdue labels', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [
          _incubation('inc-1', pairId: 'pair-1', species: Species.budgie),
        ],
        eggs: [
          _egg('e', incubationId: 'inc-1', layDate: DateTime(2026, 4, 20)),
        ],
        chicks: const [],
      );

      final overdueRisk = summary.risks.singleWhere(
        (risk) => risk.type == IncubationRiskType.overdueEgg,
      );
      expect(overdueRisk.titleArgs, ['e']);
    });

    test('ignores eggs that do not belong to a known pair incubation', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [
          _egg(
            'egg-1',
            incubationId: 'missing-incubation',
            layDate: DateTime(2026, 4, 20),
          ),
        ],
        chicks: const [],
      );

      expect(summary.risks, isEmpty);
    });

    test('flags two-egg seasons when all eggs are unsuccessful', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [
          _egg('egg-1', incubationId: 'inc-1', status: EggStatus.infertile),
          _egg('egg-2', incubationId: 'inc-1', status: EggStatus.damaged),
        ],
        chicks: const [],
      );

      final risk = summary.risks.singleWhere(
        (risk) => risk.type == IncubationRiskType.highUnsuccessfulEggRate,
      );
      expect(risk.severity, IncubationRiskSeverity.critical);
      expect(risk.descriptionArgs, ['100']);
    });

    test('flags single known unsuccessful egg without marking it critical', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [
          _egg('egg-1', incubationId: 'inc-1', status: EggStatus.infertile),
        ],
        chicks: const [],
      );

      final risk = summary.risks.singleWhere(
        (risk) => risk.type == IncubationRiskType.highUnsuccessfulEggRate,
      );
      expect(risk.severity, IncubationRiskSeverity.warning);
      expect(risk.descriptionArgs, ['100']);
    });

    test('does not duplicate single overdue active egg as rate risk', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [
          _egg('egg-1', incubationId: 'inc-1', layDate: DateTime(2026, 4, 20)),
        ],
        chicks: const [],
      );

      expect(
        summary.risks.map((risk) => risk.type),
        isNot(contains(IncubationRiskType.highUnsuccessfulEggRate)),
      );
    });

    test('ignores soft-deleted pairs, eggs, and chicks', () {
      final deletedPairSummary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1', isDeleted: true)],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [
          _egg('egg-1', incubationId: 'inc-1', status: EggStatus.damaged),
          _egg('egg-2', incubationId: 'inc-1', status: EggStatus.empty),
        ],
        chicks: const [],
      );
      expect(deletedPairSummary.risks, isEmpty);

      final deletedEggSummary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [
          _egg(
            'egg-1',
            incubationId: 'inc-1',
            status: EggStatus.damaged,
            isDeleted: true,
          ),
        ],
        chicks: const [],
      );
      expect(deletedEggSummary.risks, isEmpty);

      final deletedChickSummary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [_egg('egg-1', incubationId: 'inc-1', status: EggStatus.hatched)],
        chicks: [
          _chick(
            'chick-1',
            eggId: 'egg-1',
            health: ChickHealthStatus.deceased,
            isDeleted: true,
          ),
        ],
      );
      expect(
        deletedChickSummary.risks.map((risk) => risk.type),
        isNot(contains(IncubationRiskType.chickHealthLoss)),
      );
    });

    test('flags hatch-rate decline across the last two completed seasons', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [
          _incubation(
            'inc-latest',
            pairId: 'pair-1',
            status: IncubationStatus.completed,
            startDate: DateTime(2026, 4, 1),
          ),
          _incubation(
            'inc-previous',
            pairId: 'pair-1',
            status: IncubationStatus.completed,
            startDate: DateTime(2026, 2, 1),
          ),
        ],
        eggs: [
          _egg('p1', incubationId: 'inc-previous', status: EggStatus.hatched),
          _egg('p2', incubationId: 'inc-previous', status: EggStatus.hatched),
          _egg('p3', incubationId: 'inc-previous', status: EggStatus.hatched),
          _egg('p4', incubationId: 'inc-previous', status: EggStatus.empty),
          _egg('l1', incubationId: 'inc-latest', status: EggStatus.hatched),
          _egg('l2', incubationId: 'inc-latest', status: EggStatus.empty),
          _egg('l3', incubationId: 'inc-latest', status: EggStatus.empty),
          _egg('l4', incubationId: 'inc-latest', status: EggStatus.empty),
        ],
        chicks: const [],
      );

      expect(
        summary.risks.map((risk) => risk.type),
        contains(IncubationRiskType.hatchRateDecline),
      );
    });

    test('daysLate uses DateUtils.dayDiff so near-midnight hatch is overdue', () {
      // expected hatch at 23:59 on May 16; now is 00:01 on May 17.
      // Naive .difference().inDays returns 0 (only 2 min elapsed).
      // DateUtils.dayDiff returns 1 — egg is 1 calendar day overdue.
      final nearMidnightNow = DateTime(2026, 5, 17, 0, 1);
      final layDate = DateTime(2026, 4, 28, 23, 59); // +18d = May 16 23:59
      final summary = const IncubationRiskAssistant().assess(
        now: nearMidnightNow,
        pairs: [_pair('pair-1')],
        incubations: [
          _incubation(
            'inc-1',
            pairId: 'pair-1',
            species: Species.budgie,
            startDate: layDate,
          ),
        ],
        eggs: [_egg('egg-1', incubationId: 'inc-1', layDate: layDate)],
        chicks: const [],
      );

      expect(
        summary.risks.map((r) => r.type),
        contains(IncubationRiskType.overdueEgg),
      );
    });

    test('flags chick health loss for the incubation', () {
      final summary = const IncubationRiskAssistant().assess(
        now: now,
        pairs: [_pair('pair-1')],
        incubations: [_incubation('inc-1', pairId: 'pair-1')],
        eggs: [
          _egg('egg-1', incubationId: 'inc-1', status: EggStatus.hatched),
          _egg('egg-2', incubationId: 'inc-1', status: EggStatus.hatched),
        ],
        chicks: [
          _chick('chick-1', eggId: 'egg-1', health: ChickHealthStatus.healthy),
          _chick('chick-2', eggId: 'egg-2', health: ChickHealthStatus.deceased),
        ],
      );

      expect(
        summary.risks.map((risk) => risk.type),
        contains(IncubationRiskType.chickHealthLoss),
      );
    });
  });
}

BreedingPair _pair(String id, {bool isDeleted = false}) =>
    BreedingPair(id: id, userId: 'user-1', isDeleted: isDeleted);

Incubation _incubation(
  String id, {
  String? pairId,
  Species species = Species.budgie,
  IncubationStatus status = IncubationStatus.active,
  DateTime? startDate,
}) {
  return Incubation(
    id: id,
    userId: 'user-1',
    breedingPairId: pairId,
    species: species,
    status: status,
    startDate: startDate,
  );
}

Egg _egg(
  String id, {
  String? incubationId,
  EggStatus status = EggStatus.laid,
  DateTime? layDate,
  int? eggNumber,
  bool isDeleted = false,
}) {
  return Egg(
    id: id,
    userId: 'user-1',
    incubationId: incubationId,
    status: status,
    layDate: layDate ?? DateTime(2026, 4, 1),
    eggNumber: eggNumber,
    isDeleted: isDeleted,
  );
}

Chick _chick(
  String id, {
  required String eggId,
  required ChickHealthStatus health,
  bool isDeleted = false,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    eggId: eggId,
    healthStatus: health,
    isDeleted: isDeleted,
  );
}
