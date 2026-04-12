import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

/// Stable reference dates for tests. Use these instead of hardcoded DateTime
/// literals so tests remain valid regardless of when they run.
abstract final class TestDates {
  /// A fixed past date used as default createdAt/updatedAt.
  static final baseline = DateTime(2024, 1, 1);

  /// 10 days after baseline — used for egg lay dates.
  static final layDate = DateTime(2024, 1, 10);

  /// 28 days after baseline — used for chick hatch dates.
  static final hatchDate = DateTime(2024, 1, 28);

  /// 19 days after baseline — used for expected hatch (incubation).
  static final expectedHatch = DateTime(2024, 1, 19);
}

/// Creates a test [Bird] with sensible defaults.
///
/// Override any field as needed for specific test scenarios.
Bird createTestBird({
  String id = 'bird-1',
  String name = 'Test Bird',
  BirdGender gender = BirdGender.male,
  String userId = 'user-1',
  BirdStatus status = BirdStatus.alive,
  Species species = Species.budgie,
  String? ringNumber,
  String? photoUrl,
  String? fatherId,
  String? motherId,
  String? cageNumber,
  String? notes,
  DateTime? birthDate,
  DateTime? deathDate,
  DateTime? soldDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
}) {
  return Bird(
    id: id,
    name: name,
    gender: gender,
    userId: userId,
    status: status,
    species: species,
    ringNumber: ringNumber,
    photoUrl: photoUrl,
    fatherId: fatherId,
    motherId: motherId,
    cageNumber: cageNumber,
    notes: notes,
    birthDate: birthDate,
    deathDate: deathDate,
    soldDate: soldDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

/// Creates a pedigree map with common ancestor for inbreeding tests.
///
/// Structure:
/// ```
///         grandparent (GP)
///        /            \
///    father (F)    mother (M)
///        \            /
///          subject (S)
/// ```
Map<String, Bird> createInbredPedigree({
  String subjectId = 'subject',
  String fatherId = 'father',
  String motherId = 'mother',
  String commonAncestorId = 'grandparent',
}) {
  final grandparent = createTestBird(
    id: commonAncestorId,
    name: 'Grandparent',
    gender: BirdGender.male,
  );
  final father = createTestBird(
    id: fatherId,
    name: 'Father',
    gender: BirdGender.male,
    fatherId: commonAncestorId,
  );
  final mother = createTestBird(
    id: motherId,
    name: 'Mother',
    gender: BirdGender.female,
    fatherId: commonAncestorId,
  );
  final subject = createTestBird(
    id: subjectId,
    name: 'Subject',
    gender: BirdGender.male,
    fatherId: fatherId,
    motherId: motherId,
  );

  return {
    commonAncestorId: grandparent,
    fatherId: father,
    motherId: mother,
    subjectId: subject,
  };
}

class TestFixtures {
  static Bird sampleBird({
    String id = 'bird-1',
    String name = 'Mavis',
    BirdGender gender = BirdGender.male,
    String userId = 'user-1',
    BirdStatus status = BirdStatus.alive,
  }) {
    return createTestBird(
      id: id,
      name: name,
      gender: gender,
      userId: userId,
      status: status,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    );
  }

  static Egg sampleEgg({
    String id = 'egg-1',
    String userId = 'user-1',
    DateTime? layDate,
    EggStatus status = EggStatus.laid,
    String? clutchId,
    String? incubationId,
  }) {
    return Egg(
      id: id,
      userId: userId,
      layDate: layDate ?? TestDates.layDate,
      status: status,
      clutchId: clutchId,
      incubationId: incubationId,
      createdAt: TestDates.layDate,
      updatedAt: TestDates.layDate,
    );
  }

  static Chick sampleChick({
    String id = 'chick-1',
    String userId = 'user-1',
    BirdGender gender = BirdGender.unknown,
    DateTime? hatchDate,
    String? eggId,
    String? clutchId,
  }) {
    return Chick(
      id: id,
      userId: userId,
      gender: gender,
      hatchDate: hatchDate ?? TestDates.hatchDate,
      eggId: eggId,
      clutchId: clutchId,
      createdAt: TestDates.hatchDate,
      updatedAt: TestDates.hatchDate,
    );
  }

  static BreedingPair sampleBreedingPair({
    String id = 'pair-1',
    String userId = 'user-1',
    String? maleId = 'bird-1',
    String? femaleId = 'bird-2',
    BreedingStatus status = BreedingStatus.active,
  }) {
    return BreedingPair(
      id: id,
      userId: userId,
      maleId: maleId,
      femaleId: femaleId,
      status: status,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    );
  }

  static Clutch sampleClutch({
    String id = 'clutch-1',
    String userId = 'user-1',
    String? breedingId = 'pair-1',
    String? incubationId,
  }) {
    return Clutch(
      id: id,
      userId: userId,
      breedingId: breedingId,
      incubationId: incubationId,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    );
  }

  static SyncMetadata sampleSyncMetadata({
    String id = 'sync-1',
    String table = 'birds',
    String userId = 'user-1',
    String? recordId = 'bird-1',
    SyncStatus status = SyncStatus.pending,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncMetadata(
      id: id,
      table: table,
      userId: userId,
      recordId: recordId,
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    );
  }
}
