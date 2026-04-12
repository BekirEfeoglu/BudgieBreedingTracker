import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
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
    when(() => birdRepo.getById(any())).thenAnswer((_) async => null);
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
      'importBirdsFromExcel reads parent ids from exported columns',
      () async {
        when(() => birdRepo.getById('father-1')).thenAnswer(
          (_) async => const Bird(
            id: 'father-1',
            name: 'Father',
            gender: BirdGender.male,
            userId: 'user-1',
            species: Species.budgie,
          ),
        );
        when(() => birdRepo.getById('mother-1')).thenAnswer(
          (_) async => const Bird(
            id: 'mother-1',
            name: 'Mother',
            gender: BirdGender.female,
            userId: 'user-1',
            species: Species.budgie,
          ),
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
              'Legacy Notlar',
              'Baba ID',
              'Anne ID',
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
              'father-1',
              'mother-1',
              'family-linked',
            ],
          ],
        });

        final result = await service.importBirdsFromExcel(
          bytes: bytes,
          userId: 'user-1',
        );

        expect(result.importedCount, 1);
        final captured =
            verify(() => birdRepo.save(captureAny())).captured.single as Bird;
        expect(captured.fatherId, 'father-1');
        expect(captured.motherId, 'mother-1');
        expect(captured.notes, 'family-linked');
      },
    );

    test('importBirdsFromExcel rejects parent species mismatch', () async {
      when(() => birdRepo.getById('father-1')).thenAnswer(
        (_) async => const Bird(
          id: 'father-1',
          name: 'Father',
          gender: BirdGender.male,
          userId: 'user-1',
          species: Species.canary,
        ),
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
            'Legacy Notlar',
            'Baba ID',
            'Anne ID',
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
            'father-1',
            '',
            '',
          ],
        ],
      });

      final result = await service.importBirdsFromExcel(
        bytes: bytes,
        userId: 'user-1',
      );

      expect(result.importedCount, 0);
      expect(result.skippedCount, 1);
      expect(result.errors, contains(l10n('birds.parent_species_mismatch')));
      verifyNever(() => birdRepo.save(any()));
    });

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

    test(
      'importBreedingPairsFromExcel rejects different-species pair',
      () async {
        when(() => birdRepo.getById('male-1')).thenAnswer(
          (_) async => const Bird(
            id: 'male-1',
            name: 'Male',
            gender: BirdGender.male,
            userId: 'user-1',
            species: Species.budgie,
          ),
        );
        when(() => birdRepo.getById('female-1')).thenAnswer(
          (_) async => const Bird(
            id: 'female-1',
            name: 'Female',
            gender: BirdGender.female,
            userId: 'user-1',
            species: Species.canary,
          ),
        );

        final bytes = _buildWorkbook({
          'Ureme Ciftleri': [
            [
              'Erkek ID',
              'Disi ID',
              'Kafes',
              'Durum',
              'Eslestirme',
              'Ayrilma',
              'Notlar',
            ],
            ['male-1', 'female-1', 'B3', 'active', '01.01.2025', '', ''],
          ],
        });

        final result = await service.importBreedingPairsFromExcel(
          bytes: bytes,
          userId: 'user-1',
        );

        expect(result.importedCount, 0);
        expect(result.skippedCount, 1);
        expect(result.errors, contains(l10n('breeding.same_species_required')));
        verifyNever(() => breedingRepo.save(any()));
      },
    );

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
