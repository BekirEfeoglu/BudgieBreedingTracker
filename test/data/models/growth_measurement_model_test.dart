import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';

GrowthMeasurement _buildMeasurement({
  String id = 'gm-1',
  String chickId = 'chick-1',
  double weight = 14.2,
  DateTime? measurementDate,
  String userId = 'user-1',
  double? height,
  double? wingLength,
  double? tailLength,
  String? notes,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return GrowthMeasurement(
    id: id,
    chickId: chickId,
    weight: weight,
    measurementDate: measurementDate ?? DateTime(2024, 2, 1),
    userId: userId,
    height: height,
    wingLength: wingLength,
    tailLength: tailLength,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('GrowthMeasurement model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final measurement = _buildMeasurement(
          id: 'gm-42',
          chickId: 'chick-42',
          weight: 20.1,
          measurementDate: DateTime(2024, 3, 1),
          userId: 'user-42',
          height: 7.3,
          wingLength: 5.2,
          tailLength: 4.8,
          notes: 'Healthy growth',
          createdAt: DateTime(2024, 3, 1, 8, 0),
          updatedAt: DateTime(2024, 3, 1, 9, 0),
        );

        final restored = GrowthMeasurement.fromJson(measurement.toJson());

        expect(restored, measurement);
      });

      test('keeps nullable fields null', () {
        final measurement = GrowthMeasurement.fromJson({
          'id': 'gm-1',
          'chick_id': 'chick-1',
          'weight': 12.5,
          'measurement_date': DateTime(2024, 1, 1).toIso8601String(),
          'user_id': 'user-1',
        });

        expect(measurement.height, isNull);
        expect(measurement.wingLength, isNull);
        expect(measurement.tailLength, isNull);
        expect(measurement.notes, isNull);
      });
    });

    group('copyWith', () {
      test('updates selected fields and preserves others', () {
        final measurement = _buildMeasurement(weight: 15.0, notes: 'Old');
        final updated = measurement.copyWith(weight: 16.5, notes: 'New');

        expect(updated.weight, 16.5);
        expect(updated.notes, 'New');
        expect(updated.id, measurement.id);
        expect(updated.chickId, measurement.chickId);
      });
    });
  });
}
