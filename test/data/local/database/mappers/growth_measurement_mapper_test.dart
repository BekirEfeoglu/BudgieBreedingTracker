import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/growth_measurement_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';

void main() {
  final measureDate = DateTime.utc(2024, 4, 1);

  group('GrowthMeasurementRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = GrowthMeasurementRow(
        id: 'gm1',
        chickId: 'c1',
        weight: 25.5,
        measurementDate: measureDate,
        userId: 'u1',
        height: 5.0,
        wingLength: 3.2,
        tailLength: 1.5,
        notes: 'Growing well',
      );
      final model = row.toModel();

      expect(model.id, 'gm1');
      expect(model.chickId, 'c1');
      expect(model.weight, 25.5);
      expect(model.measurementDate, measureDate);
      expect(model.userId, 'u1');
      expect(model.height, 5.0);
      expect(model.wingLength, 3.2);
      expect(model.tailLength, 1.5);
      expect(model.notes, 'Growing well');
    });

    test('handles null optional fields', () {
      final row = GrowthMeasurementRow(
        id: 'gm2',
        chickId: 'c1',
        weight: 20.0,
        measurementDate: measureDate,
        userId: 'u1',
      );
      final model = row.toModel();

      expect(model.height, isNull);
      expect(model.wingLength, isNull);
      expect(model.tailLength, isNull);
      expect(model.notes, isNull);
    });
  });

  group('GrowthMeasurementModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      final model = GrowthMeasurement(
        id: 'gm1',
        chickId: 'c1',
        weight: 30.0,
        measurementDate: measureDate,
        userId: 'u1',
        height: 6.0,
        wingLength: 4.0,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'gm1');
      expect(companion.chickId.value, 'c1');
      expect(companion.weight.value, 30.0);
      expect(companion.measurementDate.value, measureDate);
      expect(companion.userId.value, 'u1');
      expect(companion.height.value, 6.0);
      expect(companion.wingLength.value, 4.0);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      final model = GrowthMeasurement(
        id: 'gm1',
        chickId: 'c1',
        weight: 20.0,
        measurementDate: measureDate,
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
