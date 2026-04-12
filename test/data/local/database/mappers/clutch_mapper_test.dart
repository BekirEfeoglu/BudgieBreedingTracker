import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/clutch_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';

void main() {
  group('ClutchRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final startDate = DateTime(2024, 3, 1);
      final row = ClutchRow(
        id: 'cl1',
        userId: 'u1',
        name: 'Clutch A',
        breedingId: 'bp1',
        incubationId: 'inc1',
        maleBirdId: 'm1',
        femaleBirdId: 'f1',
        nestId: 'n1',
        pairDate: startDate,
        startDate: startDate,
        endDate: null,
        status: BreedingStatus.active,
        notes: 'First clutch',
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'cl1');
      expect(model.userId, 'u1');
      expect(model.name, 'Clutch A');
      expect(model.breedingId, 'bp1');
      expect(model.incubationId, 'inc1');
      expect(model.maleBirdId, 'm1');
      expect(model.femaleBirdId, 'f1');
      expect(model.nestId, 'n1');
      expect(model.status, BreedingStatus.active);
      expect(model.isDeleted, false);
    });
  });

  group('ClutchModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = Clutch(
        id: 'cl1',
        userId: 'u1',
        name: 'Clutch B',
        breedingId: 'bp1',
        nestId: 'n1',
        status: BreedingStatus.completed,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'cl1');
      expect(companion.userId.value, 'u1');
      expect(companion.name.value, 'Clutch B');
      expect(companion.breedingId.value, 'bp1');
      expect(companion.nestId.value, 'n1');
      expect(companion.status.value, BreedingStatus.completed);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = Clutch(id: 'cl1', userId: 'u1');
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
