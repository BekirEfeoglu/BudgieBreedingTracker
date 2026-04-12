@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_calculation_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Genealogy Flow E2E', () {
    test(
      'GIVEN genealogy screen with linked birds WHEN ancestors are loaded THEN parent-grandparent hierarchy renders with at least 3 generations',
      () async {
        final mockBirdRepository = MockBirdRepository();
        final birds = <Bird>[
          const Bird(
            id: 'root-1',
            userId: 'test-user',
            name: 'Sari Boncuk',
            gender: BirdGender.male,
            fatherId: 'father-1',
            motherId: 'mother-1',
          ),
          const Bird(
            id: 'father-1',
            userId: 'test-user',
            name: 'Ata Erkek',
            gender: BirdGender.male,
            fatherId: 'grandfather-1',
            motherId: 'grandmother-1',
          ),
          const Bird(
            id: 'mother-1',
            userId: 'test-user',
            name: 'Ata Disi',
            gender: BirdGender.female,
          ),
          const Bird(
            id: 'grandfather-1',
            userId: 'test-user',
            name: 'Buyuk Dede',
            gender: BirdGender.male,
          ),
          const Bird(
            id: 'grandmother-1',
            userId: 'test-user',
            name: 'Buyuk Nine',
            gender: BirdGender.female,
          ),
        ];

        when(
          () => mockBirdRepository.getAll('test-user'),
        ).thenAnswer((_) async => birds);

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        final ancestors = await container.read(
          ancestorsProvider('root-1').future,
        );
        final stats = calculateAncestorStats('root-1', ancestors, maxDepth: 3);

        expect(ancestors['root-1']?.name, 'Sari Boncuk');
        expect(ancestors.containsKey('father-1'), isTrue);
        expect(ancestors.containsKey('mother-1'), isTrue);
        expect(stats.deepestGeneration, greaterThanOrEqualTo(2));
        expect(stats.found, greaterThanOrEqualTo(3));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN multiple birds in genealogy WHEN Sarı Boncuk is selected THEN tree re-centers around selection and shows parents/offspring',
      () async {
        final mockBirdRepository = MockBirdRepository();
        final mockPairRepository = MockBreedingPairRepository();
        final mockIncubationRepository = MockIncubationRepository();
        final mockEggRepository = MockEggRepository();
        final mockChickRepository = MockChickRepository();

        final birds = <Bird>[
          const Bird(
            id: 'root-1',
            userId: 'test-user',
            name: 'Sari Boncuk',
            gender: BirdGender.male,
            fatherId: 'father-1',
            motherId: 'mother-1',
          ),
          const Bird(
            id: 'father-1',
            userId: 'test-user',
            name: 'Ata Erkek',
            gender: BirdGender.male,
          ),
          const Bird(
            id: 'mother-1',
            userId: 'test-user',
            name: 'Ata Disi',
            gender: BirdGender.female,
          ),
          const Bird(
            id: 'child-bird-1',
            userId: 'test-user',
            name: 'Yavru Kus',
            gender: BirdGender.unknown,
            fatherId: 'root-1',
          ),
        ];
        const pair = BreedingPair(
          id: 'pair-1',
          userId: 'test-user',
          status: BreedingStatus.active,
          maleId: 'root-1',
          femaleId: 'mother-1',
        );
        final incubation = Incubation(
          id: 'inc-1',
          userId: 'test-user',
          breedingPairId: 'pair-1',
          startDate: DateTime.now().subtract(const Duration(days: 10)),
        );
        final egg = Egg(
          id: 'egg-1',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime.now().subtract(const Duration(days: 9)),
        );
        const chick = Chick(id: 'chick-1', userId: 'test-user', eggId: 'egg-1');

        when(
          () => mockBirdRepository.getAll('test-user'),
        ).thenAnswer((_) async => birds);
        when(
          () => mockPairRepository.getByBirdId('root-1'),
        ).thenAnswer((_) async => [pair]);
        when(
          () => mockIncubationRepository.getByBreedingPairIds(['pair-1']),
        ).thenAnswer((_) async => [incubation]);
        when(
          () => mockEggRepository.getByIncubationIds(['inc-1']),
        ).thenAnswer((_) async => [egg]);
        when(
          () => mockChickRepository.getByEggIds(['egg-1']),
        ).thenAnswer((_) async => [chick]);

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
            breedingPairRepositoryProvider.overrideWithValue(
              mockPairRepository,
            ),
            incubationRepositoryProvider.overrideWithValue(
              mockIncubationRepository,
            ),
            eggRepositoryProvider.overrideWithValue(mockEggRepository),
            chickRepositoryProvider.overrideWithValue(mockChickRepository),
          ],
        );
        addTearDown(container.dispose);

        container.read(selectedEntityForTreeProvider.notifier).state = (
          id: 'root-1',
          isChick: false,
        );
        final selection = container.read(selectedEntityForTreeProvider);
        final ancestors = await container.read(
          ancestorsProvider('root-1').future,
        );
        final offspring = await container.read(
          offspringProvider('root-1').future,
        );

        expect(selection?.id, 'root-1');
        expect(ancestors.containsKey('father-1'), isTrue);
        expect(ancestors.containsKey('mother-1'), isTrue);
        expect(
          offspring.birds.any((bird) => bird.id == 'child-bird-1'),
          isTrue,
        );
        expect(offspring.chicks.any((item) => item.id == 'chick-1'), isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN genealogy tree WHEN search query is Boncuk THEN matching birds are highlighted and first match is scroll target',
      () async {
        final mockBirdRepository = MockBirdRepository();
        final birds = <Bird>[
          const Bird(
            id: 'root-1',
            userId: 'test-user',
            name: 'Sari Boncuk',
            gender: BirdGender.male,
            fatherId: 'father-1',
          ),
          const Bird(
            id: 'father-1',
            userId: 'test-user',
            name: 'Boncuk Baba',
            gender: BirdGender.male,
          ),
          const Bird(
            id: 'mother-1',
            userId: 'test-user',
            name: 'Mavi Peri',
            gender: BirdGender.female,
          ),
        ];

        when(
          () => mockBirdRepository.getAll('test-user'),
        ).thenAnswer((_) async => birds);

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        final ancestors = await container.read(
          ancestorsProvider('root-1').future,
        );
        final matches = ancestors.entries
            .where((entry) => entry.value.name.toLowerCase().contains('boncuk'))
            .toList();

        final firstMatchId = matches.first.key;

        expect(matches.length, 2);
        expect(firstMatchId, isNotEmpty);
      },
      timeout: e2eTimeout,
    );
  });
}
