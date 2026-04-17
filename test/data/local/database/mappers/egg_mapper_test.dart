import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/egg_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

void main() {
  final layDate = DateTime.utc(2024, 3, 1);
  final hatchDate = DateTime.utc(2024, 3, 19);

  group('EggRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = EggRow(
        id: 'e1',
        layDate: layDate,
        userId: 'u1',
        status: EggStatus.incubating,
        clutchId: 'cl1',
        incubationId: 'inc1',
        eggNumber: 3,
        notes: 'Healthy egg',
        photoUrl: 'photo.jpg',
        hatchDate: hatchDate,
        fertileCheckDate: DateTime.utc(2024, 3, 7),
        discardDate: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'e1');
      expect(model.layDate, layDate);
      expect(model.userId, 'u1');
      expect(model.status, EggStatus.incubating);
      expect(model.clutchId, 'cl1');
      expect(model.incubationId, 'inc1');
      expect(model.eggNumber, 3);
      expect(model.notes, 'Healthy egg');
      expect(model.hatchDate, hatchDate);
    });

    test('handles null optional fields', () {
      final row = EggRow(
        id: 'e2',
        layDate: layDate,
        userId: 'u1',
        status: EggStatus.laid,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.clutchId, isNull);
      expect(model.incubationId, isNull);
      expect(model.eggNumber, isNull);
      expect(model.hatchDate, isNull);
    });
  });

  group('EggModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      final model = Egg(
        id: 'e1',
        layDate: layDate,
        userId: 'u1',
        status: EggStatus.fertile,
        clutchId: 'cl1',
        incubationId: 'inc1',
        eggNumber: 2,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'e1');
      expect(companion.layDate.value, layDate);
      expect(companion.userId.value, 'u1');
      expect(companion.status.value, EggStatus.fertile);
      expect(companion.clutchId.value, 'cl1');
      expect(companion.incubationId.value, 'inc1');
      expect(companion.eggNumber.value, 2);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      final model = Egg(id: 'e1', layDate: layDate, userId: 'u1');
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
