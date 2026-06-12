import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart'
    as date_utils;
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

enum IncubationRiskSeverity { info, warning, critical }

enum IncubationRiskType {
  overdueEgg,
  staleTracking,
  hatchRateDecline,
  highUnsuccessfulEggRate,
  chickHealthLoss,
}

class IncubationRisk {
  const IncubationRisk({
    required this.type,
    required this.severity,
    required this.titleKey,
    required this.descriptionKey,
    this.titleArgs = const [],
    this.descriptionArgs = const [],
    this.pairId,
    this.incubationId,
    this.eggId,
  });

  final IncubationRiskType type;
  final IncubationRiskSeverity severity;
  final String titleKey;
  final String descriptionKey;
  final List<String> titleArgs;
  final List<String> descriptionArgs;
  final String? pairId;
  final String? incubationId;
  final String? eggId;
}

class IncubationRiskSummary {
  const IncubationRiskSummary(this.risks);

  final List<IncubationRisk> risks;

  bool get hasRisks => risks.isNotEmpty;

  int get warningCount => risks
      .where((risk) => risk.severity == IncubationRiskSeverity.warning)
      .length;

  int get criticalCount => risks
      .where((risk) => risk.severity == IncubationRiskSeverity.critical)
      .length;

  List<IncubationRisk> topRisks({int limit = 3}) {
    final sorted = List<IncubationRisk>.of(risks)
      ..sort((a, b) => _severityRank(b.severity) - _severityRank(a.severity));
    return sorted.take(limit).toList(growable: false);
  }

  List<IncubationRisk> risksForPair(String pairId) {
    return risks.where((risk) => risk.pairId == pairId).toList(growable: false);
  }

  List<IncubationRisk> risksForIncubation(String incubationId) {
    return risks
        .where((risk) => risk.incubationId == incubationId)
        .toList(growable: false);
  }
}

class IncubationRiskAssistant {
  const IncubationRiskAssistant();

  IncubationRiskSummary assess({
    required DateTime now,
    required List<BreedingPair> pairs,
    required List<Incubation> incubations,
    required List<Egg> eggs,
    required List<Chick> chicks,
  }) {
    final pairIds = pairs
        .where((pair) => !pair.isDeleted)
        .map((pair) => pair.id)
        .toSet();
    final incubationsByPair = _groupIncubationsByPair(incubations, pairIds);
    final eggsByIncubation = _groupEggsByIncubation(eggs);
    final chicksByEgg = _groupChicksByEgg(chicks);
    final risks = <IncubationRisk>[];

    for (final incubation in incubations) {
      if (incubation.breedingPairId == null ||
          !pairIds.contains(incubation.breedingPairId)) {
        continue;
      }
      final incubationEggs = eggsByIncubation[incubation.id] ?? const <Egg>[];
      risks.addAll(_overdueEggRisks(now, incubation, incubationEggs));
      final staleRisk = _staleTrackingRisk(now, incubation, incubationEggs);
      if (staleRisk != null) risks.add(staleRisk);
      final unsuccessfulRisk = _unsuccessfulEggRisk(
        now,
        incubation,
        incubationEggs,
      );
      if (unsuccessfulRisk != null) risks.add(unsuccessfulRisk);
      final chickRisk = _chickHealthRisk(
        incubation,
        incubationEggs,
        chicksByEgg,
      );
      if (chickRisk != null) risks.add(chickRisk);
    }

    for (final entry in incubationsByPair.entries) {
      final trendRisk = _hatchTrendRisk(
        entry.key,
        entry.value,
        eggsByIncubation,
      );
      if (trendRisk != null) risks.add(trendRisk);
    }

    return IncubationRiskSummary(risks);
  }

  List<IncubationRisk> _overdueEggRisks(
    DateTime now,
    Incubation incubation,
    List<Egg> eggs,
  ) {
    final risks = <IncubationRisk>[];
    for (final egg in eggs) {
      if (!_isActiveEgg(egg)) continue;
      final expected = egg.expectedHatchDateFor(species: incubation.species);
      final daysLate = date_utils.DateUtils.dayDiff(expected, now);
      if (daysLate <= 0) continue;
      risks.add(
        IncubationRisk(
          type: IncubationRiskType.overdueEgg,
          severity: daysLate >= 3
              ? IncubationRiskSeverity.critical
              : IncubationRiskSeverity.warning,
          titleKey: 'breeding.risk_overdue_egg_title',
          descriptionKey: 'breeding.risk_overdue_egg_desc',
          titleArgs: [_eggLabel(egg)],
          descriptionArgs: [daysLate.toString()],
          pairId: incubation.breedingPairId,
          incubationId: incubation.id,
          eggId: egg.id,
        ),
      );
    }
    return risks;
  }

