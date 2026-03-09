import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

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
