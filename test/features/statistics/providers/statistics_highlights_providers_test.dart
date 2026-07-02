import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_highlights_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_fixtures.dart';

void main() {
  // mostProductiveSeason and topPair are now SQL-aggregated
  // (ChicksDao.watchMostProductiveSeason / watchTopPairByChickCount) —
  // see test/data/local/database/daos/chicks_dao_test.dart for their
  // coverage. findLongestLivedBird stays a pure Dart function (birds are
  // naturally bounded per user), so it's still unit-tested here directly.
  group('findLongestLivedBird', () {
    test('finds the bird with the longest lifespan', () {
      final birds = [
        createTestBird(
          id: 'old',
          name: 'Oldie',
          birthDate: DateTime(2018),
          deathDate: DateTime(2025),
        ),
        createTestBird(id: 'young', name: 'Young', birthDate: DateTime(2024)),
      ];

      final result = findLongestLivedBird(birds, now: DateTime(2026));

      expect(result?.birdName, 'Oldie');
    });

    test('returns null when no bird has a birthDate', () {
      final birds = [createTestBird(id: 'b1', name: 'NoDates')];

      final result = findLongestLivedBird(birds, now: DateTime(2026));

      expect(result, isNull);
    });

    test('ignores birds with a future birthDate', () {
      final birds = [
        createTestBird(
          id: 'future',
          name: 'FutureBird',
          birthDate: DateTime(2027),
        ),
      ];

      final result = findLongestLivedBird(birds, now: DateTime(2026));

      expect(result, isNull);
    });
  });

  // Season year detection and per-year stats are now SQL-aggregated
  // (EggsDao.watchDistinctLayYears / watchSeasonEggStats,
  // ChicksDao.watchDistinctHatchYears / watchSeasonChickStats) — see
  // test/data/local/database/daos/eggs_dao_test.dart and
  // chicks_dao_test.dart for their coverage, and
  // test/features/statistics/providers/statistics_providers_test.dart for
  // the combined seasonComparisonProvider reactive chain.

  // Busiest month/bird/avg-treatment-days are now SQL-aggregated
  // (HealthRecordsDao.watchBusiestMonth / watchBusiestBird /
  // watchAverageTreatmentDays) — see
  // test/data/local/database/daos/health_records_dao_test.dart for their
  // coverage. The bird-name lookup itself is a one-line fallback
  // (`birdsById[id]?.name ?? id`) folded directly into
  // healthTrendSummaryProvider, exercised by the statistics e2e test.
}
