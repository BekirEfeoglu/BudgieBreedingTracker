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
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/export/excel_export_service.dart';
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
  late MockIncubationRepository incubationRepo;
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
    incubationRepo = MockIncubationRepository();
    eggRepo = MockEggRepository();
    chickRepo = MockChickRepository();
    healthRepo = MockHealthRecordRepository();

    when(() => birdRepo.saveAll(any())).thenAnswer((_) async {});
    when(() => birdRepo.getAll(any())).thenAnswer((_) async => []);
    when(() => birdRepo.getById(any())).thenAnswer((_) async => null);
    when(() => breedingRepo.saveAll(any())).thenAnswer((_) async {});
    when(() => breedingRepo.getAll(any())).thenAnswer((_) async => []);
    when(() => incubationRepo.saveAll(any())).thenAnswer((_) async {});
    when(() => eggRepo.saveAll(any())).thenAnswer((_) async {});
    when(() => chickRepo.saveAll(any())).thenAnswer((_) async {});
    when(() => healthRepo.saveAll(any())).thenAnswer((_) async {});

    service = DataImportService(
      birdRepo,
      breedingRepo,
      incubationRepo,
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
        final captured =
            verify(() => birdRepo.saveAll(captureAny())).captured.single
                as List;
        expect(captured, hasLength(1));
      },
    );

    test(
      'importBirdsFromExcel reads parent ids from exported columns',
      () async {
        when(() => birdRepo.getAll('user-1')).thenAnswer(
          (_) async => const [
            Bird(
              id: 'father-1',
              name: 'Father',
              gender: BirdGender.male,
              userId: 'user-1',
              species: Species.budgie,
            ),
            Bird(
              id: 'mother-1',
              name: 'Mother',
              gender: BirdGender.female,
              userId: 'user-1',
              species: Species.budgie,
            ),
          ],
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
        final capturedList =
            verify(() => birdRepo.saveAll(captureAny())).captured.single
                as List<Bird>;
        final captured = capturedList.single;
        expect(captured.fatherId, 'father-1');
        expect(captured.motherId, 'mother-1');
        expect(captured.notes, 'family-linked');
      },
    );

    test('importBirdsFromExcel rejects parent species mismatch', () async {
      when(() => birdRepo.getAll('user-1')).thenAnswer(
        (_) async => const [
          Bird(
            id: 'father-1',
            name: 'Father',
            gender: BirdGender.male,
            userId: 'user-1',
            species: Species.canary,
          ),
        ],
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
      verifyNever(() => birdRepo.saveAll(any()));
    });

    test(
      'importBirdsFromExcel keeps a bird whose parent ids cannot be resolved, '
      'nulling the dangling links instead of dropping the whole bird',
      () async {
        // Empty target flock: parent ids from a re-imported export / another
        // account resolve to nothing. Option A imports the bird with the
        // dangling lineage links dropped, rather than discarding it entirely
        // (which silently lost every bird that had a parent on re-import).
        when(() => birdRepo.getAll('user-1')).thenAnswer((_) async => const []);

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
              'Yavru',
              'TR-9',
              'Erkek',
              'Budgie',
              'Alive',
              '01.01.2025',
              '',
              'A1',
              '',
              'father-gone',
              'mother-gone',
              'orphaned',
            ],
          ],
        });

        final result = await service.importBirdsFromExcel(
          bytes: bytes,
          userId: 'user-1',
        );

        expect(result.importedCount, 1);
        expect(result.skippedCount, 0);
        expect(result.errors, isEmpty);
        final saved =
            (verify(() => birdRepo.saveAll(captureAny())).captured.single
                    as List<Bird>)
                .single;
        expect(saved.name, 'Yavru');
        expect(saved.fatherId, isNull);
        expect(saved.motherId, isNull);
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
        verifyNever(() => birdRepo.saveAll(any()));
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
      verifyNever(() => eggRepo.saveAll(any()));
    });

    test(
      'importBreedingPairsFromExcel rejects different-species pair',
      () async {
        when(() => birdRepo.getAll('user-1')).thenAnswer(
          (_) async => const [
            Bird(
              id: 'male-1',
              name: 'Male',
              gender: BirdGender.male,
              userId: 'user-1',
              species: Species.budgie,
            ),
            Bird(
              id: 'female-1',
              name: 'Female',
              gender: BirdGender.female,
              userId: 'user-1',
              species: Species.canary,
            ),
          ],
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
        verifyNever(() => breedingRepo.saveAll(any()));
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
      verify(() => birdRepo.saveAll(any())).called(1);
    });

    test('importBirdsFromExcel saves imported rows with a single saveAll '
        'instead of per-row save', () async {
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
          for (var i = 0; i < 5; i++)
            [
              'Kus $i',
              'TR-$i',
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
      );

      expect(result.importedCount, 5);
      final captured = verify(() => birdRepo.saveAll(captureAny())).captured;
      expect(captured, hasLength(1));
      expect(captured.single as List, hasLength(5));
      // Per-row save path is fully retired.
      verifyNever(() => birdRepo.save(any()));
    });

    test('importBirdsFromExcel resolves a parent bird whose id is only known '
        'from a previously-validated import, without a per-row getById '
        'lookup', () async {
      // ExcelRowParsers.parseBirdRow assigns each bird a fresh
      // Uuid().v7() id that is never derived from any Excel column, so
      // no fixture can hardcode ahead of time the id a same-call row
      // will receive — a byte-level, single-call, both-rows-fresh
      // "row 3 references row 2's not-yet-known id" fixture cannot be
      // constructed (there is no id-injection seam in Uuid or the
      // parser). Instead, this test proves the shared birdsById map
      // (existing DB birds + rows validated so far in the current
      // call, data_import_service.dart's importBirdsFromExcel) resolves
      // a real, non-fabricated id with a single getAll and zero
      // getById calls: phase 1 imports the parent alone and captures
      // its true generated id from the saveAll(captureAny()) argument;
      // phase 2 imports a child file whose "Baba ID" cell is that real
      // id, with getAll seeded to return the phase-1 parent (its id is
      // otherwise unknowable at fixture-authoring time).
      when(() => birdRepo.getAll('user-1')).thenAnswer((_) async => []);

      final parentBytes = _buildWorkbook({
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
            'Baba',
            'TR-1',
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
      final parentResult = await service.importBirdsFromExcel(
        bytes: parentBytes,
        userId: 'user-1',
      );
      expect(parentResult.importedCount, 1);
      final parentCaptured =
          verify(() => birdRepo.saveAll(captureAny())).captured.single
              as List<Bird>;
      final parent = parentCaptured.single;
      final parentId = parent.id;

      // The parent's real id is only knowable after phase 1 ran, so it
      // cannot be embedded in a pre-existing test fixture — seed it here.
      when(() => birdRepo.getAll('user-1')).thenAnswer((_) async => [parent]);

      final childBytes = _buildWorkbook({
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
            'Yavru',
            'TR-2',
            'Erkek',
            'Budgie',
            'Alive',
            '01.02.2025',
            '',
            'A1',
            '',
            parentId,
            // No trailing "Anne ID"/"Notlar" cells: cellToString(row, 10)
            // must see index >= row.length (returns null), not an
            // empty-string cell (which would fail bird.motherId != null
            // and throw birds.not_found for an unrelated reason).
          ],
        ],
      });
      final childResult = await service.importBirdsFromExcel(
        bytes: childBytes,
        userId: 'user-1',
      );

      expect(childResult.importedCount, 1);
      expect(childResult.errors, isEmpty);
      verifyNever(() => birdRepo.getById(any()));
    });

    test('importBirdsFromExcel validates parents from a single preloaded map '
        'without per-row getById calls', () async {
      when(() => birdRepo.getAll('user-1')).thenAnswer(
        (_) async => const [
          Bird(
            id: 'father-1',
            name: 'Father',
            gender: BirdGender.male,
            userId: 'user-1',
            species: Species.budgie,
          ),
          Bird(
            id: 'mother-1',
            name: 'Mother',
            gender: BirdGender.female,
            userId: 'user-1',
            species: Species.budgie,
          ),
        ],
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
            '',
          ],
          [
            'Sari',
            'TR-2',
            'Dişi',
            'Budgie',
            'Alive',
            '01.01.2025',
            '',
            'A2',
            '',
            'father-1',
            'mother-1',
            '',
          ],
        ],
      });

      final result = await service.importBirdsFromExcel(
        bytes: bytes,
        userId: 'user-1',
      );

      expect(result.importedCount, 2);
      // Bird map is loaded once for the whole sheet, not per row.
      verify(() => birdRepo.getAll('user-1')).called(1);
      verifyNever(() => birdRepo.getById(any()));
    });
  });

  group('Excel export → import round-trip (Option B)', () {
    test('birds round-trip preserves ids, lineage and fields', () async {
      const userId = 'user-1';
      final father = createTestBird(
        id: 'bird-father',
        name: 'Baba',
        gender: BirdGender.male,
        species: Species.budgie,
        userId: userId,
      );
      final mother = createTestBird(
        id: 'bird-mother',
        name: 'Anne',
        gender: BirdGender.female,
        species: Species.budgie,
        userId: userId,
      );
      final child = createTestBird(
        id: 'bird-child',
        name: 'Yavru',
        gender: BirdGender.male,
        species: Species.budgie,
        userId: userId,
        fatherId: 'bird-father',
        motherId: 'bird-mother',
      );

      // Real export → real import into an empty account. Because the export
      // now carries the full id and the import preserves it, the child's
      // parent refs resolve to the just-imported parents (same ids).
      final bytes = await ExcelExportService().exportBirds([
        father,
        mother,
        child,
      ]);
      final result = await service.importBirdsFromExcel(
        bytes: bytes,
        userId: userId,
      );

      expect(result.importedCount, 3);
      expect(result.errors, isEmpty);
      final saved =
          verify(() => birdRepo.saveAll(captureAny())).captured.single
              as List<Bird>;
      final savedChild = saved.firstWhere((b) => b.name == 'Yavru');
      expect(savedChild.id, 'bird-child'); // full id preserved (not truncated)
      expect(savedChild.fatherId, 'bird-father'); // lineage survived
      expect(savedChild.motherId, 'bird-mother');
      expect(savedChild.species, Species.budgie);
      expect(savedChild.gender, BirdGender.male);
    });

    test('pairs / eggs / chicks round-trip preserve their ids', () async {
      const userId = 'user-1';
      final male = createTestBird(
        id: 'male-1',
        gender: BirdGender.male,
        species: Species.budgie,
        userId: userId,
      );
      final female = createTestBird(
        id: 'female-1',
        gender: BirdGender.female,
        species: Species.budgie,
        userId: userId,
      );
      const pair = BreedingPair(
        id: 'pair-1',
        userId: userId,
        maleId: 'male-1',
        femaleId: 'female-1',
        status: BreedingStatus.active,
      );
      final egg = Egg(
        id: 'egg-1',
        userId: userId,
        layDate: DateTime(2026, 1, 1),
        status: EggStatus.laid,
        incubationId: 'inc-1',
      );
      const chick = Chick(
        id: 'chick-1',
        userId: userId,
        name: 'Civ',
        gender: BirdGender.male,
        healthStatus: ChickHealthStatus.healthy,
      );

      final bytes = await ExcelExportService().exportAll(
        birds: [male, female],
        pairs: [pair],
        incubations: const [],
        eggs: [egg],
        chicks: [chick],
      );

      // Pair birds must resolve → seed the account with them.
      when(
        () => birdRepo.getAll(userId),
      ).thenAnswer((_) async => [male, female]);
      final pairResult = await service.importBreedingPairsFromExcel(
        bytes: bytes,
        userId: userId,
      );
      expect(pairResult.importedCount, 1);
      final savedPair =
          (verify(() => breedingRepo.saveAll(captureAny())).captured.single
              as List<BreedingPair>).single;
      expect(savedPair.id, 'pair-1');
      expect(savedPair.maleId, 'male-1');

      final eggResult = await service.importEggsFromExcel(
        bytes: bytes,
        userId: userId,
      );
      expect(eggResult.importedCount, 1);
      final savedEgg =
          (verify(() => eggRepo.saveAll(captureAny())).captured.single
              as List<Egg>).single;
      expect(savedEgg.id, 'egg-1');
      expect(savedEgg.incubationId, 'inc-1');

      final chickResult = await service.importChicksFromExcel(
        bytes: bytes,
        userId: userId,
      );
      expect(chickResult.importedCount, 1);
      final savedChick =
          (verify(() => chickRepo.saveAll(captureAny())).captured.single
              as List<Chick>).single;
      expect(savedChick.id, 'chick-1');
      expect(savedChick.gender, BirdGender.male);
    });

    test(
      'incubations round-trip: exported incubation is re-imported with its '
      'full id so eggs keep their incubationId link',
      () async {
        const userId = 'user-1';
        const incubation = Incubation(
          id: 'incubation-abcdef-123456',
          userId: userId,
          breedingPairId: 'pair-1',
          species: Species.budgie,
          status: IncubationStatus.active,
        );
        final egg = Egg(
          id: 'egg-1',
          userId: userId,
          layDate: DateTime(2026, 1, 1),
          status: EggStatus.laid,
          incubationId: 'incubation-abcdef-123456',
        );

        final bytes = await ExcelExportService().exportAll(
          birds: const [],
          pairs: const [],
          incubations: const [incubation],
          eggs: [egg],
          chicks: const [],
        );

        final results = await service.importAllFromExcel(
          bytes: bytes,
          userId: userId,
        );

        // Incubation survives the round-trip (was silently dropped before).
        expect(results['incubations']!.importedCount, 1);
        final savedInc =
            (verify(() => incubationRepo.saveAll(captureAny())).captured.single
                as List<Incubation>).single;
        expect(savedInc.id, 'incubation-abcdef-123456');
        expect(savedInc.breedingPairId, 'pair-1');
        expect(savedInc.species, Species.budgie);
        expect(savedInc.status, IncubationStatus.active);

        // The egg's FK still points at the (now-imported) incubation's full id.
        final savedEgg =
            (verify(() => eggRepo.saveAll(captureAny())).captured.single
                as List<Egg>).single;
        expect(savedEgg.incubationId, 'incubation-abcdef-123456');
      },
    );

    test('health records round-trip preserves id and fields', () async {
      const userId = 'user-1';
      final record = HealthRecord(
        id: 'health-1',
        userId: userId,
        title: 'Yearly check',
        type: HealthRecordType.vaccination,
        date: DateTime(2026, 3, 14),
        birdId: 'bird-1',
        treatment: 'Vitamin boost',
        veterinarian: 'Dr. Kus',
      );

      final bytes = await ExcelExportService().exportAll(
        birds: const [],
        pairs: const [],
        incubations: const [],
        eggs: const [],
        chicks: const [],
        healthRecords: [record],
      );

      final result = await service.importHealthRecordsFromExcel(
        bytes: bytes,
        userId: userId,
      );

      expect(result.importedCount, 1);
      final saved =
          (verify(() => healthRepo.saveAll(captureAny())).captured.single
              as List<HealthRecord>).single;
      expect(saved.id, 'health-1');
      expect(saved.title, 'Yearly check');
      expect(saved.type, HealthRecordType.vaccination);
      expect(saved.birdId, 'bird-1');
      expect(saved.treatment, 'Vitamin boost');
      expect(saved.veterinarian, 'Dr. Kus');
    });
  });
}
