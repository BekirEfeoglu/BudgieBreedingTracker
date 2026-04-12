import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

HealthRecord _buildHealthRecord({
  String id = 'health-1',
  DateTime? date,
  HealthRecordType type = HealthRecordType.checkup,
  String title = 'General check',
  String userId = 'user-1',
  String? birdId,
  String? description,
  String? treatment,
  String? veterinarian,
  String? notes,
  double? weight,
  double? cost,
  DateTime? followUpDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
}) {
  return HealthRecord(
    id: id,
    date: date ?? DateTime(2024, 1, 1),
    type: type,
    title: title,
    userId: userId,
    birdId: birdId,
    description: description,
    treatment: treatment,
    veterinarian: veterinarian,
    notes: notes,
    weight: weight,
    cost: cost,
    followUpDate: followUpDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

void main() {
  group('HealthRecord model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final record = _buildHealthRecord(
          id: 'health-42',
          date: DateTime(2024, 2, 1),
          type: HealthRecordType.medication,
          title: 'Medication cycle',
          userId: 'user-42',
          birdId: 'bird-1',
          description: 'Respiratory issue',
          treatment: 'Antibiotic',
          veterinarian: 'Dr. Kaya',
          notes: 'Responding well',
          weight: 33.2,
          cost: 120.5,
          followUpDate: DateTime(2024, 2, 10),
          createdAt: DateTime(2024, 2, 1, 8, 0),
          updatedAt: DateTime(2024, 2, 2, 8, 0),
          isDeleted: true,
        );

        final restored = HealthRecord.fromJson(record.toJson());

        expect(restored.id, record.id);
        expect(restored.date, record.date);
        expect(restored.type, record.type);
        expect(restored.title, record.title);
        expect(restored.userId, record.userId);
        expect(restored.birdId, record.birdId);
        expect(restored.description, record.description);
        expect(restored.treatment, record.treatment);
        expect(restored.veterinarian, record.veterinarian);
        expect(restored.notes, record.notes);
        expect(restored.weight, record.weight);
        expect(restored.cost, record.cost);
        expect(restored.followUpDate, record.followUpDate);
        expect(restored.createdAt, record.createdAt);
        expect(restored.updatedAt, record.updatedAt);
        expect(restored.isDeleted, record.isDeleted);
      });

      test('falls back to unknown for unrecognized type', () {
        final record = HealthRecord.fromJson({
          'id': 'health-1',
          'date': DateTime(2024, 1, 1).toIso8601String(),
          'type': 'invalid-type',
          'title': 'Title',
          'user_id': 'user-1',
        });

        expect(record.type, HealthRecordType.unknown);
      });

      test('applies default isDeleted=false when not provided', () {
        final record = HealthRecord.fromJson({
          'id': 'health-1',
          'date': DateTime(2024, 1, 1).toIso8601String(),
          'type': 'checkup',
          'title': 'Title',
          'user_id': 'user-1',
        });

        expect(record.isDeleted, isFalse);
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final record = _buildHealthRecord(notes: 'Old', cost: 50);
        final updated = record.copyWith(notes: 'New', cost: 75);

        expect(updated.notes, 'New');
        expect(updated.cost, 75);
        expect(updated.id, record.id);
        expect(updated.userId, record.userId);
      });
    });
  });

  group('HealthRecordType enum', () {
    test('toJson and fromJson work for all values', () {
      for (final type in HealthRecordType.values) {
        final json = type.toJson();
        expect(HealthRecordType.fromJson(json), type);
      }
    });
  });
}
