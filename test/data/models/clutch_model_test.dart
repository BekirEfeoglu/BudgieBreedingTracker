import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';

Clutch _buildClutch({
  String id = 'clutch-1',
  String userId = 'user-1',
  String? name,
  String? breedingId,
  String? incubationId,
  String? maleBirdId,
  String? femaleBirdId,
  String? nestId,
  DateTime? pairDate,
  DateTime? startDate,
  DateTime? endDate,
  BreedingStatus status = BreedingStatus.active,
  String? notes,
  bool isDeleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Clutch(
    id: id,
    userId: userId,
    name: name,
    breedingId: breedingId,
    incubationId: incubationId,
    maleBirdId: maleBirdId,
    femaleBirdId: femaleBirdId,
    nestId: nestId,
    pairDate: pairDate,
    startDate: startDate,
    endDate: endDate,
    status: status,
    notes: notes,
    isDeleted: isDeleted,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('Clutch model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final clutch = _buildClutch(
          id: 'clutch-42',
          userId: 'user-42',
          name: 'Spring clutch',
          breedingId: 'pair-1',
          incubationId: 'inc-1',
          maleBirdId: 'male-1',
          femaleBirdId: 'female-1',
          nestId: 'nest-1',
          pairDate: DateTime(2024, 1, 1),
          startDate: DateTime(2024, 1, 10),
          endDate: DateTime(2024, 2, 1),
          status: BreedingStatus.completed,
          notes: 'Good cycle',
          isDeleted: true,
          createdAt: DateTime(2024, 1, 1, 9, 0),
          updatedAt: DateTime(2024, 1, 2, 9, 0),
        );

        final restored = Clutch.fromJson(clutch.toJson());

        expect(restored.id, clutch.id);
        expect(restored.userId, clutch.userId);
        expect(restored.name, clutch.name);
        expect(restored.breedingId, clutch.breedingId);
        expect(restored.incubationId, clutch.incubationId);
        expect(restored.maleBirdId, clutch.maleBirdId);
        expect(restored.femaleBirdId, clutch.femaleBirdId);
        expect(restored.nestId, clutch.nestId);
        expect(restored.pairDate, clutch.pairDate);
        expect(restored.startDate, clutch.startDate);
        expect(restored.endDate, clutch.endDate);
        expect(restored.status, clutch.status);
        expect(restored.notes, clutch.notes);
        expect(restored.isDeleted, clutch.isDeleted);
        expect(restored.createdAt, clutch.createdAt);
        expect(restored.updatedAt, clutch.updatedAt);
      });

      test('applies defaults when optional values are omitted', () {
        final clutch = Clutch.fromJson({'id': 'clutch-1', 'user_id': 'user-1'});

        expect(clutch.status, BreedingStatus.active);
        expect(clutch.isDeleted, isFalse);
        expect(clutch.name, isNull);
        expect(clutch.breedingId, isNull);
        expect(clutch.incubationId, isNull);
        expect(clutch.maleBirdId, isNull);
        expect(clutch.femaleBirdId, isNull);
        expect(clutch.nestId, isNull);
        expect(clutch.pairDate, isNull);
        expect(clutch.startDate, isNull);
        expect(clutch.endDate, isNull);
        expect(clutch.notes, isNull);
      });

      test('supports nullable field combinations', () {
        final withOnlyBreeding = _buildClutch(breedingId: 'pair-1');
        final withOnlyIncubation = _buildClutch(
          breedingId: null,
          incubationId: 'inc-1',
        );

        expect(withOnlyBreeding.breedingId, 'pair-1');
        expect(withOnlyBreeding.incubationId, isNull);
        expect(withOnlyIncubation.breedingId, isNull);
        expect(withOnlyIncubation.incubationId, 'inc-1');
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final clutch = _buildClutch(name: 'Old name', notes: 'Old note');
        final updated = clutch.copyWith(name: 'New name', notes: 'New note');

        expect(updated.name, 'New name');
        expect(updated.notes, 'New note');
        expect(updated.id, clutch.id);
        expect(updated.userId, clutch.userId);
      });
    });
  });
}
