import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

extension BirdRowMapper on BirdRow {
  Bird toModel() => Bird(
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
    colorMutation: colorMutation,
    cageNumber: cageNumber,
    notes: notes,
    birthDate: birthDate,
    deathDate: deathDate,
    soldDate: soldDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
    mutations: _decodeMutationsList(mutations),
    genotypeInfo: _decodeGenotypeInfo(genotypeInfo),
  );

  static List<String>? _decodeMutationsList(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded.cast<String>();
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, String>? _decodeGenotypeInfo(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) return decoded.cast<String, String>();
      return null;
    } catch (_) {
      return null;
    }
  }
}

extension BirdModelMapper on Bird {
  BirdsTableCompanion toCompanion() => BirdsTableCompanion(
    id: Value(id),
    name: Value(name),
    gender: Value(gender),
    userId: Value(userId),
    status: Value(status),
    species: Value(species),
    ringNumber: Value(ringNumber),
    photoUrl: Value(photoUrl),
    fatherId: Value(fatherId),
    motherId: Value(motherId),
    colorMutation: Value(colorMutation),
    cageNumber: Value(cageNumber),
    notes: Value(notes),
    birthDate: Value(birthDate),
    deathDate: Value(deathDate),
    soldDate: Value(soldDate),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
    isDeleted: Value(isDeleted),
    mutations: Value(mutations != null ? jsonEncode(mutations) : null),
    genotypeInfo: Value(genotypeInfo != null ? jsonEncode(genotypeInfo) : null),
  );
}
