import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';

Nest _buildNest({
  String id = 'nest-1',
  String userId = 'user-1',
  String? name,
  String? location,
  NestStatus status = NestStatus.available,
  String? notes,
  bool isDeleted = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Nest(
    id: id,
    userId: userId,
    name: name,
    location: location,
    status: status,
    notes: notes,
    isDeleted: isDeleted,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('Nest model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final nest = _buildNest(
          id: 'nest-42',
          userId: 'user-42',
          name: 'Nest A',
          location: 'Cage 3',
          status: NestStatus.occupied,
          notes: 'Wooden nest',
          isDeleted: true,
          createdAt: DateTime(2024, 1, 1, 8, 0),
          updatedAt: DateTime(2024, 1, 1, 9, 0),
        );

        final restored = Nest.fromJson(nest.toJson());
        expect(restored, nest);
      });

      test('applies defaults for status and isDeleted', () {
        final nest = Nest.fromJson({'id': 'nest-1', 'user_id': 'user-1'});

        expect(nest.status, NestStatus.available);
        expect(nest.isDeleted, isFalse);
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final nest = _buildNest(name: 'Old', status: NestStatus.available);
        final updated = nest.copyWith(name: 'New', status: NestStatus.occupied);

        expect(updated.name, 'New');
        expect(updated.status, NestStatus.occupied);
        expect(updated.id, nest.id);
        expect(updated.userId, nest.userId);
      });
    });
  });
}
