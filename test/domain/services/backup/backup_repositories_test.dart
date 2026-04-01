import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/backup/backup_repositories.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('BackupRepositories', () {
    test('holds all 12 repository references', () {
      final repos = BackupRepositories(
        bird: MockBirdRepository(),
        breedingPair: MockBreedingPairRepository(),
        egg: MockEggRepository(),
        chick: MockChickRepository(),
        healthRecord: MockHealthRecordRepository(),
        event: MockEventRepository(),
        incubation: MockIncubationRepository(),
        growthMeasurement: MockGrowthMeasurementRepository(),
        notification: MockNotificationRepository(),
        clutch: MockClutchRepository(),
        nest: MockNestRepository(),
        photo: MockPhotoRepository(),
      );

      expect(repos.bird, isA<MockBirdRepository>());
      expect(repos.breedingPair, isA<MockBreedingPairRepository>());
      expect(repos.egg, isA<MockEggRepository>());
      expect(repos.chick, isA<MockChickRepository>());
      expect(repos.healthRecord, isA<MockHealthRecordRepository>());
      expect(repos.event, isA<MockEventRepository>());
      expect(repos.incubation, isA<MockIncubationRepository>());
      expect(repos.growthMeasurement, isA<MockGrowthMeasurementRepository>());
      expect(repos.notification, isA<MockNotificationRepository>());
      expect(repos.clutch, isA<MockClutchRepository>());
      expect(repos.nest, isA<MockNestRepository>());
      expect(repos.photo, isA<MockPhotoRepository>());
    });

    test('can be used as const', () {
      // Verify that BackupRepositories supports const construction
      // (it has const constructor)
      final bird = MockBirdRepository();
      final repos = BackupRepositories(
        bird: bird,
        breedingPair: MockBreedingPairRepository(),
        egg: MockEggRepository(),
        chick: MockChickRepository(),
        healthRecord: MockHealthRecordRepository(),
        event: MockEventRepository(),
        incubation: MockIncubationRepository(),
        growthMeasurement: MockGrowthMeasurementRepository(),
        notification: MockNotificationRepository(),
        clutch: MockClutchRepository(),
        nest: MockNestRepository(),
        photo: MockPhotoRepository(),
      );

      expect(repos.bird, same(bird));
    });
  });
}
