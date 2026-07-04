import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/import/excel_import_helpers.dart';
import 'package:budgie_breeding_tracker/domain/services/import/excel_row_parsers.dart';
import 'package:budgie_breeding_tracker/domain/services/import/import_result.dart';

part 'data_import_service_sheet.dart';

/// Imports data from Excel files into the local database.
///
/// Consumes workbooks in the documented IMPORT column layout (see each parser's
/// `Expected columns`) — a hand-fillable template. This is NOT byte-compatible
/// with the human-readable export report, whose column order differs; the
/// lossless round-trip path is the encrypted backup. A parent/FK reference that
/// cannot be resolved to a bird in the user's flock is dropped (the row still
/// imports) instead of discarding the whole record — see [_sanitizeBirdParents].
class DataImportService {
  DataImportService(
    this._birdRepo,
    this._breedingPairRepo,
    this._eggRepo,
    this._chickRepo,
    this._healthRecordRepo,
  );

  final BirdRepository _birdRepo;
  final BreedingPairRepository _breedingPairRepo;
  final EggRepository _eggRepo;
  final ChickRepository _chickRepo;
  final HealthRecordRepository _healthRecordRepo;

  /// Validates and, where necessary, sanitizes a bird's parent references,
  /// returning the bird to persist.
  ///
  /// A parent reference that cannot be RESOLVED (no such bird in this user's
  /// flock) is nulled out and the bird is still imported. Excel is a
  /// human-readable report, not a lossless round-trip format — the encrypted
  /// backup is — and the import regenerates ids, so cross-file lineage links
  /// can't survive a re-import anyway. Dropping only the dangling link (rather
  /// than the whole bird) stops a re-imported flock from silently losing every
  /// bird that has a parent. A parent that DOES resolve but is genetically
  /// invalid (wrong gender / different species) is a real data error and still
  /// rejects the row, preserving typo detection for hand-crafted templates.
  Bird _sanitizeBirdParents(Bird bird, Map<String, Bird> birdsById) {
    var fatherId = bird.fatherId;
    var motherId = bird.motherId;

    if (fatherId != null) {
      final father = birdsById[fatherId];
      if (father == null || father.userId != bird.userId) {
        fatherId = null; // unresolvable → drop the link, keep the bird
      } else if (father.gender != BirdGender.male) {
        throw const _ImportValidationException('birds.invalid_father');
      } else if (father.species != bird.species) {
        throw const _ImportValidationException('birds.parent_species_mismatch');
      }
    }

    if (motherId != null) {
      final mother = birdsById[motherId];
      if (mother == null || mother.userId != bird.userId) {
        motherId = null; // unresolvable → drop the link, keep the bird
      } else if (mother.gender != BirdGender.female) {
        throw const _ImportValidationException('birds.invalid_mother');
      } else if (mother.species != bird.species) {
        throw const _ImportValidationException('birds.parent_species_mismatch');
      }
    }

    if (fatherId == bird.fatherId && motherId == bird.motherId) return bird;
    return bird.copyWith(fatherId: fatherId, motherId: motherId);
  }

