import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/genetics_history_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';

void main() {
  group('GeneticsHistoryRowMapper.toModel()', () {
    test('maps all fields correctly with valid JSON genotypes', () {
      final fatherGeno = {'ino': 'heterozygous', 'opaline': 'homozygous'};
      final motherGeno = {'ino': 'homozygous', 'spangle': 'heterozygous'};

      final row = GeneticsHistoryRow(
        id: 'gh1',
        userId: 'u1',
        fatherGenotype: jsonEncode(fatherGeno),
        motherGenotype: jsonEncode(motherGeno),
        fatherBirdId: 'b1',
        motherBirdId: 'b2',
        resultsJson: '{"offspring":[]}',
        notes: 'Test calculation',
        createdAt: DateTime.utc(2024, 5, 1),
        updatedAt: DateTime.utc(2024, 5, 2),
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'gh1');
      expect(model.userId, 'u1');
      expect(model.fatherGenotype, fatherGeno);
      expect(model.motherGenotype, motherGeno);
      expect(model.fatherBirdId, 'b1');
      expect(model.motherBirdId, 'b2');
      expect(model.resultsJson, '{"offspring":[]}');
      expect(model.notes, 'Test calculation');
      expect(model.isDeleted, false);
    });

    test('returns empty map for invalid JSON genotype', () {
      const row = GeneticsHistoryRow(
        id: 'gh2',
        userId: 'u1',
        fatherGenotype: 'not-valid-json',
        motherGenotype: '{invalid',
        fatherBirdId: null,
        motherBirdId: null,
        resultsJson: '[]',
        notes: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.fatherGenotype, isEmpty);
      expect(model.motherGenotype, isEmpty);
    });

    test('returns empty map for empty JSON object', () {
      const row = GeneticsHistoryRow(
        id: 'gh3',
        userId: 'u1',
        fatherGenotype: '{}',
        motherGenotype: '{}',
        fatherBirdId: null,
        motherBirdId: null,
        resultsJson: '[]',
        notes: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.fatherGenotype, isEmpty);
      expect(model.motherGenotype, isEmpty);
    });

    test('returns empty map for non-map JSON (e.g. array)', () {
      const row = GeneticsHistoryRow(
        id: 'gh4',
        userId: 'u1',
        fatherGenotype: '["a","b"]',
        motherGenotype: '"string"',
        fatherBirdId: null,
        motherBirdId: null,
        resultsJson: '[]',
        notes: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.fatherGenotype, isEmpty);
      expect(model.motherGenotype, isEmpty);
    });

    test('handles null optional fields', () {
      const row = GeneticsHistoryRow(
        id: 'gh5',
        userId: 'u1',
        fatherGenotype: '{"ino":"het"}',
        motherGenotype: '{"ino":"hom"}',
        fatherBirdId: null,
        motherBirdId: null,
        resultsJson: '[]',
        notes: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.fatherBirdId, isNull);
      expect(model.motherBirdId, isNull);
      expect(model.notes, isNull);
    });
  });

  group('GeneticsHistoryModelMapper.toCompanion()', () {
    test('wraps all fields in Value and encodes genotypes as JSON', () {
      final fatherGeno = {'ino': 'heterozygous'};
      final motherGeno = {'opaline': 'homozygous'};
      final model = GeneticsHistory(
        id: 'gh1',
        userId: 'u1',
        fatherGenotype: fatherGeno,
        motherGenotype: motherGeno,
        fatherBirdId: 'b1',
        motherBirdId: 'b2',
        resultsJson: '{"results":[]}',
        notes: 'Notes',
        isDeleted: false,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'gh1');
      expect(companion.userId.value, 'u1');
      expect(companion.fatherGenotype.value, jsonEncode(fatherGeno));
      expect(companion.motherGenotype.value, jsonEncode(motherGeno));
      expect(companion.fatherBirdId.value, 'b1');
      expect(companion.motherBirdId.value, 'b2');
      expect(companion.resultsJson.value, '{"results":[]}');
      expect(companion.notes.value, 'Notes');
      expect(companion.isDeleted.value, false);
    });

    test('encodes empty genotype maps as empty JSON object', () {
      const model = GeneticsHistory(
        id: 'gh2',
        userId: 'u1',
        fatherGenotype: {},
        motherGenotype: {},
        resultsJson: '[]',
      );
      final companion = model.toCompanion();

      expect(companion.fatherGenotype.value, '{}');
      expect(companion.motherGenotype.value, '{}');
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = GeneticsHistory(
        id: 'gh1',
        userId: 'u1',
        fatherGenotype: {},
        motherGenotype: {},
        resultsJson: '[]',
      );
      final companion = model.toCompanion();

      expect(
        companion.updatedAt.value!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
