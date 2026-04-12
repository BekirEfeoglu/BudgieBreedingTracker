import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  const userId = 'user-1';

  group('freeTierLimitServiceProvider', () {
    late MockBirdRepository birdRepository;
    late MockBreedingPairRepository breedingPairRepository;
    late MockIncubationRepository incubationRepository;

    setUp(() {
      birdRepository = MockBirdRepository();
      breedingPairRepository = MockBreedingPairRepository();
      incubationRepository = MockIncubationRepository();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          birdRepositoryProvider.overrideWithValue(birdRepository),
          breedingPairRepositoryProvider.overrideWithValue(
            breedingPairRepository,
          ),
          incubationRepositoryProvider.overrideWithValue(incubationRepository),
        ],
      );
    }

    test('uses overridden bird repository for bird limit checks', () async {
      when(() => birdRepository.getCount(userId)).thenAnswer((_) async => 0);
      final container = createContainer();
      addTearDown(container.dispose);

      final service = container.read(freeTierLimitServiceProvider);
      await service.guardBirdLimit(userId);

      verify(() => birdRepository.getCount(userId)).called(1);
      verifyZeroInteractions(breedingPairRepository);
      verifyZeroInteractions(incubationRepository);
    });

    test(
      'uses overridden breeding pair repository for breeding limit checks',
      () async {
        when(
          () => breedingPairRepository.getActiveCount(userId),
        ).thenAnswer((_) async => 0);
        final container = createContainer();
        addTearDown(container.dispose);

        final service = container.read(freeTierLimitServiceProvider);
        await service.guardBreedingPairLimit(userId);

        verify(() => breedingPairRepository.getActiveCount(userId)).called(1);
        verifyZeroInteractions(birdRepository);
        verifyZeroInteractions(incubationRepository);
      },
    );

    test(
      'uses overridden incubation repository for incubation limit checks',
      () async {
        when(
          () => incubationRepository.getActiveCount(userId),
        ).thenAnswer((_) async => 0);
        final container = createContainer();
        addTearDown(container.dispose);

        final service = container.read(freeTierLimitServiceProvider);
        await service.guardIncubationLimit(userId);

        verify(() => incubationRepository.getActiveCount(userId)).called(1);
        verifyZeroInteractions(birdRepository);
        verifyZeroInteractions(breedingPairRepository);
      },
    );
  });
}
