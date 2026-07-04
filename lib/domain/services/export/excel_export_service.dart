import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../data/models/bird_model.dart';
import '../../../data/models/breeding_pair_model.dart';
import '../../../data/models/chick_model.dart';
import '../../../data/models/egg_model.dart';
import '../../../data/models/incubation_model.dart';

part 'excel_export_sheets.dart';

/// Generates Excel workbooks with separate sheets for each entity type.
class ExcelExportService {
  ExcelExportService();

  static final _dateFormat = DateFormat('dd.MM.yyyy');

  /// Exports all data to a single Excel workbook.
  Future<Uint8List> exportAll({
    required List<Bird> birds,
    required List<BreedingPair> pairs,
    required List<Incubation> incubations,
    required List<Egg> eggs,
    required List<Chick> chicks,
  }) async {
    final excel = Excel.createExcel();

    _addBirdsSheet(excel, birds);
    _addBreedingSheet(excel, pairs);
    _addIncubationsSheet(excel, incubations);
    _addEggsSheet(excel, eggs);
    _addChicksSheet(excel, chicks);

    // Remove default Sheet1
    excel.delete('Sheet1');

    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('export.error_excel_create'.tr());
    }
    return Uint8List.fromList(bytes);
  }

  /// Exports birds only.
  Future<Uint8List> exportBirds(List<Bird> birds) async {
    final excel = Excel.createExcel();
    _addBirdsSheet(excel, birds);
    excel.delete('Sheet1');
    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('export.error_excel_create'.tr());
    }
    return Uint8List.fromList(bytes);
  }

  void _addBirdsSheet(Excel excel, List<Bird> birds) {
    final sheet = excel['export.sheet_birds'.tr()];
    final headerStyle = CellStyle(bold: true);

    // Column order matches DataImportService's bird parser (species@3,
    // status@4, cage@7, father@9, mother@10, notes@11) so a re-import is a
    // lossless round-trip. Columns 6 ("Renk") and 8 are legacy positions the
    // parser skips — kept empty so the father/mother/notes indices line up.
    // The trailing ID (12) / death (13) / sale (14) columns carry the full
    // (untruncated) id and the extra dates the parser reads to reconstruct the
    // bird exactly (see excel_row_parsers.parseBirdRow).
    final headers = [
      'export.header_name'.tr(),
      'export.header_ring_number'.tr(),
      'export.header_gender'.tr(),
      'export.header_species'.tr(),
      'export.header_status'.tr(),
      'export.header_birth_date'.tr(),
      'export.header_color'.tr(),
      'export.header_cage'.tr(),
      'export.header_notes'.tr(),
      'export.header_father_id'.tr(),
      'export.header_mother_id'.tr(),
      'export.header_notes'.tr(),
      'export.header_id'.tr(),
      'export.header_death_date'.tr(),
      'export.header_sale_date'.tr(),
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var row = 0; row < birds.length; row++) {
      final b = birds[row];
      // Enum-backed fields (gender/species/status) are written as stable enum
      // NAMES, not localized labels, so re-import parses them back exactly
      // regardless of locale — the import's parseGender/parseSpecies/
      // parseBirdStatus accept these tokens. (species was already exported this
      // way; gender/status now match for a lossless round-trip.)
      final values = [
        b.name,
        b.ringNumber ?? '',
        b.gender.name,
        b.species.name,
        b.status.name,
        b.birthDate != null ? _dateFormat.format(b.birthDate!) : '',
        '', // col 6 (Renk) — legacy, parser skips
        b.cageNumber ?? '',
        '', // col 8 — legacy notes slot, parser reads notes from col 11
        b.fatherId ?? '',
        b.motherId ?? '',
        b.notes ?? '',
        b.id,
        b.deathDate != null ? _dateFormat.format(b.deathDate!) : '',
        b.soldDate != null ? _dateFormat.format(b.soldDate!) : '',
      ];
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
            )
            .value = TextCellValue(
          sanitize(values[col]),
        );
      }
    }
  }

  void _addBreedingSheet(Excel excel, List<BreedingPair> pairs) {
    final sheet = excel['export.sheet_breeding'.tr()];
    final headerStyle = CellStyle(bold: true);

    // Column order matches DataImportService's pair parser (maleId@0,
    // femaleId@1, cage@2, status@3, pairing@4, separation@5, notes@6) with the
    // full pair id trailing at col 7, so re-import is a lossless round-trip.
    final headers = [
      'export.header_male_id'.tr(),
      'export.header_female_id'.tr(),
      'export.header_cage'.tr(),
      'export.header_status'.tr(),
      'export.header_pairing_date'.tr(),
      'export.header_separation_date'.tr(),
      'export.header_notes'.tr(),
      'export.header_id'.tr(),
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var row = 0; row < pairs.length; row++) {
      final p = pairs[row];
      final values = [
        p.maleId ?? '',
        p.femaleId ?? '',
        p.cageNumber ?? '',
        p.status.name,
        p.pairingDate != null ? _dateFormat.format(p.pairingDate!) : '',
        p.separationDate != null ? _dateFormat.format(p.separationDate!) : '',
        p.notes ?? '',
        p.id,
      ];
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
            )
            .value = TextCellValue(
          sanitize(values[col]),
        );
      }
    }
  }

  /// Prevents formula injection by prefixing dangerous characters.
  /// Allows negative numbers (e.g. "-5.2") to pass through unmodified.
  @visibleForTesting
  String sanitize(String value) {
    if (value.isEmpty) return value;
    final first = value[0];
    if (first == '-' &&
        value.length > 1 &&
        _isDigitOrDot(value.codeUnitAt(1))) {
      return value;
    }
    if (first == '=' ||
        first == '+' ||
        first == '-' ||
        first == '@' ||
        first == '|' ||
        first == '\t' ||
        first == '\r' ||
        first == '\n') {
      return "'$value";
    }
    return value;
  }

  static bool _isDigitOrDot(int codeUnit) =>
      (codeUnit >= 0x30 && codeUnit <= 0x39) || codeUnit == 0x2E;
}
