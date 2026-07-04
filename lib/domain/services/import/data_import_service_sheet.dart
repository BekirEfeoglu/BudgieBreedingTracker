part of 'data_import_service.dart';

// ---------------------------------------------------------------------------
// Generic sheet import orchestration & limit exceptions
// ---------------------------------------------------------------------------

/// Decodes [bytes] into an Excel workbook, locates a sheet by
/// [sheetNames], iterates its data rows and delegates parsing/saving
/// to the provided callbacks.
///
/// [parseRow] returns `null` when the row should be skipped.
/// [validate] validates and may return a SANITIZED copy of the item to persist
/// (e.g. a bird with an unresolvable parent link nulled out); throw to skip the
/// row. The returned item — not the raw parsed one — is what gets saved.
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
  required Future<T> Function(T item) validate,
  required Future<void> Function(List<T> items) saveAll,
  String Function(List<Data?> row, int rowIndex)? onSkip,
  String Function(Object error, int rowIndex)? onError,
  String? sheetNotFoundError,
}) async {
  // Reject files larger than 20 MB to prevent memory exhaustion
  const maxImportFileSize = 20 * 1024 * 1024; // 20 MB
  if (bytes.length > maxImportFileSize) {
    return ImportResult(
      totalRows: 0,
      importedCount: 0,
      skippedCount: 0,
      errors: ['import.file_too_large'.tr()],
    );
  }

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
  final validItems = <T>[];

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
      final prepared = await validate(item);
      validItems.add(prepared);
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

  if (validItems.isNotEmpty) {
    try {
      await saveAll(validItems);
    } catch (e, st) {
      // Batch persist failed as a whole (transactional insertAll) — report
      // a sheet-level error instead of pretending rows were imported.
      AppLogger.error('[DataImportService] $label batch save failed', e, st);
      return ImportResult(
        totalRows: totalRows,
        importedCount: 0,
        skippedCount: skipped,
        errors: [
          ...errors,
          'import.row_error'.tr(args: ['-', '$e']),
        ],
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

class _BirdLimitExceededException implements Exception {
  final int maxBirds;
  const _BirdLimitExceededException(this.maxBirds);
}

class _BreedingPairLimitExceededException implements Exception {
  final int maxPairs;
  const _BreedingPairLimitExceededException(this.maxPairs);
}

class _ImportValidationException implements Exception {
  final String messageKey;
  const _ImportValidationException(this.messageKey);
}