  IncubationRisk? _staleTrackingRisk(
    DateTime now,
    Incubation incubation,
    List<Egg> eggs,
  ) {
    if (!incubation.isActive || eggs.isEmpty) return null;
    final dates = <DateTime>[
      if (incubation.updatedAt != null) incubation.updatedAt!,
      if (incubation.createdAt != null) incubation.createdAt!,
      if (incubation.startDate != null) incubation.startDate!,
      for (final egg in eggs) ...[
        egg.updatedAt ?? egg.createdAt ?? egg.layDate,
        if (egg.fertileCheckDate != null) egg.fertileCheckDate!,
        if (egg.hatchDate != null) egg.hatchDate!,
        if (egg.discardDate != null) egg.discardDate!,
      ],
    ];
    if (dates.isEmpty) return null;
    dates.sort();
    final daysSinceUpdate = date_utils.DateUtils.dayDiff(dates.last, now);
    if (daysSinceUpdate < 3) return null;
    return IncubationRisk(
      type: IncubationRiskType.staleTracking,
      severity: IncubationRiskSeverity.warning,
      titleKey: 'breeding.risk_stale_tracking_title',
      descriptionKey: 'breeding.risk_stale_tracking_desc',
      descriptionArgs: [daysSinceUpdate.toString()],
      pairId: incubation.breedingPairId,
      incubationId: incubation.id,
    );
  }

  IncubationRisk? _unsuccessfulEggRisk(
    DateTime now,
    Incubation incubation,
    List<Egg> eggs,
  ) {
    if (eggs.isEmpty) return null;
    var unsuccessful = 0;
    var knownUnsuccessful = 0;
    for (final egg in eggs) {
      if (_isKnownUnsuccessful(egg)) {
        unsuccessful++;
        knownUnsuccessful++;
        continue;
      }
      final expected = egg.expectedHatchDateFor(species: incubation.species);
      if (_isActiveEgg(egg) &&
          date_utils.DateUtils.dayDiff(expected, now) >= 3) {
        unsuccessful++;
      }
    }
    if (unsuccessful == 0) return null;
    if (eggs.length == 1 && knownUnsuccessful == 0) return null;
    final rate = unsuccessful / eggs.length;
    if (rate < 0.5) return null;
    return IncubationRisk(
      type: IncubationRiskType.highUnsuccessfulEggRate,
      severity: rate >= 0.75 && unsuccessful >= 2
          ? IncubationRiskSeverity.critical
          : IncubationRiskSeverity.warning,
      titleKey: 'breeding.risk_unsuccessful_eggs_title',
      descriptionKey: 'breeding.risk_unsuccessful_eggs_desc',
      descriptionArgs: [(rate * 100).round().toString()],
      pairId: incubation.breedingPairId,
      incubationId: incubation.id,
    );
  }

  IncubationRisk? _chickHealthRisk(
    Incubation incubation,
    List<Egg> eggs,
    Map<String, List<Chick>> chicksByEgg,
  ) {
    final eggIds = eggs.map((egg) => egg.id).toSet();
    final chicks = [
      for (final eggId in eggIds) ...chicksByEgg[eggId] ?? const <Chick>[],
    ];
    if (chicks.isEmpty) return null;
    final affected = chicks
        .where(
          (chick) =>
              chick.healthStatus == ChickHealthStatus.sick ||
              chick.healthStatus == ChickHealthStatus.deceased,
        )
        .length;
    if (affected == 0) return null;
    final deceased = chicks
        .where((chick) => chick.healthStatus == ChickHealthStatus.deceased)
        .length;
    final rate = affected / chicks.length;
    if (rate < 0.25) return null;
    return IncubationRisk(
      type: IncubationRiskType.chickHealthLoss,
      severity: deceased > 0
          ? IncubationRiskSeverity.critical
          : IncubationRiskSeverity.warning,
      titleKey: 'breeding.risk_chick_loss_title',
      descriptionKey: 'breeding.risk_chick_loss_desc',
      descriptionArgs: [affected.toString(), chicks.length.toString()],
      pairId: incubation.breedingPairId,
      incubationId: incubation.id,
    );
  }

