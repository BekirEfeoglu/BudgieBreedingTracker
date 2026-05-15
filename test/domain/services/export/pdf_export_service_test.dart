import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pdf_export_service.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_highlights_providers.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfExportService service;

  setUp(() {
    service = PdfExportService();
  });

  group('PdfExportService', () {
    test('generateFullReport creates a valid PDF for mixed data', () async {
      final birds = [createTestBird(id: 'bird-0001', name: 'Mavi')];
      final pairs = [
        BreedingPair(
          id: 'pair-0001',
          userId: 'user-1',
          maleId: 'bird-0001',
          femaleId: 'bird-0002',
          pairingDate: DateTime(2026, 1, 1),
        ),
      ];
      final eggs = [
        Egg(
          id: 'egg-0001',
          userId: 'user-1',
          layDate: DateTime(2026, 1, 5),
          status: EggStatus.laid,
          eggNumber: 1,
        ),
      ];
      final incubations = [
        Incubation(
          id: 'inc-0001',
          userId: 'user-1',
          breedingPairId: 'pair-0001',
          species: Species.cockatiel,
          status: IncubationStatus.active,
          startDate: DateTime(2026, 1, 1),
        ),
      ];
      final chicks = [
        Chick(
          id: 'chick-0001',
          userId: 'user-1',
          name: 'Minik',
          hatchDate: DateTime(2026, 1, 22),
        ),
      ];

      final bytes = await service.generateFullReport(
        birds: birds,
        pairs: pairs,
        incubations: incubations,
        eggs: eggs,
        chicks: chicks,
      );

      _expectPdf(bytes);
      expect(bytes.length, greaterThan(800));
    });

    test(
      'generateFullReport still creates a valid PDF when lists are empty',
      () async {
        final bytes = await service.generateFullReport(
          birds: const [],
          pairs: const [],
          incubations: const [],
          eggs: const [],
          chicks: const [],
        );

        _expectPdf(bytes);
        expect(bytes.length, greaterThan(400));
      },
    );

    test(
      'generateBirdReport creates a valid PDF for bird-only export',
      () async {
        final bytes = await service.generateBirdReport([
          createTestBird(id: 'bird-0100', name: 'Sari'),
        ]);

        _expectPdf(bytes);
        expect(bytes.length, greaterThan(500));
      },
    );

    test(
      'generateBreedingReport creates a valid PDF for breeding data',
      () async {
        final bytes = await service.generateBreedingReport([
          BreedingPair(
            id: 'pair-1111',
            userId: 'user-1',
            maleId: 'bird-0001',
            femaleId: 'bird-0002',
            cageNumber: 'A1',
            pairingDate: DateTime(2026, 2, 1),
          ),
        ]);

        _expectPdf(bytes);
        expect(bytes.length, greaterThan(500));
      },
    );

    test(
      'generateStatisticsReport creates a valid PDF for highlights',
      () async {
        final bytes = await service.generateStatisticsReport(
          personalRecords: const PersonalRecords(
            mostProductiveSeason: SeasonRecord(year: 2025, chickCount: 8),
            topPair: TopPairRecord(pairId: 'pair-1', chickCount: 6),
            longestLivedBird: LongevityRecord(
              birdId: 'bird-1',
              birdName: 'Mavi',
              daysLived: 1200,
            ),
          ),
          seasonComparison: const SeasonComparison(
            previous: SeasonStats(
              year: 2024,
              totalEggs: 10,
              fertileEggs: 6,
              hatchedChicks: 4,
              liveChicks: 3,
            ),
            current: SeasonStats(
              year: 2025,
              totalEggs: 12,
              fertileEggs: 9,
              hatchedChicks: 7,
              liveChicks: 7,
            ),
          ),
          healthTrend: const HealthTrendSummary(
            busiestMonthKey: '2025-01',
            busiestMonthRecordCount: 5,
            mostVisitedBirdName: 'Mavi',
            mostVisitedBirdRecordCount: 3,
            averageTreatmentDays: 4.5,
          ),
        );

        _expectPdf(bytes);
        expect(bytes.length, greaterThan(500));
      },
    );
  });
}

void _expectPdf(Uint8List bytes) {
  expect(bytes, isNotEmpty);
  expect(String.fromCharCodes(bytes.take(4)), '%PDF');
}