  void _validateBreedingPairBirds(
    BreedingPair pair,
    Map<String, Bird> birdsById,
  ) {
    if (pair.maleId == null || pair.femaleId == null) return;

    final maleBird = birdsById[pair.maleId!];
    final femaleBird = birdsById[pair.femaleId!];
    if (maleBird == null ||
        femaleBird == null ||
        maleBird.userId != pair.userId ||
        femaleBird.userId != pair.userId) {
      throw const _ImportValidationException('birds.not_found');
    }
    if (maleBird.gender != BirdGender.male ||
        femaleBird.gender != BirdGender.female) {
      throw const _ImportValidationException('birds.not_found');
    }
    if (maleBird.species != femaleBird.species) {
      throw const _ImportValidationException('breeding.same_species_required');
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Imports birds from an Excel file.
  ///
  /// Expected columns: Ad, Halka No, Cinsiyet, Tur, Durum,
  /// Dogum Tarihi, Renk, Kafes, Notlar
  Future<ImportResult> importBirdsFromExcel({
    required Uint8List bytes,
    required String userId,
    int? maxTotalBirds,
  }) async {
    // Single bulk load: existing birds plus, as the sheet is walked, every
    // row validated so far are kept in the same map — this retires
    // per-row getById and still lets a later row reference an earlier
    // row's bird as its parent (the old sequential-save behavior).
    final existing = await _birdRepo.getAll(userId);
    final birdsById = {for (final b in existing) b.id: b};
    final existingBirdCount = existing.length;
    var importedBirds = 0;

    return _importSheet(
      bytes: bytes,
      userId: userId,
      sheetNames: const ['Kuslar', 'Birds', 'Sheet1'],
      label: 'Birds',
      sheetNotFoundError: 'import.sheet_not_found'.tr(),
      parseRow: (row, uid) => ExcelRowParsers.parseBirdRow(row, uid),
      onSkip: (_, rowIndex) => 'import.row_name_empty'.tr(args: ['$rowIndex']),
      onError: (error, rowIndex) {
        if (error is _ImportValidationException) {
          return error.messageKey.tr();
        }
        if (error is _BirdLimitExceededException) {
          return 'premium.bird_limit_reached'.tr(args: ['${error.maxBirds}']);
        }
        return 'import.row_error'.tr(args: ['$rowIndex', '$error']);
      },
      validate: (bird) async {
        if (maxTotalBirds != null &&
            existingBirdCount + importedBirds >= maxTotalBirds) {
          throw _BirdLimitExceededException(maxTotalBirds);
        }
        final sanitized = _sanitizeBirdParents(bird, birdsById);
        birdsById[sanitized.id] = sanitized; // same-file forward references
        importedBirds++;
        return sanitized;
      },
      saveAll: _birdRepo.saveAll,
    );
  }

  /// Imports breeding pairs from an Excel file.
  ///
  /// Expected columns: Erkek ID (0), Disi ID (1), Kafes (2), Durum (3),
  /// Eslestirme (4), Ayrilma (5), Notlar (6)
  Future<ImportResult> importBreedingPairsFromExcel({
    required Uint8List bytes,
    required String userId,
    int? maxActivePairs,
  }) async {
    // Single bulk load of birds for FK validation (needed regardless of
    // the limit, same as importBirdsFromExcel).
    final birds = await _birdRepo.getAll(userId);
    final birdsById = {for (final b in birds) b.id: b};

    var existingActivePairs = 0;
    var importedActivePairs = 0;
    if (maxActivePairs != null) {
      final existing = await _breedingPairRepo.getAll(userId);
      existingActivePairs = existing
          .where((pair) => pair.status == BreedingStatus.active)
          .length;
    }

    return _importSheet(
      bytes: bytes,
      userId: userId,
      sheetNames: const ['Ureme Ciftleri', 'Breeding Pairs', 'Sheet2'],
      label: 'Breeding pairs',
      parseRow: (row, uid) => ExcelRowParsers.parseBreedingPairRow(row, uid),
      onError: (error, rowIndex) {
        if (error is _ImportValidationException) {
          return error.messageKey.tr();
        }
        if (error is _BreedingPairLimitExceededException) {
          return 'premium.breeding_limit_reached'.tr(
            args: ['${error.maxPairs}'],
          );
        }
        return 'import.row_error'.tr(args: ['$rowIndex', '$error']);
      },
      validate: (pair) async {
        final isActive = pair.status == BreedingStatus.active;
        if (maxActivePairs != null &&
            isActive &&
            existingActivePairs + importedActivePairs >= maxActivePairs) {
          throw _BreedingPairLimitExceededException(maxActivePairs);
        }
        _validateBreedingPairBirds(pair, birdsById);
        if (isActive) importedActivePairs++;
        return pair;
      },
      saveAll: _breedingPairRepo.saveAll,
    );
  }

  /// Imports eggs from an Excel file.
  ///
  /// Expected columns: No (0), Yumurtlama (1), Durum (2), Doller (3),
  /// Cikim (4), Kulucka ID (5), Notlar (6)
  Future<ImportResult> importEggsFromExcel({
    required Uint8List bytes,
    required String userId,
  }) async {
    return _importSheet(
      bytes: bytes,
      userId: userId,
      sheetNames: const ['Yumurtalar', 'Eggs', 'Sheet3'],
      label: 'Eggs',
      parseRow: (row, uid) => ExcelRowParsers.parseEggRow(row, uid),
      onSkip: (_, rowIndex) =>
          'import.row_date_required'.tr(args: ['$rowIndex']),
      validate: (item) async => item,
      saveAll: _eggRepo.saveAll,
    );
  }

  /// Imports chicks from an Excel file.
  ///
  /// Expected columns: Ad (0), Halka (1), Cinsiyet (2), Saglik (3),
  /// Cikim (4), Suten Kesme (5), Cikim Agirligi (6), Notlar (7)
  Future<ImportResult> importChicksFromExcel({
    required Uint8List bytes,
    required String userId,
  }) async {
    return _importSheet(
      bytes: bytes,
      userId: userId,
      sheetNames: const ['Yavrular', 'Chicks', 'Sheet4'],
      label: 'Chicks',
      parseRow: (row, uid) => ExcelRowParsers.parseChickRow(row, uid),
      validate: (item) async => item,
      saveAll: _chickRepo.saveAll,
    );
  }

  /// Imports health records from an Excel file.
  ///
  /// Expected columns: Baslik (0), Tur (1), Tarih (2), Kus ID (3),
  /// Aciklama (4), Tedavi (5), Veteriner (6), Notlar (7)
  Future<ImportResult> importHealthRecordsFromExcel({
    required Uint8List bytes,
    required String userId,
  }) async {
    return _importSheet(
      bytes: bytes,
      userId: userId,
      sheetNames: const ['Saglik', 'Health Records', 'Sheet5'],
      label: 'Health records',
      parseRow: (row, uid) => ExcelRowParsers.parseHealthRecordRow(row, uid),
      onSkip: (row, rowIndex) {
        final title = cellToString(row, 0);
        if (title == null || title.isEmpty) {
          return 'import.row_title_required'.tr(args: ['$rowIndex']);
        }
        return 'import.row_date_required'.tr(args: ['$rowIndex']);
      },
      validate: (item) async => item,
      saveAll: _healthRecordRepo.saveAll,
    );
  }

  /// Imports all supported entity types from a single Excel file.
  ///
  /// Returns a map of entity type name to [ImportResult].
  Future<Map<String, ImportResult>> importAllFromExcel({
    required Uint8List bytes,
    required String userId,
    int? maxTotalBirds,
    int? maxActiveBreedingPairs,
  }) async {
    return {
      'birds': await importBirdsFromExcel(
        bytes: bytes,
        userId: userId,
        maxTotalBirds: maxTotalBirds,
      ),
      'breeding_pairs': await importBreedingPairsFromExcel(
        bytes: bytes,
        userId: userId,
        maxActivePairs: maxActiveBreedingPairs,
      ),
      'eggs': await importEggsFromExcel(bytes: bytes, userId: userId),
      'chicks': await importChicksFromExcel(bytes: bytes, userId: userId),
      'health_records': await importHealthRecordsFromExcel(
        bytes: bytes,
        userId: userId,
      ),
    };
  }
}
