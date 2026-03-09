import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/chick_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

void main() {
  group('ChickRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final hatchDate = DateTime(2024, 3, 19);
      final row = ChickRow(
        id: 'c1',
        userId: 'u1',
        gender: BirdGender.female,
        healthStatus: ChickHealthStatus.healthy,
        clutchId: 'cl1',
        eggId: 'e1',
        birdId: 'b1',
        name: 'Baby',
        ringNumber: 'R-001',
        notes: 'Healthy chick',
        photoUrl: 'photo.jpg',
        hatchWeight: 3.5,
        hatchDate: hatchDate,
        weanDate: null,
        deathDate: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'c1');
      expect(model.userId, 'u1');
      expect(model.gender, BirdGender.female);
      expect(model.healthStatus, ChickHealthStatus.healthy);
      expect(model.clutchId, 'cl1');
      expect(model.eggId, 'e1');
      expect(model.birdId, 'b1');
      expect(model.name, 'Baby');
      expect(model.ringNumber, 'R-001');
      expect(model.hatchWeight, 3.5);
      expect(model.hatchDate, hatchDate);
    });

    test('handles null optional fields', () {
      const row = ChickRow(
        id: 'c2',
        userId: 'u1',
        gender: BirdGender.unknown,
        healthStatus: ChickHealthStatus.healthy,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.name, isNull);
      expect(model.eggId, isNull);
      expect(model.hatchWeight, isNull);
      expect(model.weanDate, isNull);
    });
  });

  group('ChickModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = Chick(
        id: 'c1',
        userId: 'u1',
        gender: BirdGender.male,
        healthStatus: ChickHealthStatus.sick,
        eggId: 'e1',
        name: 'Lemon',
        hatchWeight: 4.0,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'c1');
      expect(companion.userId.value, 'u1');
      expect(companion.gender.value, BirdGender.male);
      expect(companion.healthStatus.value, ChickHealthStatus.sick);
      expect(companion.eggId.value, 'e1');
      expect(companion.name.value, 'Lemon');
      expect(companion.hatchWeight.value, 4.0);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = Chick(id: 'c1', userId: 'u1');
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
