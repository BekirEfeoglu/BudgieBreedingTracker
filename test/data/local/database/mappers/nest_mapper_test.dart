import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/nest_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';

void main() {
  group('NestRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = NestRow(
        id: 'n1',
        userId: 'u1',
        name: 'Nest A',
        location: 'Cage 3',
        status: NestStatus.occupied,
        notes: 'Wooden nest',
        isDeleted: false,
        createdAt: DateTime.utc(2024, 3, 1),
        updatedAt: DateTime.utc(2024, 3, 2),
      );
      final model = row.toModel();

      expect(model.id, 'n1');
      expect(model.userId, 'u1');
      expect(model.name, 'Nest A');
      expect(model.location, 'Cage 3');
      expect(model.status, NestStatus.occupied);
      expect(model.notes, 'Wooden nest');
      expect(model.isDeleted, false);
    });

    test('handles null optional fields', () {
      const row = NestRow(
        id: 'n2',
        userId: 'u1',
        name: null,
        location: null,
        status: NestStatus.available,
        notes: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.name, isNull);
      expect(model.location, isNull);
      expect(model.notes, isNull);
    });
  });

  group('NestModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = Nest(
        id: 'n1',
        userId: 'u1',
        name: 'Nest B',
        location: 'Cage 5',
        status: NestStatus.maintenance,
        notes: 'Cleaning',
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'n1');
      expect(companion.userId.value, 'u1');
      expect(companion.name.value, 'Nest B');
      expect(companion.location.value, 'Cage 5');
      expect(companion.status.value, NestStatus.maintenance);
      expect(companion.notes.value, 'Cleaning');
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = Nest(id: 'n1', userId: 'u1');
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
