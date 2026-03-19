import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/domain/services/import/excel_row_parsers.dart';

const _userId = 'test-user-id';

/// Builds a row of [Data?] from a list of string values.
///
/// Null entries in [values] produce null cells; non-null entries produce
/// [TextCellValue] cells. An empty list returns an empty row.
List<Data?> _buildRow(List<String?> values) {
  if (values.isEmpty) return <Data?>[];
  final excel = Excel.createExcel();
  final sheet = excel['Test'];
  sheet.appendRow(
    values.map((v) => v != null ? TextCellValue(v) : null).toList(),
  );
  return sheet.rows.first;
}

void main() {
  // ---------------------------------------------------------------------------
  // parseBirdRow
  // ---------------------------------------------------------------------------
  group('parseBirdRow', () {
    test('parses a fully populated bird row', () {
      // arrange
      // Columns: Ad(0), Halka No(1), Cinsiyet(2), Tur(3), Durum(4),
      //          Dogum Tarihi(5), Renk(6), Kafes(7), Notlar(8)
      final row = _buildRow([
        'Mavis',
        'TR-001',
        'erkek',
        'budgie',
        'alive',
        '15.03.2025',
        'green',
        'A1',
        'Healthy bird',
      ]);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNotNull);
      expect(bird!.name, 'Mavis');
      expect(bird.ringNumber, 'TR-001');
      expect(bird.gender, BirdGender.male);
      expect(bird.species, Species.budgie);
      expect(bird.status, BirdStatus.alive);
      expect(bird.birthDate, DateTime(2025, 3, 15));
      expect(bird.cageNumber, 'A1');
      expect(bird.notes, 'Healthy bird');
      expect(bird.userId, _userId);
      expect(bird.id, isNotEmpty);
    });

    test('parses bird row with minimal data (name only)', () {
      // arrange
      final row = _buildRow(['Sari']);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNotNull);
      expect(bird!.name, 'Sari');
      expect(bird.ringNumber, isNull);
      expect(bird.gender, BirdGender.unknown);
      expect(bird.birthDate, isNull);
      expect(bird.cageNumber, isNull);
      expect(bird.notes, isNull);
    });

    test('returns null when name cell is null', () {
      // arrange
      final row = _buildRow([null, 'TR-002', 'female']);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNull);
    });

    test('returns null when name cell is empty string', () {
      // arrange
      final row = _buildRow(['', 'TR-003', 'male']);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNull);
    });

    test('returns null when row is completely empty', () {
      // arrange
      final row = _buildRow([null, null, null]);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNull);
    });

    test('parses female gender correctly', () {
      // arrange
      final row = _buildRow(['Disi Kus', null, 'female']);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNotNull);
      expect(bird!.gender, BirdGender.female);
    });

    test('defaults gender to unknown for invalid value', () {
      // arrange
      final row = _buildRow(['Test', null, 'invalid-gender']);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNotNull);
      expect(bird!.gender, BirdGender.unknown);
    });

    test('parses ISO 8601 date format', () {
      // arrange
      final row = _buildRow([
        'Test Bird',
        null,
        null,
        null,
        null,
        '2025-06-15',
      ]);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNotNull);
      expect(bird!.birthDate, DateTime(2025, 6, 15));
    });

    test('handles invalid date gracefully', () {
      // arrange
      final row = _buildRow([
        'Test Bird',
        null,
        null,
        null,
        null,
        'not-a-date',
      ]);

      // act
      final bird = ExcelRowParsers.parseBirdRow(row, _userId);

      // assert
      expect(bird, isNotNull);
      expect(bird!.birthDate, isNull);
    });

    test('generates unique IDs for each parsed bird', () {
      // arrange
      final row1 = _buildRow(['Bird A']);
      final row2 = _buildRow(['Bird B']);

      // act
      final bird1 = ExcelRowParsers.parseBirdRow(row1, _userId);
      final bird2 = ExcelRowParsers.parseBirdRow(row2, _userId);

      // assert
      expect(bird1!.id, isNot(bird2!.id));
    });
  });

  // ---------------------------------------------------------------------------
  // parseBreedingPairRow
  // ---------------------------------------------------------------------------
  group('parseBreedingPairRow', () {
    test('parses a fully populated breeding pair row', () {
      // arrange
      // Columns: Erkek ID(0), Disi ID(1), Kafes(2), Durum(3),
      //          Eslestirme(4), Ayrilma(5), Notlar(6)
      final row = _buildRow([
        'male-uuid',
        'female-uuid',
        'B3',
        'active',
        '01.01.2025',
        '15.06.2025',
        'Good pairing',
      ]);

      // act
      final pair = ExcelRowParsers.parseBreedingPairRow(row, _userId);

      // assert
      expect(pair.maleId, 'male-uuid');
      expect(pair.femaleId, 'female-uuid');
      expect(pair.cageNumber, 'B3');
      expect(pair.status, BreedingStatus.active);
      expect(pair.pairingDate, DateTime(2025, 1, 1));
      expect(pair.separationDate, DateTime(2025, 6, 15));
      expect(pair.notes, 'Good pairing');
      expect(pair.userId, _userId);
      expect(pair.id, isNotEmpty);
    });

    test('parses breeding pair with minimal data (all nulls)', () {
      // arrange
      final row = _buildRow([null, null, null]);

      // act
      final pair = ExcelRowParsers.parseBreedingPairRow(row, _userId);

      // assert
      expect(pair.maleId, isNull);
      expect(pair.femaleId, isNull);
      expect(pair.cageNumber, isNull);
      expect(pair.status, BreedingStatus.active);
      expect(pair.pairingDate, isNull);
      expect(pair.separationDate, isNull);
      expect(pair.notes, isNull);
    });

    test('parses completed status', () {
      // arrange
      final row = _buildRow([null, null, null, 'completed']);

      // act
      final pair = ExcelRowParsers.parseBreedingPairRow(row, _userId);

      // assert
      expect(pair.status, BreedingStatus.completed);
    });

    test('parses cancelled status in Turkish', () {
      // arrange
      final row = _buildRow([null, null, null, 'iptal']);

      // act
      final pair = ExcelRowParsers.parseBreedingPairRow(row, _userId);

      // assert
      expect(pair.status, BreedingStatus.cancelled);
    });

    test('parses ongoing status in German', () {
      // arrange
      final row = _buildRow([null, null, null, 'laufend']);

      // act
      final pair = ExcelRowParsers.parseBreedingPairRow(row, _userId);

      // assert
      expect(pair.status, BreedingStatus.ongoing);
    });

    test('defaults status to active for invalid value', () {
      // arrange
      final row = _buildRow([null, null, null, 'xyz']);

      // act
      final pair = ExcelRowParsers.parseBreedingPairRow(row, _userId);

      // assert
      expect(pair.status, BreedingStatus.active);
    });

    test('always returns a non-null BreedingPair (never skips)', () {
      // arrange - completely empty row
      final row = _buildRow([]);

      // act
      final pair = ExcelRowParsers.parseBreedingPairRow(row, _userId);

      // assert
      expect(pair, isNotNull);
      expect(pair.userId, _userId);
      expect(pair.id, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // parseEggRow
  // ---------------------------------------------------------------------------
  group('parseEggRow', () {
    test('parses a fully populated egg row', () {
      // arrange
      // Columns: No(0), Yumurtlama(1), Durum(2), Doller(3),
      //          Cikim(4), Kulucka ID(5), Notlar(6)
      final row = _buildRow([
        '3',
        '10.02.2025',
        'fertile',
        '14.02.2025',
        '28.02.2025',
        'incubation-uuid',
        'Healthy egg',
      ]);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.eggNumber, 3);
      expect(egg.layDate, DateTime(2025, 2, 10));
      expect(egg.status, EggStatus.fertile);
      expect(egg.fertileCheckDate, DateTime(2025, 2, 14));
      expect(egg.hatchDate, DateTime(2025, 2, 28));
      expect(egg.incubationId, 'incubation-uuid');
      expect(egg.notes, 'Healthy egg');
      expect(egg.userId, _userId);
      expect(egg.id, isNotEmpty);
    });

    test('returns null when lay date is missing', () {
      // arrange
      final row = _buildRow(['1', null, 'laid']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNull);
    });

    test('returns null when lay date is empty string', () {
      // arrange
      final row = _buildRow(['1', '', 'laid']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNull);
    });

    test('returns null when lay date is invalid', () {
      // arrange
      final row = _buildRow(['1', 'not-a-date', 'laid']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNull);
    });

    test('handles null egg number gracefully', () {
      // arrange
      final row = _buildRow([null, '01.01.2025']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.eggNumber, isNull);
    });

    test('handles non-numeric egg number', () {
      // arrange
      final row = _buildRow(['abc', '01.01.2025']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.eggNumber, isNull);
    });

    test('parses hatched status', () {
      // arrange
      final row = _buildRow([null, '01.01.2025', 'hatched']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.status, EggStatus.hatched);
    });

    test('parses incubating status in Turkish', () {
      // arrange
      final row = _buildRow([null, '01.01.2025', 'kuluckada']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.status, EggStatus.incubating);
    });

    test('parses damaged status in German', () {
      // arrange
      final row = _buildRow([null, '01.01.2025', 'beschaedigt']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.status, EggStatus.damaged);
    });

    test('defaults status to laid for invalid value', () {
      // arrange
      final row = _buildRow([null, '01.01.2025', 'xyz']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.status, EggStatus.laid);
    });

    test('defaults status to laid when status is null', () {
      // arrange
      final row = _buildRow([null, '01.01.2025']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.status, EggStatus.laid);
    });

    test('parses with only lay date (minimal valid egg)', () {
      // arrange
      final row = _buildRow([null, '20.05.2025']);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNotNull);
      expect(egg!.layDate, DateTime(2025, 5, 20));
      expect(egg.eggNumber, isNull);
      expect(egg.fertileCheckDate, isNull);
      expect(egg.hatchDate, isNull);
      expect(egg.incubationId, isNull);
      expect(egg.notes, isNull);
    });

    test('returns null for completely empty row', () {
      // arrange
      final row = _buildRow([]);

      // act
      final egg = ExcelRowParsers.parseEggRow(row, _userId);

      // assert
      expect(egg, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // parseChickRow
  // ---------------------------------------------------------------------------
  group('parseChickRow', () {
    test('parses a fully populated chick row', () {
      // arrange
      // Columns: Ad(0), Halka(1), Cinsiyet(2), Saglik(3),
      //          Cikim(4), Suten Kesme(5), Cikim Agirligi(6), Notlar(7)
      final row = _buildRow([
        'Baby',
        'CK-001',
        'female',
        'healthy',
        '01.03.2025',
        '15.04.2025',
        '3.5',
        'Strong chick',
      ]);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.name, 'Baby');
      expect(chick.ringNumber, 'CK-001');
      expect(chick.gender, BirdGender.female);
      expect(chick.healthStatus, ChickHealthStatus.healthy);
      expect(chick.hatchDate, DateTime(2025, 3, 1));
      expect(chick.weanDate, DateTime(2025, 4, 15));
      expect(chick.hatchWeight, 3.5);
      expect(chick.notes, 'Strong chick');
      expect(chick.userId, _userId);
      expect(chick.id, isNotEmpty);
    });

    test('parses chick row with all null values', () {
      // arrange
      final row = _buildRow([null, null, null, null, null, null, null, null]);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.name, isNull);
      expect(chick.ringNumber, isNull);
      expect(chick.gender, BirdGender.unknown);
      expect(chick.healthStatus, ChickHealthStatus.healthy);
      expect(chick.hatchDate, isNull);
      expect(chick.weanDate, isNull);
      expect(chick.hatchWeight, isNull);
      expect(chick.notes, isNull);
    });

    test('parses male gender in Turkish', () {
      // arrange
      final row = _buildRow([null, null, 'erkek']);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.gender, BirdGender.male);
    });

    test('parses sick health status', () {
      // arrange
      final row = _buildRow([null, null, null, 'sick']);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.healthStatus, ChickHealthStatus.sick);
    });

    test('parses deceased health status in Turkish', () {
      // arrange
      final row = _buildRow([null, null, null, 'vefat']);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.healthStatus, ChickHealthStatus.deceased);
    });

    test('defaults health status to unknown for invalid value', () {
      // arrange
      final row = _buildRow([null, null, null, 'invalid']);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.healthStatus, ChickHealthStatus.unknown);
    });

    test('handles non-numeric hatch weight', () {
      // arrange
      final row = _buildRow([
        null,
        null,
        null,
        null,
        null,
        null,
        'not-a-number',
      ]);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.hatchWeight, isNull);
    });

    test('parses integer hatch weight', () {
      // arrange
      final row = _buildRow([null, null, null, null, null, null, '4']);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.hatchWeight, 4.0);
    });

    test('always returns non-null chick (never skips)', () {
      // arrange
      final row = _buildRow([]);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick, isNotNull);
      expect(chick.userId, _userId);
      expect(chick.id, isNotEmpty);
    });

    test('parses German health status', () {
      // arrange
      final row = _buildRow([null, null, null, 'krank']);

      // act
      final chick = ExcelRowParsers.parseChickRow(row, _userId);

      // assert
      expect(chick.healthStatus, ChickHealthStatus.sick);
    });
  });

  // ---------------------------------------------------------------------------
  // parseHealthRecordRow
  // ---------------------------------------------------------------------------
  group('parseHealthRecordRow', () {
    test('parses a fully populated health record row', () {
      // arrange
      // Columns: Baslik(0), Tur(1), Tarih(2), Kus ID(3),
      //          Aciklama(4), Tedavi(5), Veteriner(6), Notlar(7)
      final row = _buildRow([
        'Annual checkup',
        'checkup',
        '10.01.2025',
        'bird-uuid-123',
        'Routine examination',
        'Vitamin supplement',
        'Dr. Vet',
        'All clear',
      ]);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.title, 'Annual checkup');
      expect(record.type, HealthRecordType.checkup);
      expect(record.date, DateTime(2025, 1, 10));
      expect(record.birdId, 'bird-uuid-123');
      expect(record.description, 'Routine examination');
      expect(record.treatment, 'Vitamin supplement');
      expect(record.veterinarian, 'Dr. Vet');
      expect(record.notes, 'All clear');
      expect(record.userId, _userId);
      expect(record.id, isNotEmpty);
    });

    test('returns null when title is null', () {
      // arrange
      final row = _buildRow([null, 'checkup', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNull);
    });

    test('returns null when title is empty string', () {
      // arrange
      final row = _buildRow(['', 'checkup', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNull);
    });

    test('returns null when date is missing', () {
      // arrange
      final row = _buildRow(['Vaccination', 'vaccination', null]);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNull);
    });

    test('returns null when date is empty string', () {
      // arrange
      final row = _buildRow(['Vaccination', 'vaccination', '']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNull);
    });

    test('returns null when date is invalid', () {
      // arrange
      final row = _buildRow(['Vaccination', 'vaccination', 'not-a-date']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNull);
    });

    test('returns null when both title and date are missing', () {
      // arrange
      final row = _buildRow([null, null, null]);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNull);
    });

    test('parses with minimal valid data (title + date only)', () {
      // arrange
      final row = _buildRow(['Quick check', null, '05.05.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.title, 'Quick check');
      expect(record.type, HealthRecordType.checkup);
      expect(record.date, DateTime(2025, 5, 5));
      expect(record.birdId, isNull);
      expect(record.description, isNull);
      expect(record.treatment, isNull);
      expect(record.veterinarian, isNull);
      expect(record.notes, isNull);
    });

    test('parses illness type', () {
      // arrange
      final row = _buildRow(['Sick bird', 'illness', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.type, HealthRecordType.illness);
    });

    test('parses vaccination type in Turkish', () {
      // arrange
      final row = _buildRow(['Asi', 'asilama', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.type, HealthRecordType.vaccination);
    });

    test('parses medication type in German', () {
      // arrange
      final row = _buildRow(['Medikament', 'medikation', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.type, HealthRecordType.medication);
    });

    test('parses injury type', () {
      // arrange
      final row = _buildRow(['Wing injury', 'injury', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.type, HealthRecordType.injury);
    });

    test('parses death type', () {
      // arrange
      final row = _buildRow(['Death record', 'death', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.type, HealthRecordType.death);
    });

    test('defaults type to unknown for invalid value', () {
      // arrange
      final row = _buildRow(['Record', 'xyz', '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.type, HealthRecordType.unknown);
    });

    test('defaults type to checkup when type is null', () {
      // arrange
      final row = _buildRow(['Record', null, '01.01.2025']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.type, HealthRecordType.checkup);
    });

    test('parses ISO 8601 date format', () {
      // arrange
      final row = _buildRow(['Record', null, '2025-07-20']);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNotNull);
      expect(record!.date, DateTime(2025, 7, 20));
    });

    test('returns null for completely empty row', () {
      // arrange
      final row = _buildRow([]);

      // act
      final record = ExcelRowParsers.parseHealthRecordRow(row, _userId);

      // assert
      expect(record, isNull);
    });
  });
}
