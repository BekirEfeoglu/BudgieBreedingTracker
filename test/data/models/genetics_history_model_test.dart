import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';

void main() {
  group('GeneticsHistory', () {
    final sampleHistory = GeneticsHistory(
      id: 'hist-1',
      userId: 'user-1',
      fatherGenotype: const {'lutino': 'carrier', 'albino': 'visual'},
      motherGenotype: const {'lutino': 'visual'},
      resultsJson: '[{"phenotype":"Lutino","probability":0.5}]',
      fatherBirdId: 'bird-1',
      motherBirdId: 'bird-2',
      notes: 'Test notes',
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    );

    test('JSON serialization round-trip preserves all fields', () {
      final json = sampleHistory.toJson();
      final restored = GeneticsHistory.fromJson(json);

      expect(restored.id, sampleHistory.id);
      expect(restored.userId, sampleHistory.userId);
      expect(restored.fatherGenotype, sampleHistory.fatherGenotype);
      expect(restored.motherGenotype, sampleHistory.motherGenotype);
      expect(restored.resultsJson, sampleHistory.resultsJson);
      expect(restored.fatherBirdId, sampleHistory.fatherBirdId);
      expect(restored.motherBirdId, sampleHistory.motherBirdId);
      expect(restored.notes, sampleHistory.notes);
      expect(restored.isDeleted, isFalse);
    });

    test('JSON round-trip with null optional fields', () {
      const minimal = GeneticsHistory(
        id: 'hist-2',
        userId: 'user-1',
        fatherGenotype: {},
        motherGenotype: {},
        resultsJson: '[]',
      );

      final json = minimal.toJson();
      final restored = GeneticsHistory.fromJson(json);

      expect(restored.id, 'hist-2');
      expect(restored.fatherBirdId, isNull);
      expect(restored.motherBirdId, isNull);
      expect(restored.notes, isNull);
      expect(restored.isDeleted, isFalse);
    });

    test('@Default(false) sets isDeleted to false', () {
      const history = GeneticsHistory(
        id: 'hist-3',
        userId: 'user-1',
        fatherGenotype: {},
        motherGenotype: {},
        resultsJson: '[]',
      );

      expect(history.isDeleted, isFalse);
    });

    test('copyWith creates updated copy immutably', () {
      final updated = sampleHistory.copyWith(
        notes: 'Updated notes',
        isDeleted: true,
      );

      expect(updated.notes, 'Updated notes');
      expect(updated.isDeleted, isTrue);
      // Original unchanged
      expect(sampleHistory.notes, 'Test notes');
      expect(sampleHistory.isDeleted, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = sampleHistory.copyWith(notes: 'New note');

      expect(updated.id, sampleHistory.id);
      expect(updated.userId, sampleHistory.userId);
      expect(updated.fatherGenotype, sampleHistory.fatherGenotype);
      expect(updated.resultsJson, sampleHistory.resultsJson);
    });

    test('equality is value-based', () {
      final copy = GeneticsHistory(
        id: 'hist-1',
        userId: 'user-1',
        fatherGenotype: const {'lutino': 'carrier', 'albino': 'visual'},
        motherGenotype: const {'lutino': 'visual'},
        resultsJson: '[{"phenotype":"Lutino","probability":0.5}]',
        fatherBirdId: 'bird-1',
        motherBirdId: 'bird-2',
        notes: 'Test notes',
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      );

      expect(sampleHistory, copy);
    });

    test('JSON serialization handles empty genotype maps', () {
      const history = GeneticsHistory(
        id: 'hist-4',
        userId: 'user-1',
        fatherGenotype: {},
        motherGenotype: {},
        resultsJson: '[]',
      );

      final json = history.toJson();
      final restored = GeneticsHistory.fromJson(json);

      expect(restored.fatherGenotype, isEmpty);
      expect(restored.motherGenotype, isEmpty);
    });
  });
}
