import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/breeding_pair_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';

void main() {
  group('BreedingPairRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final pairingDate = DateTime.utc(2024, 2, 1);
      final row = BreedingPairRow(
        id: 'bp1',
        userId: 'u1',
        status: BreedingStatus.active,
        maleId: 'm1',
        femaleId: 'f1',
        cageNumber: 'C-5',
        notes: 'Good pair',
        pairingDate: pairingDate,
        separationDate: null,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'bp1');
      expect(model.userId, 'u1');
      expect(model.status, BreedingStatus.active);
      expect(model.maleId, 'm1');
      expect(model.femaleId, 'f1');
      expect(model.cageNumber, 'C-5');
      expect(model.notes, 'Good pair');
      expect(model.pairingDate, pairingDate);
      expect(model.separationDate, isNull);
      expect(model.isDeleted, false);
    });
  });

  group('BreedingPairModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = BreedingPair(
        id: 'bp1',
        userId: 'u1',
        status: BreedingStatus.completed,
        maleId: 'm1',
        femaleId: 'f1',
        cageNumber: 'C-3',
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'bp1');
      expect(companion.userId.value, 'u1');
      expect(companion.status.value, BreedingStatus.completed);
      expect(companion.maleId.value, 'm1');
      expect(companion.femaleId.value, 'f1');
      expect(companion.cageNumber.value, 'C-3');
      expect(companion.isDeleted.value, false);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = BreedingPair(id: 'bp1', userId: 'u1');
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
