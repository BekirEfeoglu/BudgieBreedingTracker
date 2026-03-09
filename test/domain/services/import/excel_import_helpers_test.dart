import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/domain/services/import/excel_import_helpers.dart';

void main() {
  group('findSheet', () {
    test('returns first matching sheet by preferred names', () {
      final excel = Excel.createExcel();
      final birdsSheet = excel['Birds'];

      final result = findSheet(excel, const ['Kuslar', 'Birds', 'Voegel']);
      expect(result, same(birdsSheet));
    });

    test('returns null when no candidate sheet exists', () {
      final excel = Excel.createExcel();
      expect(findSheet(excel, const ['Missing']), isNull);
    });
  });

  group('cellToString', () {
    test('returns cell string and null for out-of-range index', () {
      final excel = Excel.createExcel();
      final sheet = excel['Data'];
      sheet.appendRow([TextCellValue('alpha')]);
      final row = sheet.rows.first;

      expect(cellToString(row, 0), 'alpha');
      expect(cellToString(row, 99), isNull);
    });
  });

  group('parseDate', () {
    test('supports dd.MM.yyyy and ISO values', () {
      final localDate = parseDate('26.02.2026');
      final isoDate = parseDate('2026-02-26T12:30:00.000Z');

      expect(localDate, DateTime(2026, 2, 26));
      expect(isoDate, isNotNull);
      expect(isoDate!.toUtc().year, 2026);
    });

    test('returns null for empty or invalid dates', () {
      expect(parseDate(null), isNull);
      expect(parseDate(''), isNull);
      expect(parseDate('not-a-date'), isNull);
    });
  });

  group('enum parsers', () {
    test('parseGender handles localized values and fallback', () {
      expect(parseGender('erkek'), BirdGender.male);
      expect(parseGender('female'), BirdGender.female);
      expect(parseGender('unknown-value'), BirdGender.unknown);
    });

    test('parseBreedingStatus maps known values', () {
      expect(parseBreedingStatus('aktiv'), BreedingStatus.active);
      expect(parseBreedingStatus('ongoing'), BreedingStatus.ongoing);
      expect(parseBreedingStatus('completed'), BreedingStatus.completed);
      expect(parseBreedingStatus('abgebrochen'), BreedingStatus.cancelled);
      expect(parseBreedingStatus('invalid'), BreedingStatus.active);
    });

    test('parseEggStatus maps known values and defaults to laid', () {
      expect(parseEggStatus('incubating'), EggStatus.incubating);
      expect(parseEggStatus('hatched'), EggStatus.hatched);
      expect(parseEggStatus('beschaedigt'), EggStatus.damaged);
      expect(parseEggStatus('invalid'), EggStatus.laid);
    });

    test('parseHealthStatus maps known values and unknown fallback', () {
      expect(parseHealthStatus('healthy'), ChickHealthStatus.healthy);
      expect(parseHealthStatus('krank'), ChickHealthStatus.sick);
      expect(parseHealthStatus('deceased'), ChickHealthStatus.deceased);
      expect(parseHealthStatus('invalid'), ChickHealthStatus.unknown);
    });

    test('parseHealthRecordType maps known values and unknown fallback', () {
      expect(parseHealthRecordType('checkup'), HealthRecordType.checkup);
      expect(parseHealthRecordType('injury'), HealthRecordType.injury);
      expect(parseHealthRecordType('medikation'), HealthRecordType.medication);
      expect(parseHealthRecordType('invalid'), HealthRecordType.unknown);
    });
  });
}
