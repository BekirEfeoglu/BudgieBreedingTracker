import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';

extension GeneticsHistoryRowMapper on GeneticsHistoryRow {
  GeneticsHistory toModel() => GeneticsHistory(
    id: id,
    userId: userId,
    fatherGenotype: _decodeStringMap(fatherGenotype),
    motherGenotype: _decodeStringMap(motherGenotype),
    fatherPhaseOverrides: _decodeNullableStringMap(fatherPhaseOverrides),
    fatherBirdId: fatherBirdId,
    motherBirdId: motherBirdId,
    resultsJson: resultsJson,
    calculationVersion: calculationVersion,
    notes: notes,
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
    isDeleted: isDeleted,
  );

  static Map<String, String> _decodeStringMap(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map) return decoded.cast<String, String>();
      return {};
    } catch (_) {
      return {};
    }
  }

  static Map<String, String>? _decodeNullableStringMap(String? json) {
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      return decoded is Map ? decoded.cast<String, String>() : null;
    } catch (_) {
      return null;
    }
  }
}

extension GeneticsHistoryModelMapper on GeneticsHistory {
  GeneticsHistoryTableCompanion toCompanion() => GeneticsHistoryTableCompanion(
    id: Value(id),
    userId: Value(userId),
    fatherGenotype: Value(jsonEncode(fatherGenotype)),
    motherGenotype: Value(jsonEncode(motherGenotype)),
    fatherPhaseOverrides: Value(
      fatherPhaseOverrides == null ? null : jsonEncode(fatherPhaseOverrides),
    ),
    fatherBirdId: Value(fatherBirdId),
    motherBirdId: Value(motherBirdId),
    resultsJson: Value(resultsJson),
    calculationVersion: Value(calculationVersion),
    notes: Value(notes),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
    isDeleted: Value(isDeleted),
  );
}