  IncubationRisk? _hatchTrendRisk(
    String pairId,
    List<Incubation> incubations,
    Map<String, List<Egg>> eggsByIncubation,
  ) {
    final completed =
        incubations
            .where(
              (incubation) => incubation.status == IncubationStatus.completed,
            )
            .toList()
          ..sort((a, b) => _incubationDate(b).compareTo(_incubationDate(a)));
    if (completed.length < 2) return null;
    final latest = completed[0];
    final previous = completed[1];
    final latestEggs = eggsByIncubation[latest.id] ?? const <Egg>[];
    final previousEggs = eggsByIncubation[previous.id] ?? const <Egg>[];
    // Without eggs on either side, "hatch rate decline" is not a meaningful
    // signal — a barren incubation isn't a regression of the previous season.
    if (latestEggs.isEmpty || previousEggs.isEmpty) return null;
    final latestRate = _hatchRate(latestEggs);
    final previousRate = _hatchRate(previousEggs);
    if (previousRate < 0.5 || previousRate - latestRate < 0.25) return null;
    return IncubationRisk(
      type: IncubationRiskType.hatchRateDecline,
      severity: IncubationRiskSeverity.warning,
      titleKey: 'breeding.risk_hatch_decline_title',
      descriptionKey: 'breeding.risk_hatch_decline_desc',
      descriptionArgs: [
        (previousRate * 100).round().toString(),
        (latestRate * 100).round().toString(),
      ],
      pairId: pairId,
      incubationId: latest.id,
    );
  }
}

Map<String, List<Incubation>> _groupIncubationsByPair(
  List<Incubation> incubations,
  Set<String> pairIds,
) {
  final grouped = <String, List<Incubation>>{};
  for (final incubation in incubations) {
    final pairId = incubation.breedingPairId;
    if (pairId == null || !pairIds.contains(pairId)) continue;
    grouped.putIfAbsent(pairId, () => []).add(incubation);
  }
  return grouped;
}

Map<String, List<Egg>> _groupEggsByIncubation(List<Egg> eggs) {
  final grouped = <String, List<Egg>>{};
  for (final egg in eggs) {
    if (egg.isDeleted) continue;
    final incubationId = egg.incubationId;
    if (incubationId == null) continue;
    grouped.putIfAbsent(incubationId, () => []).add(egg);
  }
  return grouped;
}

Map<String, List<Chick>> _groupChicksByEgg(List<Chick> chicks) {
  final grouped = <String, List<Chick>>{};
  for (final chick in chicks) {
    if (chick.isDeleted) continue;
    final eggId = chick.eggId;
    if (eggId == null) continue;
    grouped.putIfAbsent(eggId, () => []).add(chick);
  }
  return grouped;
}

bool _isActiveEgg(Egg egg) {
  return egg.status == EggStatus.laid ||
      egg.status == EggStatus.fertile ||
      egg.status == EggStatus.incubating;
}

bool _isKnownUnsuccessful(Egg egg) {
  return egg.status == EggStatus.empty ||
      egg.status == EggStatus.damaged ||
      egg.status == EggStatus.discarded ||
      egg.status == EggStatus.infertile;
}

String _eggLabel(Egg egg) =>
    egg.eggNumber?.toString() ??
    egg.id.substring(0, egg.id.length < 4 ? egg.id.length : 4);

double _hatchRate(List<Egg> eggs) {
  if (eggs.isEmpty) return 0;
  final hatched = eggs.where((egg) => egg.status == EggStatus.hatched).length;
  return hatched / eggs.length;
}

DateTime _incubationDate(Incubation incubation) {
  return incubation.endDate ??
      incubation.startDate ??
      incubation.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

int _severityRank(IncubationRiskSeverity severity) {
  return switch (severity) {
    IncubationRiskSeverity.info => 0,
    IncubationRiskSeverity.warning => 1,
    IncubationRiskSeverity.critical => 2,
  };
}
