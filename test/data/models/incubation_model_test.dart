import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

Incubation _buildIncubation({
  String id = 'inc-1',
  String userId = 'user-1',
  IncubationStatus status = IncubationStatus.active,
  int version = 1,
  String? clutchId,
  String? breedingPairId,
  String? notes,
  DateTime? startDate,
  DateTime? endDate,
  DateTime? expectedHatchDate,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Incubation(
    id: id,
    userId: userId,
    status: status,
    version: version,
    clutchId: clutchId,
    breedingPairId: breedingPairId,
    notes: notes,
    startDate: startDate,
    endDate: endDate,
    expectedHatchDate: expectedHatchDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('Incubation model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final incubation = _buildIncubation(
          id: 'inc-42',
          userId: 'user-42',
          status: IncubationStatus.completed,
          version: 3,
          clutchId: 'clutch-1',
          breedingPairId: 'pair-1',
          notes: 'Completed successfully',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 20),
          expectedHatchDate: DateTime(2024, 1, 19),
          createdAt: DateTime(2024, 1, 1, 7, 0),
          updatedAt: DateTime(2024, 1, 2, 7, 0),
        );

        final restored = Incubation.fromJson(incubation.toJson());

        expect(restored.id, incubation.id);
        expect(restored.userId, incubation.userId);
        expect(restored.status, incubation.status);
        expect(restored.version, incubation.version);
        expect(restored.clutchId, incubation.clutchId);
        expect(restored.breedingPairId, incubation.breedingPairId);
        expect(restored.notes, incubation.notes);
        expect(restored.startDate, incubation.startDate);
        expect(restored.endDate, incubation.endDate);
        expect(restored.expectedHatchDate, incubation.expectedHatchDate);
        expect(restored.createdAt, incubation.createdAt);
        expect(restored.updatedAt, incubation.updatedAt);
      });

      test('applies default values and nullable fields', () {
        final incubation = Incubation.fromJson({
          'id': 'inc-1',
          'user_id': 'user-1',
        });

        expect(incubation.status, IncubationStatus.active);
        expect(incubation.version, 1);
        expect(incubation.clutchId, isNull);
        expect(incubation.breedingPairId, isNull);
        expect(incubation.startDate, isNull);
        expect(incubation.endDate, isNull);
      });

      test('falls back to active for unknown status', () {
        final incubation = Incubation.fromJson({
          'id': 'inc-1',
          'user_id': 'user-1',
          'status': 'not-a-real-status',
        });

        expect(incubation.status, IncubationStatus.active);
      });
    });

    group('copyWith', () {
      test('updates selected fields and keeps others unchanged', () {
        final incubation = _buildIncubation(status: IncubationStatus.active);
        final updated = incubation.copyWith(
          status: IncubationStatus.cancelled,
          notes: 'Stopped',
        );

        expect(updated.status, IncubationStatus.cancelled);
        expect(updated.notes, 'Stopped');
        expect(updated.id, incubation.id);
        expect(updated.userId, incubation.userId);
      });
    });
  });

  group('IncubationX extension', () {
    test('daysElapsed uses endDate when present', () {
      final incubation = _buildIncubation(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 10),
      );

      expect(incubation.daysElapsed, 9);
    });

    test('daysRemaining clamps at zero', () {
      final incubation = _buildIncubation(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
      );

      expect(incubation.daysRemaining, 0);
    });

    test('percentageComplete is clamped to 1.0', () {
      final incubation = _buildIncubation(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
      );

      expect(incubation.percentageComplete, 1.0);
    });

    test('computedExpectedHatchDate is startDate plus incubation period', () {
      final startDate = DateTime(2024, 1, 1);
      final incubation = _buildIncubation(startDate: startDate);

      expect(
        incubation.computedExpectedHatchDate,
        startDate.add(
          const Duration(days: IncubationConstants.incubationPeriodDays),
        ),
      );
    });

    test('isComplete and isActive reflect status', () {
      final active = _buildIncubation(status: IncubationStatus.active);
      final completed = _buildIncubation(status: IncubationStatus.completed);

      expect(active.isActive, isTrue);
      expect(active.isComplete, isFalse);
      expect(completed.isActive, isFalse);
      expect(completed.isComplete, isTrue);
    });
  });
}
