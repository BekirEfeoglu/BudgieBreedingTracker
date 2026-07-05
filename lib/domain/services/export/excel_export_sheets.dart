part of 'excel_export_service.dart';

extension _ExcelSheetBuilders on ExcelExportService {
  void _addEggsSheet(Excel excel, List<Egg> eggs) {
    final sheet = excel['export.sheet_eggs'.tr()];
    final headerStyle = CellStyle(bold: true);

    // Column order matches DataImportService's egg parser (no@0, lay@1,
    // status@2, fertile@3, hatch@4, incubationId@5, notes@6) with the full egg
    // id trailing at col 7, so re-import is a lossless round-trip (the
    // incubation link is now exported too, and the id preserved).
    final headers = [
      'export.header_no'.tr(),
      'export.header_lay_date'.tr(),
      'export.header_status'.tr(),
      'export.header_fertile_check'.tr(),
      'export.header_hatch_date'.tr(),
      'export.header_incubation_id'.tr(),
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

    for (var row = 0; row < eggs.length; row++) {
      final e = eggs[row];
      final values = [
        '${e.eggNumber ?? ""}',
        ExcelExportService._dateFormat.format(e.layDate),
        e.status.name,
        e.fertileCheckDate != null
            ? ExcelExportService._dateFormat.format(e.fertileCheckDate!)
            : '',
        e.hatchDate != null
            ? ExcelExportService._dateFormat.format(e.hatchDate!)
            : '',
        e.incubationId ?? '',
        e.notes ?? '',
        e.id,
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

    // Column order matches DataImportService's incubation parser (id@0,
    // breedingPairId@1, species@2, status@3, startDate@4, expectedHatch@5,
    // totalDays@6, notes@7). The id is written in FULL (not truncated) so an
    // egg's incubationId FK resolves back to this row on re-import — a lossless
    // round-trip. species/status are written as stable enum NAMES the parser
    // accepts regardless of locale. totalDays@6 is a derived display column the
    // parser ignores.
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
        incubation.id,
        incubation.breedingPairId ?? '',
        incubation.species.name,
        incubation.status.name,
        incubation.startDate != null
            ? ExcelExportService._dateFormat.format(incubation.startDate!)
            : '',
        incubation.computedExpectedHatchDate != null
            ? ExcelExportService._dateFormat.format(
                incubation.computedExpectedHatchDate!,
              )
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

    // Column order already matches the chick parser (name@0 … notes@7); gender
    // is written as an enum NAME (not a localized label) and the full id trails
    // at col 8 so re-import round-trips losslessly.
    final headers = [
      'export.header_name'.tr(),
      'export.header_ring_number'.tr(),
      'export.header_gender'.tr(),
      'export.header_health'.tr(),
      'export.header_hatch_date'.tr(),
      'export.header_weaning'.tr(),
      'export.header_hatch_weight'.tr(),
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

    for (var row = 0; row < chicks.length; row++) {
      final c = chicks[row];
      final values = [
        c.name ?? '',
        c.ringNumber ?? '',
        c.gender.name,
        c.healthStatus.name,
        c.hatchDate != null
            ? ExcelExportService._dateFormat.format(c.hatchDate!)
            : '',
        c.weanDate != null
            ? ExcelExportService._dateFormat.format(c.weanDate!)
            : '',
        c.hatchWeight != null ? c.hatchWeight.toString() : '',
        c.notes ?? '',
        c.id,
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

  void _addHealthRecordsSheet(Excel excel, List<HealthRecord> records) {
    final sheet = excel['export.sheet_health'.tr()];
    final headerStyle = CellStyle(bold: true);

    // Column order matches DataImportService's health parser (title@0, type@1,
    // date@2, birdId@3, description@4, treatment@5, veterinarian@6, notes@7)
    // with the full id trailing at col 8, so re-import is a lossless round-trip.
    // type is written as a stable enum NAME the parser accepts regardless of
    // locale.
    final headers = [
      'export.header_title'.tr(),
      'export.header_type'.tr(),
      'export.header_date'.tr(),
      'export.header_bird_id'.tr(),
      'export.header_description'.tr(),
      'export.header_treatment'.tr(),
      'export.header_veterinarian'.tr(),
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

    for (var row = 0; row < records.length; row++) {
      final r = records[row];
      final values = [
        r.title,
        r.type.name,
        ExcelExportService._dateFormat.format(r.date),
        r.birdId ?? '',
        r.description ?? '',
        r.treatment ?? '',
        r.veterinarian ?? '',
        r.notes ?? '',
        r.id,
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
