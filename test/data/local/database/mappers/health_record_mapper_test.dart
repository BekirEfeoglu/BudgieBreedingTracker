import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/health_record_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

void main() {
  final date = DateTime.utc(2024, 4, 15);

  group('HealthRecordRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = HealthRecordRow(
        id: 'hr1',
        date: date,
        type: HealthRecordType.vaccination,
        title: 'Annual vaccine',
        userId: 'u1',
        birdId: 'b1',
        description: 'Routine vaccination',
        treatment: 'Vaccine X',
        veterinarian: 'Dr. Smith',
        notes: 'No reactions',
        weight: 35.5,
        cost: 50.0,
        followUpDate: DateTime.utc(2024, 5, 15),
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'hr1');
      expect(model.date, date);
      expect(model.type, HealthRecordType.vaccination);
      expect(model.title, 'Annual vaccine');
      expect(model.userId, 'u1');
      expect(model.birdId, 'b1');
      expect(model.description, 'Routine vaccination');
      expect(model.treatment, 'Vaccine X');
      expect(model.veterinarian, 'Dr. Smith');
      expect(model.weight, 35.5);
      expect(model.cost, 50.0);
    });

    test('handles null optional fields', () {
      final row = HealthRecordRow(
        id: 'hr2',
        date: date,
        type: HealthRecordType.checkup,
        title: 'Checkup',
        userId: 'u1',
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.birdId, isNull);
      expect(model.description, isNull);
      expect(model.treatment, isNull);
      expect(model.weight, isNull);
      expect(model.cost, isNull);
      expect(model.followUpDate, isNull);
    });
  });

  group('HealthRecordModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      final model = HealthRecord(
        id: 'hr1',
        date: date,
        type: HealthRecordType.illness,
        title: 'Sick bird',
        userId: 'u1',
        birdId: 'b1',
        weight: 30.0,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'hr1');
      expect(companion.date.value, date);
      expect(companion.type.value, HealthRecordType.illness);
      expect(companion.title.value, 'Sick bird');
      expect(companion.userId.value, 'u1');
      expect(companion.birdId.value, 'b1');
      expect(companion.weight.value, 30.0);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      final model = HealthRecord(
        id: 'hr1',
        date: date,
        type: HealthRecordType.checkup,
        title: 'Test',
        userId: 'u1',
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
