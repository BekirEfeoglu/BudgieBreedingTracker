import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';

BreedingPair _buildPair({
  String id = 'pair-1',
  String userId = 'user-1',
  BreedingStatus status = BreedingStatus.active,
  String? maleId,
  String? femaleId,
  String? cageNumber,
  String? notes,
  DateTime? pairingDate,
  DateTime? separationDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
}) {
  return BreedingPair(
    id: id,
    userId: userId,
    status: status,
    maleId: maleId,
    femaleId: femaleId,
    cageNumber: cageNumber,
    notes: notes,
    pairingDate: pairingDate,
    separationDate: separationDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

void main() {
  group('BreedingPair model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final pair = _buildPair(
          id: 'pair-42',
          userId: 'user-42',
          status: BreedingStatus.ongoing,
          maleId: 'bird-male',
          femaleId: 'bird-female',
          cageNumber: 'C-12',
          notes: 'Active pair',
          pairingDate: DateTime(2024, 1, 1),
          separationDate: DateTime(2024, 3, 1),
          createdAt: DateTime(2024, 1, 1, 8, 0),
          updatedAt: DateTime(2024, 1, 2, 8, 0),
          isDeleted: true,
        );

        final restored = BreedingPair.fromJson(pair.toJson());

        expect(restored.id, pair.id);
        expect(restored.userId, pair.userId);
        expect(restored.status, pair.status);
        expect(restored.maleId, pair.maleId);
        expect(restored.femaleId, pair.femaleId);
        expect(restored.cageNumber, pair.cageNumber);
        expect(restored.notes, pair.notes);
        expect(restored.pairingDate, pair.pairingDate);
        expect(restored.separationDate, pair.separationDate);
        expect(restored.createdAt, pair.createdAt);
        expect(restored.updatedAt, pair.updatedAt);
        expect(restored.isDeleted, pair.isDeleted);
      });

      test('applies defaults and keeps nullable fields null', () {
        final pair = BreedingPair.fromJson({
          'id': 'pair-1',
          'user_id': 'user-1',
        });

        expect(pair.status, BreedingStatus.active);
        expect(pair.isDeleted, isFalse);
        expect(pair.maleId, isNull);
        expect(pair.femaleId, isNull);
        expect(pair.cageNumber, isNull);
        expect(pair.notes, isNull);
        expect(pair.pairingDate, isNull);
        expect(pair.separationDate, isNull);
      });

      test('falls back to active for unknown status', () {
        final pair = BreedingPair.fromJson({
          'id': 'pair-1',
          'user_id': 'user-1',
          'status': 'not-real-status',
        });

        expect(pair.status, BreedingStatus.active);
      });
    });

    group('copyWith', () {
      test('updates fields without mutating original', () {
        final pair = _buildPair(cageNumber: 'A-1', notes: 'Old');
        final updated = pair.copyWith(cageNumber: 'B-2', notes: 'New');

        expect(updated.cageNumber, 'B-2');
        expect(updated.notes, 'New');
        expect(pair.cageNumber, 'A-1');
        expect(pair.notes, 'Old');
      });
    });
  });
}
