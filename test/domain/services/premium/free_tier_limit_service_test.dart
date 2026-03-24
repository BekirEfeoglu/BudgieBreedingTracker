import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_service.dart';

class MockBirdRepository extends Mock implements BirdRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

void main() {
  late FreeTierLimitService service;
  late MockBirdRepository mockBirdRepo;
  late MockBreedingPairRepository mockBreedingRepo;
  late MockIncubationRepository mockIncubationRepo;

  setUp(() {
    mockBirdRepo = MockBirdRepository();
    mockBreedingRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    service = FreeTierLimitService(
      birdRepo: mockBirdRepo,
      breedingPairRepo: mockBreedingRepo,
      incubationRepo: mockIncubationRepo,
    );
  });

  group('guardBirdLimit', () {
    test('does not throw when under limit', () async {
      final birds = List.generate(
        AppConstants.freeTierMaxBirds - 1,
        (i) => Bird(
          id: '$i',
          userId: 'u1',
          name: 'Bird $i',
          gender: BirdGender.male,
        ),
      );
      when(() => mockBirdRepo.getAll('u1')).thenAnswer((_) async => birds);

      await expectLater(service.guardBirdLimit('u1'), completes);
    });

    test('throws FreeTierLimitException at limit', () async {
      final birds = List.generate(
        AppConstants.freeTierMaxBirds,
        (i) => Bird(
          id: '$i',
          userId: 'u1',
          name: 'Bird $i',
          gender: BirdGender.male,
        ),
      );
      when(() => mockBirdRepo.getAll('u1')).thenAnswer((_) async => birds);

      await expectLater(
        service.guardBirdLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('throws FreeTierLimitException above limit', () async {
      final birds = List.generate(
        AppConstants.freeTierMaxBirds + 2,
        (i) => Bird(
          id: '$i',
          userId: 'u1',
          name: 'Bird $i',
          gender: BirdGender.female,
        ),
      );
      when(() => mockBirdRepo.getAll('u1')).thenAnswer((_) async => birds);

      await expectLater(
        service.guardBirdLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('does not throw when list is empty', () async {
      when(() => mockBirdRepo.getAll('u1')).thenAnswer((_) async => []);

      await expectLater(service.guardBirdLimit('u1'), completes);
    });
  });

  group('guardBreedingPairLimit', () {
    test('does not throw when only completed pairs exist', () async {
      final pairs = [
        const BreedingPair(
          id: '1',
          userId: 'u1',
          status: BreedingStatus.completed,
        ),
      ];
      when(() => mockBreedingRepo.getAll('u1')).thenAnswer((_) async => pairs);

      await expectLater(service.guardBreedingPairLimit('u1'), completes);
    });

    test('does not throw when only cancelled pairs exist', () async {
      final pairs = List.generate(
        AppConstants.freeTierMaxBreedingPairs + 5,
        (i) => BreedingPair(
          id: '$i',
          userId: 'u1',
          status: BreedingStatus.cancelled,
        ),
      );
      when(() => mockBreedingRepo.getAll('u1')).thenAnswer((_) async => pairs);

      await expectLater(service.guardBreedingPairLimit('u1'), completes);
    });

    test('throws when active pairs reach limit', () async {
      final pairs = List.generate(
        AppConstants.freeTierMaxBreedingPairs,
        (i) => BreedingPair(
          id: '$i',
          userId: 'u1',
          maleId: 'm$i',
          femaleId: 'f$i',
          status: BreedingStatus.active,
        ),
      );
      when(() => mockBreedingRepo.getAll('u1')).thenAnswer((_) async => pairs);

      await expectLater(
        service.guardBreedingPairLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('throws when ongoing pairs reach limit', () async {
      final pairs = List.generate(
        AppConstants.freeTierMaxBreedingPairs,
        (i) => BreedingPair(
          id: '$i',
          userId: 'u1',
          status: BreedingStatus.ongoing,
        ),
      );
      when(() => mockBreedingRepo.getAll('u1')).thenAnswer((_) async => pairs);

      await expectLater(
        service.guardBreedingPairLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('counts both active and ongoing pairs together', () async {
      // Mix of active and ongoing that together hit the limit
      final activePairs = List.generate(
        AppConstants.freeTierMaxBreedingPairs - 1,
        (i) => BreedingPair(
          id: 'active_$i',
          userId: 'u1',
          status: BreedingStatus.active,
        ),
      );
      final ongoingPairs = [
        const BreedingPair(
          id: 'ongoing_0',
          userId: 'u1',
          status: BreedingStatus.ongoing,
        ),
      ];
      when(() => mockBreedingRepo.getAll('u1'))
          .thenAnswer((_) async => [...activePairs, ...ongoingPairs]);

      await expectLater(
        service.guardBreedingPairLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('does not throw when under limit with mixed statuses', () async {
      final pairs = [
        const BreedingPair(id: '1', userId: 'u1', status: BreedingStatus.active),
        const BreedingPair(id: '2', userId: 'u1', status: BreedingStatus.completed),
        const BreedingPair(id: '3', userId: 'u1', status: BreedingStatus.cancelled),
      ];
      when(() => mockBreedingRepo.getAll('u1')).thenAnswer((_) async => pairs);

      await expectLater(service.guardBreedingPairLimit('u1'), completes);
    });
  });

  group('guardIncubationLimit', () {
    test('does not throw when list is empty', () async {
      when(() => mockIncubationRepo.getAll('u1')).thenAnswer((_) async => []);

      await expectLater(service.guardIncubationLimit('u1'), completes);
    });

    test('does not throw when under limit', () async {
      final incubations = List.generate(
        AppConstants.freeTierMaxActiveIncubations - 1,
        (i) => Incubation(
          id: '$i',
          userId: 'u1',
          status: IncubationStatus.active,
        ),
      );
      when(() => mockIncubationRepo.getAll('u1'))
          .thenAnswer((_) async => incubations);

      await expectLater(service.guardIncubationLimit('u1'), completes);
    });

    test('throws when active incubations reach limit', () async {
      final incubations = List.generate(
        AppConstants.freeTierMaxActiveIncubations,
        (i) => Incubation(
          id: '$i',
          userId: 'u1',
          status: IncubationStatus.active,
        ),
      );
      when(() => mockIncubationRepo.getAll('u1'))
          .thenAnswer((_) async => incubations);

      await expectLater(
        service.guardIncubationLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('does not count completed incubations toward limit', () async {
      final incubations = List.generate(
        AppConstants.freeTierMaxActiveIncubations + 10,
        (i) => Incubation(
          id: '$i',
          userId: 'u1',
          status: IncubationStatus.completed,
        ),
      );
      when(() => mockIncubationRepo.getAll('u1'))
          .thenAnswer((_) async => incubations);

      await expectLater(service.guardIncubationLimit('u1'), completes);
    });

    test('does not count cancelled incubations toward limit', () async {
      final incubations = List.generate(
        AppConstants.freeTierMaxActiveIncubations + 5,
        (i) => Incubation(
          id: '$i',
          userId: 'u1',
          status: IncubationStatus.cancelled,
        ),
      );
      when(() => mockIncubationRepo.getAll('u1'))
          .thenAnswer((_) async => incubations);

      await expectLater(service.guardIncubationLimit('u1'), completes);
    });
  });
}
