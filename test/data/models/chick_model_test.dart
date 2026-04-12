import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

Chick _buildChick({
  String id = 'chick-1',
  String userId = 'user-1',
  BirdGender gender = BirdGender.unknown,
  ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
  String? clutchId,
  String? eggId,
  String? birdId,
  String? name,
  String? ringNumber,
  int bandingDay = 10,
  DateTime? bandingDate,
  String? notes,
  String? photoUrl,
  double? hatchWeight,
  DateTime? hatchDate,
  DateTime? weanDate,
  DateTime? deathDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
}) {
  return Chick(
    id: id,
    userId: userId,
    gender: gender,
    healthStatus: healthStatus,
    clutchId: clutchId,
    eggId: eggId,
    birdId: birdId,
    name: name,
    ringNumber: ringNumber,
    bandingDay: bandingDay,
    bandingDate: bandingDate,
    notes: notes,
    photoUrl: photoUrl,
    hatchWeight: hatchWeight,
    hatchDate: hatchDate,
    weanDate: weanDate,
    deathDate: deathDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

void main() {
  group('Chick model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final chick = _buildChick(
          id: 'chick-42',
          userId: 'user-42',
          gender: BirdGender.female,
          healthStatus: ChickHealthStatus.sick,
          clutchId: 'clutch-1',
          eggId: 'egg-1',
          birdId: 'bird-1',
          name: 'Mini',
          ringNumber: 'TR-CH-1',
          bandingDay: 14,
          bandingDate: DateTime(2024, 2, 3),
          notes: 'Needs monitoring',
          photoUrl: 'https://example.com/chick.jpg',
          hatchWeight: 3.6,
          hatchDate: DateTime(2024, 1, 20),
          weanDate: DateTime(2024, 3, 1),
          deathDate: DateTime(2025, 1, 1),
          createdAt: DateTime(2024, 1, 20, 10, 0),
          updatedAt: DateTime(2024, 1, 21, 10, 0),
          isDeleted: true,
        );

        final restored = Chick.fromJson(chick.toJson());

        expect(restored.id, chick.id);
        expect(restored.userId, chick.userId);
        expect(restored.gender, chick.gender);
        expect(restored.healthStatus, chick.healthStatus);
        expect(restored.clutchId, chick.clutchId);
        expect(restored.eggId, chick.eggId);
        expect(restored.birdId, chick.birdId);
        expect(restored.name, chick.name);
        expect(restored.ringNumber, chick.ringNumber);
        expect(restored.bandingDay, chick.bandingDay);
        expect(restored.bandingDate, chick.bandingDate);
        expect(restored.notes, chick.notes);
        expect(restored.photoUrl, chick.photoUrl);
        expect(restored.hatchWeight, chick.hatchWeight);
        expect(restored.hatchDate, chick.hatchDate);
        expect(restored.weanDate, chick.weanDate);
        expect(restored.deathDate, chick.deathDate);
        expect(restored.createdAt, chick.createdAt);
        expect(restored.updatedAt, chick.updatedAt);
        expect(restored.isDeleted, chick.isDeleted);
      });

      test('applies defaults and keeps nullable fields null', () {
        final chick = Chick.fromJson({'id': 'chick-1', 'user_id': 'user-1'});

        expect(chick.gender, BirdGender.unknown);
        expect(chick.healthStatus, ChickHealthStatus.healthy);
        expect(chick.isDeleted, isFalse);
        expect(chick.hatchDate, isNull);
        expect(chick.weanDate, isNull);
        expect(chick.clutchId, isNull);
        expect(chick.eggId, isNull);
        expect(chick.bandingDay, 10);
        expect(chick.bandingDate, isNull);
      });

      test('parses unknown enums with configured fallbacks', () {
        final chick = Chick.fromJson({
          'id': 'chick-1',
          'user_id': 'user-1',
          'gender': 'invalid-gender',
          'health_status': 'invalid-health',
        });

        expect(chick.gender, BirdGender.unknown);
        expect(chick.healthStatus, ChickHealthStatus.unknown);
      });
    });

    group('copyWith', () {
      test('updates selected fields and preserves others', () {
        final chick = _buildChick(name: 'Old Name', notes: 'Old note');
        final updated = chick.copyWith(name: 'New Name', notes: 'New note');

        expect(updated.name, 'New Name');
        expect(updated.notes, 'New note');
        expect(updated.id, chick.id);
        expect(updated.userId, chick.userId);
      });
    });
  });

  group('ChickX extension', () {
    test('age returns null when hatchDate is null', () {
      final chick = _buildChick(hatchDate: null);
      expect(chick.age, isNull);
    });

    test('age returns weeks, days and totalDays', () {
      final hatchDate = DateTime.now().subtract(
        const Duration(days: 17, minutes: 1),
      );
      final chick = _buildChick(hatchDate: hatchDate);

      final age = chick.age!;
      expect(age.totalDays, 17);
      expect(age.weeks, 2);
      expect(age.days, 3);
    });

    test('developmentStage is newborn for 0-7 days', () {
      final stageAt0Days = _buildChick(
        hatchDate: DateTime.now().subtract(const Duration(minutes: 1)),
      ).developmentStage;
      final stageAt7Days = _buildChick(
        hatchDate: DateTime.now().subtract(const Duration(days: 7, minutes: 1)),
      ).developmentStage;

      expect(stageAt0Days, DevelopmentStage.newborn);
      expect(stageAt7Days, DevelopmentStage.newborn);
    });

    test('developmentStage is nestling for 8-21 days', () {
      final stageAt8Days = _buildChick(
        hatchDate: DateTime.now().subtract(const Duration(days: 8, minutes: 1)),
      ).developmentStage;
      final stageAt21Days = _buildChick(
        hatchDate: DateTime.now().subtract(
          const Duration(days: 21, minutes: 1),
        ),
      ).developmentStage;

      expect(stageAt8Days, DevelopmentStage.nestling);
      expect(stageAt21Days, DevelopmentStage.nestling);
    });

    test('developmentStage is fledgling for 22-35 days', () {
      final stageAt22Days = _buildChick(
        hatchDate: DateTime.now().subtract(
          const Duration(days: 22, minutes: 1),
        ),
      ).developmentStage;
      final stageAt35Days = _buildChick(
        hatchDate: DateTime.now().subtract(
          const Duration(days: 35, minutes: 1),
        ),
      ).developmentStage;

      expect(stageAt22Days, DevelopmentStage.fledgling);
      expect(stageAt35Days, DevelopmentStage.fledgling);
    });

    test('developmentStage is juvenile for 36+ days', () {
      final stage = _buildChick(
        hatchDate: DateTime.now().subtract(
          const Duration(days: 36, minutes: 1),
        ),
      ).developmentStage;
      expect(stage, DevelopmentStage.juvenile);
    });

    test('isWeaned is true when weanDate exists', () {
      final weaned = _buildChick(weanDate: DateTime(2024, 2, 1));
      final notWeaned = _buildChick(weanDate: null);

      expect(weaned.isWeaned, isTrue);
      expect(notWeaned.isWeaned, isFalse);
    });

    test('isBanded is true when bandingDate is set', () {
      final banded = _buildChick(bandingDate: DateTime(2024, 1, 30));
      final notBanded = _buildChick(bandingDate: null);

      expect(banded.isBanded, isTrue);
      expect(notBanded.isBanded, isFalse);
    });

    test('plannedBandingDate is null when hatchDate is null', () {
      final chick = _buildChick(hatchDate: null, bandingDay: 10);
      expect(chick.plannedBandingDate, isNull);
    });

    test('plannedBandingDate is hatchDate + bandingDay days', () {
      final hatchDate = DateTime(2024, 1, 20);
      final chick = _buildChick(hatchDate: hatchDate, bandingDay: 10);
      expect(chick.plannedBandingDate, DateTime(2024, 1, 30));
    });

    test('plannedBandingDate respects custom bandingDay', () {
      final hatchDate = DateTime(2024, 3, 1);
      final chick = _buildChick(hatchDate: hatchDate, bandingDay: 14);
      expect(chick.plannedBandingDate, DateTime(2024, 3, 15));
    });
  });
}
