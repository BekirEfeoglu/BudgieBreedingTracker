import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/domain/services/import/data_import_service.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

Uint8List _buildWorkbook(Map<String, List<List<String>>> sheets) {
  final excel = Excel.createExcel();
  for (final entry in sheets.entries) {
    final sheet = excel[entry.key];
    for (final row in entry.value) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }
  }
  return Uint8List.fromList(excel.save()!);
}

void main() {
  late MockBirdRepository birdRepo;
  late MockBreedingPairRepository breedingRepo;
  late MockEggRepository eggRepo;
  late MockChickRepository chickRepo;
  late MockHealthRecordRepository healthRepo;
  late DataImportService service;

  setUpAll(() {
    registerFallbackValue(createTestBird());
    registerFallbackValue(
      const BreedingPair(id: 'p1', userId: 'u1', status: BreedingStatus.active),
    );
    registerFallbackValue(
      Egg(
        id: 'e1',
        userId: 'u1',
        layDate: DateTime(2026, 1, 1),
        status: EggStatus.laid,
      ),
    );
    registerFallbackValue(
      const Chick(
        id: 'c1',
        userId: 'u1',
        healthStatus: ChickHealthStatus.healthy,
      ),
    );
    registerFallbackValue(
      HealthRecord(
        id: 'h1',
        userId: 'u1',
        title: 'check',
        date: DateTime(2026, 1, 1),
        type: HealthRecordType.checkup,
      ),
    );
  });

  setUp(() {
    birdRepo = MockBirdRepository();
    breedingRepo = MockBreedingPairRepository();
    eggRepo = MockEggRepository();
    chickRepo = MockChickRepository();
    healthRepo = MockHealthRecordRepository();

    when(() => birdRepo.save(any())).thenAnswer((_) async {});
    when(() => birdRepo.getAll(any())).thenAnswer((_) async => []);
    when(() => breedingRepo.save(any())).thenAnswer((_) async {});
    when(() => breedingRepo.getAll(any())).thenAnswer((_) async => []);
    when(() => eggRepo.save(any())).thenAnswer((_) async {});
    when(() => chickRepo.save(any())).thenAnswer((_) async {});
    when(() => healthRepo.save(any())).thenAnswer((_) async {});

    service = DataImportService(
      birdRepo,
      breedingRepo,
      eggRepo,
      chickRepo,
      healthRepo,
    );
  });

  group('DataImportService', () {
    test(
      'importBirdsFromExcel imports valid rows and skips empty-name rows',
      () async {
        final bytes = _buildWorkbook({
          'Kuslar': [
            [
              'Ad',
              'Halka No',
              'Cinsiyet',
              'Tur',
              'Durum',
              'Dogum Tarihi',
              'Renk',
              'Kafes',
              'Notlar',
            ],
            [
              'Mavi',
              'TR-1',
              'Erkek',
              'Budgie',
              'Alive',
              '01.01.2025',
              '',
              'A1',
              '',
            ],
            ['', 'TR-2', 'Dişi', 'Budgie', 'Alive', '01.01.2025', '', 'A2', ''],
          ],
        });

        final result = await service.importBirdsFromExcel(
          bytes: bytes,
          userId: 'user-1',
        );

        expect(result.totalRows, 2);
        expect(result.importedCount, 1);
        expect(result.skippedCount, 1);
        verify(() => birdRepo.save(any())).called(1);
      },
    );

    test(
      'importBirdsFromExcel enforces maxTotalBirds limit for free tier',
      () async {
        when(() => birdRepo.getAll(any())).thenAnswer(
          (_) async => List.generate(15, (i) => createTestBird(id: 'b-$i')),
        );

        final bytes = _buildWorkbook({
          'Kuslar': [
            [
              'Ad',
              'Halka No',
              'Cinsiyet',
              'Tur',
              'Durum',
              'Dogum Tarihi',
              'Renk',
              'Kafes',
              'Notlar',
            ],
            [
              'Yeni Kus',
              'TR-99',
              'Erkek',
              'Budgie',
              'Alive',
              '01.01.2025',
              '',
              'A1',
              '',
            ],
          ],
        });

        final result = await service.importBirdsFromExcel(
          bytes: bytes,
          userId: 'user-1',
          maxTotalBirds: 15,
        );

        expect(result.totalRows, 1);
        expect(result.importedCount, 0);
        expect(result.skippedCount, 1);
        verifyNever(() => birdRepo.save(any()));
      },
    );

    test('importEggsFromExcel requires lay date', () async {
      final bytes = _buildWorkbook({
        'Yumurtalar': [
          [
            'No',
            'Yumurtlama',
            'Durum',
            'Doller',
            'Cikim',
            'Kulucka ID',
            'Notlar',
          ],
          ['1', '', 'laid', '', '', '', ''],
        ],
      });

      final result = await service.importEggsFromExcel(
        bytes: bytes,
        userId: 'user-1',
      );

      expect(result.totalRows, 1);
      expect(result.importedCount, 0);
      expect(result.skippedCount, 1);
      verifyNever(() => eggRepo.save(any()));
    });

    test('importAllFromExcel returns per-entity result map', () async {
      final bytes = _buildWorkbook({
        'Kuslar': [
          [
            'Ad',
            'Halka No',
            'Cinsiyet',
            'Tur',
            'Durum',
            'Dogum Tarihi',
            'Renk',
            'Kafes',
            'Notlar',
          ],
          [
            'Sari',
            'TR-3',
            'Dişi',
            'Budgie',
            'Alive',
            '01.02.2025',
            '',
            'B1',
            '',
          ],
        ],
      });

      final results = await service.importAllFromExcel(
        bytes: bytes,
        userId: 'user-1',
      );

      expect(
        results.keys,
        containsAll([
          'birds',
          'breeding_pairs',
          'eggs',
          'chicks',
          'health_records',
        ]),
      );
      expect(results['birds']!.importedCount, 1);
      verify(() => birdRepo.save(any())).called(1);
    });
  });
}
