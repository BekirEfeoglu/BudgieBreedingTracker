import 'package:excel/excel.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/domain/services/import/excel_import_helpers.dart';
import 'package:uuid/uuid.dart';

/// Static row parsers that convert an Excel row into the corresponding model.
///
/// Each parser returns `null` when the row should be skipped (validation
/// failure). The caller is responsible for collecting error messages via
/// the optional [onSkip] callback.
abstract final class ExcelRowParsers {
  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Bird
  // ---------------------------------------------------------------------------

  /// Parses a single Excel row into a [Bird].
  ///
  /// Expected columns: Ad (0), Halka No (1), Cinsiyet (2), Tur (3),
  /// Durum (4), Dogum Tarihi (5), Renk (6), Kafes (7),
  /// Notlar (8) or Baba ID (9), Anne ID (10), Notlar (11)
  ///
  /// Returns `null` when name is empty (row skipped).
  static Bird? parseBirdRow(List<Data?> row, String userId) {
    final name = cellToString(row, 0);
    if (name == null || name.isEmpty) return null;

    final ringNumber = cellToString(row, 1);
    final genderStr = cellToString(row, 2);
    final speciesStr = cellToString(row, 3);
    final statusStr = cellToString(row, 4);
    final birthDateStr = cellToString(row, 5);
    final cage = cellToString(row, 7);
    final fatherId = cellToString(row, 9);
    final motherId = cellToString(row, 10);
    final notes = cellToString(row, 11) ?? cellToString(row, 8);

    final gender = parseGender(genderStr);
    final species = parseSpecies(speciesStr);
    final status = parseBirdStatus(statusStr);
    final birthDate = parseDate(birthDateStr);

    return Bird(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      ringNumber: ringNumber,
      gender: gender,
      species: species,
      status: status,
      birthDate: birthDate,
      fatherId: fatherId,
      motherId: motherId,
      cageNumber: cage,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Breeding Pair
  // ---------------------------------------------------------------------------

  /// Parses a single Excel row into a [BreedingPair].
  ///
  /// Expected columns: Erkek ID (0), Disi ID (1), Kafes (2), Durum (3),
  /// Eslestirme (4), Ayrilma (5), Notlar (6)
  static BreedingPair parseBreedingPairRow(List<Data?> row, String userId) {
    final maleId = cellToString(row, 0);
    final femaleId = cellToString(row, 1);
    final cageNumber = cellToString(row, 2);
    final statusStr = cellToString(row, 3);
    final pairingDateStr = cellToString(row, 4);
    final separationDateStr = cellToString(row, 5);
    final notes = cellToString(row, 6);

    final status = parseBreedingStatus(statusStr);
    final pairingDate = parseDate(pairingDateStr);
    final separationDate = parseDate(separationDateStr);

    return BreedingPair(
      id: _uuid.v4(),
      userId: userId,
      maleId: maleId,
      femaleId: femaleId,
      cageNumber: cageNumber,
      status: status,
      pairingDate: pairingDate,
      separationDate: separationDate,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Egg
  // ---------------------------------------------------------------------------

  /// Parses a single Excel row into an [Egg].
  ///
  /// Expected columns: No (0), Yumurtlama (1), Durum (2), Doller (3),
  /// Cikim (4), Kulucka ID (5), Notlar (6)
  ///
  /// Returns `null` when layDate is missing (row skipped).
  static Egg? parseEggRow(List<Data?> row, String userId) {
    final eggNumberStr = cellToString(row, 0);
    final layDateStr = cellToString(row, 1);
    final statusStr = cellToString(row, 2);
    final fertileDateStr = cellToString(row, 3);
    final hatchDateStr = cellToString(row, 4);
    final incubationId = cellToString(row, 5);
    final notes = cellToString(row, 6);

    final layDate = parseDate(layDateStr);
    if (layDate == null) return null;

    final eggNumber = int.tryParse(eggNumberStr ?? '');
    final status = parseEggStatus(statusStr);
    final fertileCheckDate = parseDate(fertileDateStr);
    final hatchDate = parseDate(hatchDateStr);

    return Egg(
      id: _uuid.v4(),
      userId: userId,
      eggNumber: eggNumber,
      layDate: layDate,
      status: status,
      fertileCheckDate: fertileCheckDate,
      hatchDate: hatchDate,
      incubationId: incubationId,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Chick
  // ---------------------------------------------------------------------------

  /// Parses a single Excel row into a [Chick].
  ///
  /// Expected columns: Ad (0), Halka (1), Cinsiyet (2), Saglik (3),
  /// Cikim (4), Suten Kesme (5), Cikim Agirligi (6), Notlar (7)
  static Chick parseChickRow(List<Data?> row, String userId) {
    final name = cellToString(row, 0);
    final ringNumber = cellToString(row, 1);
    final genderStr = cellToString(row, 2);
    final healthStr = cellToString(row, 3);
    final hatchDateStr = cellToString(row, 4);
    final weanDateStr = cellToString(row, 5);
    final hatchWeightStr = cellToString(row, 6);
    final notes = cellToString(row, 7);

    final gender = parseGender(genderStr);
    final healthStatus = parseHealthStatus(healthStr);
    final hatchDate = parseDate(hatchDateStr);
    final weanDate = parseDate(weanDateStr);
    final hatchWeight = double.tryParse(hatchWeightStr ?? '');

    return Chick(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      ringNumber: ringNumber,
      gender: gender,
      healthStatus: healthStatus,
      hatchDate: hatchDate,
      weanDate: weanDate,
      hatchWeight: hatchWeight,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Health Record
  // ---------------------------------------------------------------------------

  /// Parses a single Excel row into a [HealthRecord].
  ///
  /// Expected columns: Baslik (0), Tur (1), Tarih (2), Kus ID (3),
  /// Aciklama (4), Tedavi (5), Veteriner (6), Notlar (7)
  ///
  /// Returns `null` when title is empty or date is missing (row skipped).
  static HealthRecord? parseHealthRecordRow(List<Data?> row, String userId) {
    final title = cellToString(row, 0);
    final typeStr = cellToString(row, 1);
    final dateStr = cellToString(row, 2);
    final birdId = cellToString(row, 3);
    final description = cellToString(row, 4);
    final treatment = cellToString(row, 5);
    final veterinarian = cellToString(row, 6);
    final notes = cellToString(row, 7);

    if (title == null || title.isEmpty) return null;

    final date = parseDate(dateStr);
    if (date == null) return null;

    final type = parseHealthRecordType(typeStr);

    return HealthRecord(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      type: type,
      date: date,
      birdId: birdId,
      description: description,
      treatment: treatment,
      veterinarian: veterinarian,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
