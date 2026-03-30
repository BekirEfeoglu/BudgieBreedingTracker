import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/incubation_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

void main() {
  final startDate = DateTime(2024, 3, 1);
  final endDate = DateTime(2024, 3, 19);

  group('IncubationRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = IncubationRow(
        id: 'i1',
        userId: 'u1',
        species: Species.canary,
        status: IncubationStatus.active,
        version: 2,
        clutchId: 'cl1',
        breedingPairId: 'bp1',
        notes: 'Started',
        startDate: startDate,
        endDate: endDate,
        expectedHatchDate: endDate,
      );
      final model = row.toModel();

      expect(model.id, 'i1');
      expect(model.userId, 'u1');
      expect(model.species, Species.canary);
      expect(model.status, IncubationStatus.active);
      expect(model.version, 2);
      expect(model.clutchId, 'cl1');
      expect(model.breedingPairId, 'bp1');
      expect(model.notes, 'Started');
      expect(model.startDate, startDate);
      expect(model.endDate, endDate);
    });

    test('handles null optional fields', () {
      const row = IncubationRow(
        id: 'i2',
        userId: 'u1',
        species: Species.budgie,
        status: IncubationStatus.active,
        version: 1,
      );
      final model = row.toModel();

      expect(model.clutchId, isNull);
      expect(model.breedingPairId, isNull);
      expect(model.notes, isNull);
      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
    });
  });

  group('IncubationModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      final model = Incubation(
        id: 'i1',
        userId: 'u1',
        species: Species.cockatiel,
        status: IncubationStatus.completed,
        version: 3,
        breedingPairId: 'bp1',
        startDate: startDate,
        endDate: endDate,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'i1');
      expect(companion.userId.value, 'u1');
      expect(companion.species.value, Species.cockatiel);
      expect(companion.status.value, IncubationStatus.completed);
      expect(companion.version.value, 3);
      expect(companion.breedingPairId.value, 'bp1');
      expect(companion.startDate.value, startDate);
      expect(companion.endDate.value, endDate);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      final model = Incubation(id: 'i1', userId: 'u1', startDate: startDate);
      final companion = model.toCompanion();

      expect(companion.updatedAt.value, isNotNull);
      expect(
        companion.updatedAt.value!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
