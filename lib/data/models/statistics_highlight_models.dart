class SeasonRecord {
  final int year;
  final int chickCount;

  const SeasonRecord({required this.year, required this.chickCount});
}

class TopPairRecord {
  final String pairId;
  final int chickCount;

  const TopPairRecord({required this.pairId, required this.chickCount});
}

class LongevityRecord {
  final String birdId;
  final String birdName;
  final int daysLived;

  const LongevityRecord({
    required this.birdId,
    required this.birdName,
    required this.daysLived,
  });
}

class PersonalRecords {
  final SeasonRecord? mostProductiveSeason;
  final TopPairRecord? topPair;
  final LongevityRecord? longestLivedBird;

  const PersonalRecords({
    this.mostProductiveSeason,
    this.topPair,
    this.longestLivedBird,
  });
}

class SeasonStats {
  final int year;
  final int totalEggs;
  final int fertileEggs;
  final int hatchedChicks;
  final int liveChicks;

  const SeasonStats({
    required this.year,
    required this.totalEggs,
    required this.fertileEggs,
    required this.hatchedChicks,
    required this.liveChicks,
  });

  double get fertilityRate => totalEggs > 0 ? fertileEggs / totalEggs : 0;
}

class SeasonComparison {
  final SeasonStats previous;
  final SeasonStats current;

  const SeasonComparison({required this.previous, required this.current});

  double get fertilityDelta => current.fertilityRate - previous.fertilityRate;
  int get chickDelta => current.hatchedChicks - previous.hatchedChicks;
}

class HealthTrendSummary {
  final String? busiestMonthKey;
  final int busiestMonthRecordCount;
  final String? mostVisitedBirdId;
  final String? mostVisitedBirdName;
  final int mostVisitedBirdRecordCount;
  final double? averageTreatmentDays;

  const HealthTrendSummary({
    this.busiestMonthKey,
    this.busiestMonthRecordCount = 0,
    this.mostVisitedBirdId,
    this.mostVisitedBirdName,
    this.mostVisitedBirdRecordCount = 0,
    this.averageTreatmentDays,
  });
}
