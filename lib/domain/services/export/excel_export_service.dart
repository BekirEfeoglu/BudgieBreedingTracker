import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../data/models/bird_model.dart';
import '../../../data/models/breeding_pair_model.dart';
import '../../../data/models/chick_model.dart';
import '../../../data/models/egg_model.dart';
import '../../../data/models/incubation_model.dart';

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
    return Uint8List.fromList(bytes!);
  }

  /// Exports birds only.
  Future<Uint8List> exportBirds(List<Bird> birds) async {
    final excel = Excel.createExcel();
    _addBirdsSheet(excel, birds);
    excel.delete('Sheet1');
    final bytes = excel.save();
    return Uint8List.fromList(bytes!);
  }

  void _addBirdsSheet(Excel excel, List<Bird> birds) {
    final sheet = excel['export.sheet_birds'.tr()];
    final headerStyle = CellStyle(bold: true);

    final headers = [
      'export.header_name'.tr(),
      'export.header_ring_number'.tr(),
      'export.header_gender'.tr(),
      'export.header_status'.tr(),
      'export.header_species'.tr(),
      'export.header_cage'.tr(),
      'export.header_birth_date'.tr(),
      'export.header_death_date'.tr(),
      'export.header_sale_date'.tr(),
      'export.header_father_id'.tr(),
      'export.header_mother_id'.tr(),
      'export.header_notes'.tr(),
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
      final values = [
        b.name,
        b.ringNumber ?? '',
        _genderLabel(b.gender.name),
        _statusLabel(b.status.name),
        b.species.name,
        b.cageNumber ?? '',
        b.birthDate != null ? _dateFormat.format(b.birthDate!) : '',
        b.deathDate != null ? _dateFormat.format(b.deathDate!) : '',
        b.soldDate != null ? _dateFormat.format(b.soldDate!) : '',
        b.fatherId ?? '',
        b.motherId ?? '',
        b.notes ?? '',
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

    final headers = [
      'export.header_id'.tr(),
      'export.header_male_id'.tr(),
      'export.header_female_id'.tr(),
      'export.header_cage'.tr(),
      'export.header_status'.tr(),
      'export.header_pairing_date'.tr(),
      'export.header_separation_date'.tr(),
      'export.header_notes'.tr(),
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
        p.id.substring(0, 8),
        p.maleId ?? '',
        p.femaleId ?? '',
        p.cageNumber ?? '',
        p.status.name,
        p.pairingDate != null ? _dateFormat.format(p.pairingDate!) : '',
        p.separationDate != null ? _dateFormat.format(p.separationDate!) : '',
        p.notes ?? '',
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

  void _addEggsSheet(Excel excel, List<Egg> eggs) {
    final sheet = excel['export.sheet_eggs'.tr()];
    final headerStyle = CellStyle(bold: true);

    final headers = [
      'export.header_id'.tr(),
      'export.header_no'.tr(),
      'export.header_lay_date'.tr(),
      'export.header_status'.tr(),
      'export.header_hatch_date'.tr(),
      'export.header_fertile_check'.tr(),
      'export.header_notes'.tr(),
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var row = 0; row < eggs.length; row++) {
      final e = eggs[row];
      final values = [
        e.id.substring(0, 8),
        '${e.eggNumber ?? ""}',
        _dateFormat.format(e.layDate),
        e.status.name,
        e.hatchDate != null ? _dateFormat.format(e.hatchDate!) : '',
        e.fertileCheckDate != null
            ? _dateFormat.format(e.fertileCheckDate!)
            : '',
        e.notes ?? '',
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

  void _addIncubationsSheet(Excel excel, List<Incubation> incubations) {
    final sheet = excel['export.sheet_incubations'.tr()];
    final headerStyle = CellStyle(bold: true);

    final headers = [
      'export.header_id'.tr(),
      'export.header_breeding_pair_id'.tr(),
      'export.header_species'.tr(),
      'export.header_status'.tr(),
      'export.header_start_date'.tr(),
      'export.header_expected_hatch_date'.tr(),
      'export.header_total_days'.tr(),
      'export.header_notes'.tr(),
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var row = 0; row < incubations.length; row++) {
      final incubation = incubations[row];
      final values = [
        incubation.id.substring(0, 8),
        incubation.breedingPairId ?? '',
        incubation.species.name,
        incubation.status.name,
        incubation.startDate != null
            ? _dateFormat.format(incubation.startDate!)
            : '',
        incubation.computedExpectedHatchDate != null
            ? _dateFormat.format(incubation.computedExpectedHatchDate!)
            : '',
        incubation.totalIncubationDays().toString(),
        incubation.notes ?? '',
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

  void _addChicksSheet(Excel excel, List<Chick> chicks) {
    final sheet = excel['export.sheet_chicks'.tr()];
    final headerStyle = CellStyle(bold: true);

    final headers = [
      'export.header_name'.tr(),
      'export.header_ring_number'.tr(),
      'export.header_gender'.tr(),
      'export.header_health'.tr(),
      'export.header_hatch_date'.tr(),
      'export.header_weaning'.tr(),
      'export.header_hatch_weight'.tr(),
      'export.header_notes'.tr(),
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (var row = 0; row < chicks.length; row++) {
      final c = chicks[row];
      final values = [
        c.name ?? '',
        c.ringNumber ?? '',
        _genderLabel(c.gender.name),
        c.healthStatus.name,
        c.hatchDate != null ? _dateFormat.format(c.hatchDate!) : '',
        c.weanDate != null ? _dateFormat.format(c.weanDate!) : '',
        c.hatchWeight != null ? c.hatchWeight.toString() : '',
        c.notes ?? '',
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
    if (first == '-' && value.length > 1 && _isDigitOrDot(value.codeUnitAt(1))) {
      return value;
    }
    if (first == '=' || first == '+' || first == '-' || first == '@' ||
        first == '|' || first == '\t' || first == '\r' || first == '\n') {
      return "'$value";
    }
    return value;
  }

  static bool _isDigitOrDot(int codeUnit) =>
      (codeUnit >= 0x30 && codeUnit <= 0x39) || codeUnit == 0x2E;

  String _genderLabel(String name) => switch (name) {
    'male' => 'export.gender_male'.tr(),
    'female' => 'export.gender_female'.tr(),
    _ => 'export.gender_unknown'.tr(),
  };

  String _statusLabel(String name) => switch (name) {
    'alive' => 'export.status_alive'.tr(),
    'dead' => 'export.status_dead'.tr(),
    'sold' => 'export.status_sold'.tr(),
    _ => name,
  };
}
