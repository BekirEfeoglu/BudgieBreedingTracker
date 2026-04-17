// Plain Dart classes for admin user content inspection.
//
// These models have no code generation (no Freezed/JSON) and are used
// exclusively by the admin user-detail flow to display a user's entities.

/// Detailed admin-visible content for a specific user.
class AdminUserContent {
  const AdminUserContent({
    this.birds = const [],
    this.pairs = const [],
    this.eggs = const [],
    this.chicks = const [],
    this.photos = const [],
  });

  final List<AdminBirdRecord> birds;
  final List<AdminBreedingRecord> pairs;
  final List<AdminEggRecord> eggs;
  final List<AdminChickRecord> chicks;
  final List<AdminPhotoRecord> photos;
}

class AdminBirdRecord {
  const AdminBirdRecord({
    required this.id,
    required this.name,
    required this.gender,
    required this.status,
    required this.species,
    this.ringNumber,
    this.cageNumber,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String gender;
  final String status;
  final String species;
  final String? ringNumber;
  final String? cageNumber;
  final String? photoUrl;
  final DateTime? createdAt;
}

class AdminBreedingRecord {
  const AdminBreedingRecord({
    required this.id,
    required this.status,
    this.maleId,
    this.maleName,
    this.femaleId,
    this.femaleName,
    this.cageNumber,
    this.pairingDate,
    this.createdAt,
  });

  final String id;
  final String status;
  final String? maleId;
  final String? maleName;
  final String? femaleId;
  final String? femaleName;
  final String? cageNumber;
  final DateTime? pairingDate;
  final DateTime? createdAt;
}

class AdminEggRecord {
  const AdminEggRecord({
    required this.id,
    required this.status,
    required this.layDate,
    this.eggNumber,
    this.clutchId,
    this.hatchDate,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String status;
  final DateTime layDate;
  final int? eggNumber;
  final String? clutchId;
  final DateTime? hatchDate;
  final String? photoUrl;
  final DateTime? createdAt;
}

class AdminChickRecord {
  const AdminChickRecord({
    required this.id,
    required this.gender,
    required this.healthStatus,
    this.name,
    this.ringNumber,
    this.hatchDate,
    this.photoUrl,
    this.birdId,
    this.createdAt,
  });

  final String id;
  final String gender;
  final String healthStatus;
  final String? name;
  final String? ringNumber;
  final DateTime? hatchDate;
  final String? photoUrl;
  final String? birdId;
  final DateTime? createdAt;
}

class AdminPhotoRecord {
  const AdminPhotoRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.fileName,
    this.filePath,
    this.entityLabel,
    this.isPrimary = false,
    this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String fileName;
  final String? filePath;
  final String? entityLabel;
  final bool isPrimary;
  final DateTime? createdAt;
}
