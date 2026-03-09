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
        fatherBirdId: fatherBirdId,
        motherBirdId: motherBirdId,
        resultsJson: resultsJson,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
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
}

extension GeneticsHistoryModelMapper on GeneticsHistory {
  GeneticsHistoryTableCompanion toCompanion() => GeneticsHistoryTableCompanion(
        id: Value(id),
        userId: Value(userId),
        fatherGenotype: Value(jsonEncode(fatherGenotype)),
        motherGenotype: Value(jsonEncode(motherGenotype)),
        fatherBirdId: Value(fatherBirdId),
        motherBirdId: Value(motherBirdId),
        resultsJson: Value(resultsJson),
        notes: Value(notes),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt ?? DateTime.now()),
        isDeleted: Value(isDeleted),
      );
}
