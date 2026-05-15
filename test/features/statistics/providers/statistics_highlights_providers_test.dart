import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_highlights_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_fixtures.dart';

void main() {
  group('buildPersonalRecords', () {
    test('finds most productive season, top pair, and longest-lived bird', () {
      const pair = BreedingPair(
        id: 'pair-1',
        userId: 'user-1',
        maleId: 'male-1',
        femaleId: 'female-1',
      );
      final clutch = Clutch(
        id: 'clutch-1',
        userId: 'user-1',
        breedingId: pair.id,
      );
      final chicks = [
        Chick(
          id: 'c1',
          userId: 'user-1',
          clutchId: clutch.id,
          hatchDate: DateTime(2025, 4, 1),
        ),
        Chick(
          id: 'c2',
          userId: 'user-1',
          clutchId: clutch.id,
          hatchDate: DateTime(2025, 4, 2),
        ),
      ];
      final birds = [
        createTestBird(
          id: 'old',
          name: 'Oldie',
          birthDate: DateTime(2018),
          deathDate: DateTime(2025),
        ),
        createTestBird(id: 'young', name: 'Young', birthDate: DateTime(2024)),
      ];

      final result = buildPersonalRecords(
        birds: birds,
        pairs: [pair],
        clutches: [clutch],
        chicks: chicks,
        now: DateTime(2026),
      );

      expect(result.mostProductiveSeason?.year, 2025);
      expect(result.mostProductiveSeason?.chickCount, 2);
      expect(result.topPair?.pairId, pair.id);
      expect(result.topPair?.chickCount, 2);
      expect(result.longestLivedBird?.birdName, 'Oldie');
    });
  });

  group('buildSeasonComparison', () {
    test('compares the two latest seasons with fertility and live chicks', () {
      final eggs = [
        Egg(
          id: 'e1',
          userId: 'user-1',
          layDate: DateTime(2024, 3),
          status: EggStatus.infertile,
        ),
        Egg(
          id: 'e2',
          userId: 'user-1',
          layDate: DateTime(2024, 3),
          status: EggStatus.fertile,
        ),
        Egg(
          id: 'e3',
          userId: 'user-1',
          layDate: DateTime(2025, 3),
          status: EggStatus.hatched,
        ),
        Egg(
          id: 'e4',
          userId: 'user-1',
          layDate: DateTime(2025, 3),
          status: EggStatus.fertile,
        ),
      ];
      final chicks = [
        Chick(
          id: 'c1',
          userId: 'user-1',
          hatchDate: DateTime(2024, 4),
          healthStatus: ChickHealthStatus.deceased,
        ),
        Chick(
          id: 'c2',
          userId: 'user-1',
          hatchDate: DateTime(2025, 4),
          healthStatus: ChickHealthStatus.healthy,
        ),
      ];

      final result = buildSeasonComparison(eggs: eggs, chicks: chicks);

      expect(result?.previous.year, 2024);
      expect(result?.current.year, 2025);
      expect(result?.previous.fertilityRate, 0.5);
      expect(result?.current.fertilityRate, 1.0);
      expect(result?.fertilityDelta, 0.5);
      expect(result?.current.liveChicks, 1);
    });
  });

  group('buildHealthTrend', () {
    test(
      'finds busiest month, most visited bird, and average follow-up days',
      () {
        final records = [
          HealthRecord(
            id: 'h1',
            userId: 'user-1',
            birdId: 'bird-1',
            date: DateTime(2025, 1, 1),
            followUpDate: DateTime(2025, 1, 6),
            type: HealthRecordType.illness,
            title: 'Illness',
          ),
          HealthRecord(
            id: 'h2',
            userId: 'user-1',
            birdId: 'bird-1',
            date: DateTime(2025, 1, 10),
            followUpDate: DateTime(2025, 1, 12),
            type: HealthRecordType.checkup,
            title: 'Checkup',
          ),
          HealthRecord(
            id: 'h3',
            userId: 'user-1',
            birdId: 'bird-2',
            date: DateTime(2025, 2, 1),
            type: HealthRecordType.vaccination,
            title: 'Vaccination',
          ),
        ];
        final birds = [
          createTestBird(id: 'bird-1', name: 'Mavi'),
          createTestBird(id: 'bird-2', name: 'Sari'),
        ];

        final result = buildHealthTrend(records: records, birds: birds);

        expect(result.busiestMonthKey, '2025-01');
        expect(result.busiestMonthRecordCount, 2);
        expect(result.mostVisitedBirdName, 'Mavi');
        expect(result.averageTreatmentDays, 3.5);
      },
    );
  });
}
