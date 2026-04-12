part of 'excel_export_service.dart';

extension _ExcelSheetBuilders on ExcelExportService {
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
        ExcelExportService._dateFormat.format(e.layDate),
        e.status.name,
        e.hatchDate != null ? ExcelExportService._dateFormat.format(e.hatchDate!) : '',
        e.fertileCheckDate != null
            ? ExcelExportService._dateFormat.format(e.fertileCheckDate!)
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
            ? ExcelExportService._dateFormat.format(incubation.startDate!)
            : '',
        incubation.computedExpectedHatchDate != null
            ? ExcelExportService._dateFormat.format(incubation.computedExpectedHatchDate!)
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
        c.hatchDate != null ? ExcelExportService._dateFormat.format(c.hatchDate!) : '',
        c.weanDate != null ? ExcelExportService._dateFormat.format(c.weanDate!) : '',
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
}
