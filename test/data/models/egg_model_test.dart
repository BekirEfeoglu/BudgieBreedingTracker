import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

Egg _buildEgg({
  String id = 'egg-1',
  DateTime? layDate,
  String userId = 'user-1',
  EggStatus status = EggStatus.laid,
  String? clutchId,
  String? incubationId,
  int? eggNumber,
  String? notes,
  String? photoUrl,
  DateTime? hatchDate,
  DateTime? fertileCheckDate,
  DateTime? discardDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
}) {
  return Egg(
    id: id,
    layDate: layDate ?? DateTime(2024, 1, 1),
    userId: userId,
    status: status,
    clutchId: clutchId,
    incubationId: incubationId,
    eggNumber: eggNumber,
    notes: notes,
    photoUrl: photoUrl,
    hatchDate: hatchDate,
    fertileCheckDate: fertileCheckDate,
    discardDate: discardDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

void main() {
  group('Egg model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final egg = _buildEgg(
          id: 'egg-42',
          layDate: DateTime(2024, 1, 10),
          userId: 'user-42',
          status: EggStatus.incubating,
          clutchId: 'clutch-1',
          incubationId: 'incubation-1',
          eggNumber: 3,
          notes: 'Test egg',
          photoUrl: 'https://example.com/egg.jpg',
          hatchDate: DateTime(2024, 1, 28),
          fertileCheckDate: DateTime(2024, 1, 15),
          discardDate: DateTime(2024, 2, 1),
          createdAt: DateTime(2024, 1, 10, 9, 0),
          updatedAt: DateTime(2024, 1, 11, 9, 0),
          isDeleted: true,
        );

        final restored = Egg.fromJson(egg.toJson());

        expect(restored.id, egg.id);
        expect(restored.layDate, egg.layDate);
        expect(restored.userId, egg.userId);
        expect(restored.status, egg.status);
        expect(restored.clutchId, egg.clutchId);
        expect(restored.incubationId, egg.incubationId);
        expect(restored.eggNumber, egg.eggNumber);
        expect(restored.notes, egg.notes);
        expect(restored.photoUrl, egg.photoUrl);
        expect(restored.hatchDate, egg.hatchDate);
        expect(restored.fertileCheckDate, egg.fertileCheckDate);
        expect(restored.discardDate, egg.discardDate);
        expect(restored.createdAt, egg.createdAt);
        expect(restored.updatedAt, egg.updatedAt);
        expect(restored.isDeleted, egg.isDeleted);
      });

      test('applies defaults and keeps nullable fields null', () {
        final egg = Egg.fromJson({
          'id': 'egg-1',
          'lay_date': DateTime(2024, 1, 1).toIso8601String(),
          'user_id': 'user-1',
        });

        expect(egg.status, EggStatus.laid);
        expect(egg.isDeleted, isFalse);
        expect(egg.clutchId, isNull);
        expect(egg.incubationId, isNull);
        expect(egg.eggNumber, isNull);
        expect(egg.hatchDate, isNull);
      });

      test('falls back to laid for unknown status', () {
        final egg = Egg.fromJson({
          'id': 'egg-1',
          'lay_date': DateTime(2024, 1, 1).toIso8601String(),
          'user_id': 'user-1',
          'status': 'not-a-real-status',
        });

        expect(egg.status, EggStatus.laid);
      });

      test('parses all EggStatus values from json', () {
        for (final status in EggStatus.values) {
          final egg = Egg.fromJson({
            'id': 'egg-${status.name}',
            'lay_date': DateTime(2024, 1, 1).toIso8601String(),
            'user_id': 'user-1',
            'status': status.name,
          });
          expect(egg.status, status);
        }
      });
    });

    group('copyWith', () {
      test('updates selected fields and preserves others', () {
        final egg = _buildEgg(status: EggStatus.laid, notes: 'Old');
        final updated = egg.copyWith(status: EggStatus.fertile, notes: 'New');

        expect(updated.status, EggStatus.fertile);
        expect(updated.notes, 'New');
        expect(updated.id, egg.id);
        expect(updated.userId, egg.userId);
      });
    });
  });

  group('EggX extension', () {
    test('incubationDays uses hatchDate when present', () {
      final egg = _buildEgg(
        layDate: DateTime(2024, 1, 1),
        hatchDate: DateTime(2024, 1, 18),
      );

      expect(egg.incubationDays, 17);
    });

    test('incubationDays uses now when hatchDate is null', () {
      final layDate = DateTime.now().subtract(
        const Duration(days: 5, minutes: 1),
      );
      final egg = _buildEgg(layDate: layDate, hatchDate: null);

      final expected = DateTime.now().difference(layDate).inDays;
      expect(egg.incubationDays, expected);
    });

    test('expectedHatchDate is layDate plus incubation period', () {
      final layDate = DateTime(2024, 1, 1);
      final egg = _buildEgg(layDate: layDate);

      expect(
        egg.expectedHatchDate,
        layDate.add(
          const Duration(days: IncubationConstants.incubationPeriodDays),
        ),
      );
    });

    test('isOverdue is true only for non-hatched eggs beyond 18 days', () {
      final overdueEgg = _buildEgg(
        layDate: DateTime.now().subtract(const Duration(days: 19, minutes: 1)),
        status: EggStatus.incubating,
      );
      final hatchedEgg = overdueEgg.copyWith(status: EggStatus.hatched);

      expect(overdueEgg.isOverdue, isTrue);
      expect(hatchedEgg.isOverdue, isFalse);
    });

    test('progressPercent is clamped between 0.0 and 1.0', () {
      final futureEgg = _buildEgg(
        layDate: DateTime.now().add(const Duration(days: 2)),
      );
      final matureEgg = _buildEgg(
        layDate: DateTime.now().subtract(const Duration(days: 40)),
      );
      final midpointEgg = _buildEgg(
        layDate: DateTime.now().subtract(const Duration(days: 9, minutes: 1)),
      );

      expect(futureEgg.progressPercent, 0.0);
      expect(matureEgg.progressPercent, 1.0);
      expect(midpointEgg.progressPercent, closeTo(0.5, 0.01));
    });

    test('boolean status getters return expected values', () {
      final hatched = _buildEgg(status: EggStatus.hatched);
      final fertile = _buildEgg(status: EggStatus.fertile);
      final incubating = _buildEgg(status: EggStatus.incubating);

      expect(hatched.isHatched, isTrue);
      expect(hatched.isFertile, isTrue);
      expect(hatched.isIncubating, isFalse);

      expect(fertile.isHatched, isFalse);
      expect(fertile.isFertile, isTrue);
      expect(fertile.isIncubating, isFalse);

      expect(incubating.isHatched, isFalse);
      expect(incubating.isFertile, isFalse);
      expect(incubating.isIncubating, isTrue);
    });
  });

  group('EggStatus enum', () {
    test('toJson and fromJson work for all values', () {
      for (final status in EggStatus.values) {
        final json = status.toJson();
        expect(EggStatus.fromJson(json), status);
      }
    });
  });
}
