import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/import/excel_import_helpers.dart';
import 'package:budgie_breeding_tracker/domain/services/import/excel_row_parsers.dart';
import 'package:budgie_breeding_tracker/domain/services/import/import_result.dart';

/// Imports data from Excel files into the local database.
///
/// Supports importing bird, breeding pair, egg, chick, and health record
/// data from Excel workbooks that follow the same format as the exported files.
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
    var existingBirdCount = 0;
    var importedBirds = 0;
    if (maxTotalBirds != null) {
      existingBirdCount = (await _birdRepo.getAll(userId)).length;
    }

    return _importSheet(
      bytes: bytes,
      userId: userId,
      sheetNames: const ['Kuslar', 'Birds', 'Sheet1'],
      label: 'Birds',
      sheetNotFoundError: 'import.sheet_not_found'.tr(),
      parseRow: (row, uid) => ExcelRowParsers.parseBirdRow(row, uid),
      onSkip: (_, rowIndex) =>
          'import.row_name_empty'.tr(args: ['$rowIndex']),
      onError: (error, rowIndex) {
        if (error is _BirdLimitExceededException) {
          return 'premium.bird_limit_reached'
              .tr(args: ['${error.maxBirds}']);
        }
        return 'import.row_error'.tr(args: ['$rowIndex', '$error']);
      },
      save: (bird) async {
        if (maxTotalBirds != null &&
            existingBirdCount + importedBirds >= maxTotalBirds) {
          throw _BirdLimitExceededException(maxTotalBirds);
        }
        await _birdRepo.save(bird);
        importedBirds++;
      },
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
        if (error is _BreedingPairLimitExceededException) {
          return 'premium.breeding_limit_reached'
              .tr(args: ['${error.maxPairs}']);
        }
        return 'import.row_error'.tr(args: ['$rowIndex', '$error']);
      },
      save: (pair) async {
        final isActive = pair.status == BreedingStatus.active;
        if (maxActivePairs != null &&
            isActive &&
            existingActivePairs + importedActivePairs >= maxActivePairs) {
          throw _BreedingPairLimitExceededException(maxActivePairs);
        }
        await _breedingPairRepo.save(pair);
        if (isActive) importedActivePairs++;
      },
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
      save: (egg) => _eggRepo.save(egg),
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
      save: (chick) => _chickRepo.save(chick),
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
      save: (record) => _healthRecordRepo.save(record),
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

  // ---------------------------------------------------------------------------
  // Generic import orchestration
  // ---------------------------------------------------------------------------

  /// Decodes [bytes] into an Excel workbook, locates a sheet by
  /// [sheetNames], iterates its data rows and delegates parsing/saving
  /// to the provided callbacks.
  ///
  /// [parseRow] returns `null` when the row should be skipped.
  /// [onSkip] (optional) produces the error message for skipped rows.
  /// [onError] (optional) customizes the error message for thrown row errors.
  /// [sheetNotFoundError] (optional) is added to errors when the sheet
  /// is missing; when `null` the result is returned with an empty error list.
  Future<ImportResult> _importSheet<T>({
    required Uint8List bytes,
    required String userId,
    required List<String> sheetNames,
    required String label,
    required T? Function(List<Data?> row, String userId) parseRow,
    required Future<void> Function(T item) save,
    String Function(List<Data?> row, int rowIndex)? onSkip,
    String Function(Object error, int rowIndex)? onError,
    String? sheetNotFoundError,
  }) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = findSheet(excel, sheetNames);

    if (sheet == null) {
      return ImportResult(
        totalRows: 0,
        importedCount: 0,
        skippedCount: 0,
        errors: sheetNotFoundError != null ? [sheetNotFoundError] : const [],
      );
    }

    final rows = sheet.rows;
    if (rows.length <= 1) {
      return ImportResult(
        totalRows: 0,
        importedCount: 0,
        skippedCount: 0,
        errors: ['import.no_data_rows'.tr()],
      );
    }

    final errors = <String>[];
    var imported = 0;
    var skipped = 0;
    var totalRows = 0;

    for (var i = 1; i < rows.length; i++) {
      totalRows++;
      try {
        final item = parseRow(rows[i], userId);
        if (item == null) {
          skipped++;
          if (onSkip != null) {
            errors.add(onSkip(rows[i], i + 1));
          }
          continue;
        }
        await save(item);
        imported++;
      } catch (e) {
        AppLogger.warning('[DataImportService] Row ${i + 1}: $e');
        skipped++;
        errors.add(
          onError != null
              ? onError(e, i + 1)
              : 'import.row_error'.tr(args: ['${i + 1}', '$e']),
        );
      }
    }

    AppLogger.info(
      '[DataImportService] $label import complete: $imported imported, $skipped skipped',
    );

    return ImportResult(
      totalRows: totalRows,
      importedCount: imported,
      skippedCount: skipped,
      errors: errors,
    );
  }
}

class _BirdLimitExceededException implements Exception {
  final int maxBirds;
  const _BirdLimitExceededException(this.maxBirds);
}

class _BreedingPairLimitExceededException implements Exception {
  final int maxPairs;
  const _BreedingPairLimitExceededException(this.maxPairs);
}
