import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/export/excel_export_service.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late ExcelExportService service;

  setUp(() {
    service = ExcelExportService();
  });

  group('ExcelExportService', () {
    test('exportAll creates workbook with all entity sheets', () async {
      final birds = [
        createTestBird(id: 'bird-0001', name: 'Mavi', gender: BirdGender.male),
      ];
      final pairs = [
        const BreedingPair(
          id: 'pair-0001',
          userId: 'u1',
          maleId: 'bird-0001',
          femaleId: 'bird-0002',
        ),
      ];
      final eggs = [
        Egg(
          id: 'egg-0001',
          userId: 'u1',
          layDate: DateTime(2026, 1, 1),
          status: EggStatus.laid,
          eggNumber: 1,
        ),
      ];
      final incubations = [
        Incubation(
          id: 'inc-0001',
          userId: 'u1',
          breedingPairId: 'pair-0001',
          species: Species.canary,
          status: IncubationStatus.active,
          startDate: DateTime(2026, 1, 1),
        ),
      ];
      final chicks = [const Chick(id: 'c1', userId: 'u1', name: 'Chick 1')];

      final bytes = await service.exportAll(
        birds: birds,
        pairs: pairs,
        incubations: incubations,
        eggs: eggs,
        chicks: chicks,
      );

      final workbook = Excel.decodeBytes(Uint8List.fromList(bytes));
      expect(workbook.tables.containsKey('export.sheet_birds'), isTrue);
      expect(workbook.tables.containsKey('export.sheet_breeding'), isTrue);
      expect(workbook.tables.containsKey('export.sheet_incubations'), isTrue);
      expect(workbook.tables.containsKey('export.sheet_eggs'), isTrue);
      expect(workbook.tables.containsKey('export.sheet_chicks'), isTrue);

      final breedingSheet = workbook.tables['export.sheet_breeding']!;
      // header + 1 row
      expect(breedingSheet.rows.length, 2);
      expect(breedingSheet.rows[1][1]?.value.toString(), 'bird-0001');
      expect(breedingSheet.rows[1][2]?.value.toString(), 'bird-0002');

      final incubationSheet = workbook.tables['export.sheet_incubations']!;
      expect(incubationSheet.rows.length, 2);
      expect(incubationSheet.rows[1][1]?.value.toString(), 'pair-0001');
      expect(incubationSheet.rows[1][2]?.value.toString(), 'canary');
    });

    test('exportBirds creates workbook containing only bird sheet', () async {
      final bytes = await service.exportBirds([
        createTestBird(id: 'b1', name: 'Mavi'),
      ]);

      final workbook = Excel.decodeBytes(Uint8List.fromList(bytes));
      expect(workbook.tables.containsKey('export.sheet_birds'), isTrue);
      expect(workbook.tables.length, 1);

      final sheet = workbook.tables['export.sheet_birds']!;
      // header + one data row
      expect(sheet.rows.length, 2);
      expect(sheet.rows[1][0]?.value.toString(), 'Mavi');
    });

    test('exportAll handles empty data sets with header-only sheets', () async {
      final bytes = await service.exportAll(
        birds: const [],
        pairs: const [],
        incubations: const [],
        eggs: const [],
        chicks: const [],
      );

      final workbook = Excel.decodeBytes(Uint8List.fromList(bytes));
      expect(
        workbook.tables.keys,
        containsAll([
          'export.sheet_birds',
          'export.sheet_breeding',
          'export.sheet_incubations',
          'export.sheet_eggs',
          'export.sheet_chicks',
        ]),
      );

      for (final table in workbook.tables.values) {
        expect(table.rows.length, 1);
      }
    });
  });
}
