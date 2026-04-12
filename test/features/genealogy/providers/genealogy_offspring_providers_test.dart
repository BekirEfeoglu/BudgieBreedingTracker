import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  late MockBirdRepository mockBirdRepo;
  late MockBreedingPairRepository mockPairRepo;
  late MockIncubationRepository mockIncubationRepo;
  late MockEggRepository mockEggRepo;
  late MockChickRepository mockChickRepo;

  setUp(() {
    mockBirdRepo = MockBirdRepository();
    mockPairRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    mockEggRepo = MockEggRepository();
    mockChickRepo = MockChickRepository();
  });

  ProviderContainer createContainer({int pedigreeDepth = 5}) {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        breedingPairRepositoryProvider.overrideWithValue(mockPairRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        eggRepositoryProvider.overrideWithValue(mockEggRepo),
        chickRepositoryProvider.overrideWithValue(mockChickRepo),
        pedigreeDepthProvider.overrideWith(() => _TestPedigreeDepthNotifier(pedigreeDepth)),
      ],
    );
  }

  group('offspringProvider', () {
    test('returns bird offspring via fatherId/motherId', () async {
      final father = createTestBird(id: 'father-1', gender: BirdGender.male);
      final child1 = createTestBird(
        id: 'child-1',
        fatherId: 'father-1',
        gender: BirdGender.female,
      );
      final child2 = createTestBird(
        id: 'child-2',
        motherId: 'father-1',
        gender: BirdGender.male,
      );
      final unrelated = createTestBird(id: 'unrelated');

      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => [father, child1, child2, unrelated]);
      when(() => mockPairRepo.getByBirdId('father-1'))
          .thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(offspringProvider('father-1').future);

      expect(result.birds, hasLength(2));
      expect(result.birds.map((b) => b.id), containsAll(['child-1', 'child-2']));
      expect(result.chicks, isEmpty);
    });

    test('returns chick offspring via breeding pair chain', () async {
      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => []);

      when(() => mockPairRepo.getByBirdId('bird-1')).thenAnswer(
        (_) async => [
          const BreedingPair(
            id: 'pair-1',
            userId: 'user-1',
            maleId: 'bird-1',
            femaleId: 'female-1',
          ),
        ],
      );

      when(() => mockIncubationRepo.getByBreedingPairIds(['pair-1']))
          .thenAnswer(
        (_) async => [
          const Incubation(id: 'inc-1', userId: 'user-1', breedingPairId: 'pair-1'),
        ],
      );

      when(() => mockEggRepo.getByIncubationIds(['inc-1'])).thenAnswer(
        (_) async => [
          Egg(id: 'egg-1', userId: 'user-1', incubationId: 'inc-1', layDate: DateTime(2024)),
        ],
      );

      when(() => mockChickRepo.getByEggIds(['egg-1'])).thenAnswer(
        (_) async => [
          const Chick(
            id: 'chick-1',
            userId: 'user-1',
            eggId: 'egg-1',
            gender: BirdGender.unknown,
            healthStatus: ChickHealthStatus.healthy,
          ),
        ],
      );

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(offspringProvider('bird-1').future);

      expect(result.birds, isEmpty);
      expect(result.chicks, hasLength(1));
      expect(result.chicks.first.id, 'chick-1');
    });

    test('excludes promoted chicks (those with birdId set)', () async {
      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => []);

      when(() => mockPairRepo.getByBirdId('bird-1')).thenAnswer(
        (_) async => [
          const BreedingPair(
            id: 'pair-1',
            userId: 'user-1',
            maleId: 'bird-1',
            femaleId: 'female-1',
          ),
        ],
      );
      when(() => mockIncubationRepo.getByBreedingPairIds(['pair-1']))
          .thenAnswer(
        (_) async => [
          const Incubation(id: 'inc-1', userId: 'user-1', breedingPairId: 'pair-1'),
        ],
      );
      when(() => mockEggRepo.getByIncubationIds(['inc-1'])).thenAnswer(
        (_) async => [
          Egg(id: 'egg-1', userId: 'user-1', incubationId: 'inc-1', layDate: DateTime(2024)),
        ],
      );
      when(() => mockChickRepo.getByEggIds(['egg-1'])).thenAnswer(
        (_) async => [
          const Chick(
            id: 'chick-promoted',
            userId: 'user-1',
            eggId: 'egg-1',
            birdId: 'promoted-bird-id',
            gender: BirdGender.unknown,
            healthStatus: ChickHealthStatus.healthy,
          ),
        ],
      );

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(offspringProvider('bird-1').future);

      expect(result.chicks, isEmpty);
    });

    test('returns empty when bird has no offspring', () async {
      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => [createTestBird(id: 'bird-1')]);
      when(() => mockPairRepo.getByBirdId('bird-1'))
          .thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(offspringProvider('bird-1').future);

      expect(result.birds, isEmpty);
      expect(result.chicks, isEmpty);
    });

    test('handles chick resolution failure gracefully', () async {
      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockPairRepo.getByBirdId('bird-1'))
          .thenThrow(Exception('DB error'));

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(offspringProvider('bird-1').future);

      // Bird offspring is empty (no matches), chick resolution failed gracefully
      expect(result.birds, isEmpty);
      expect(result.chicks, isEmpty);
    });
  });

  group('chickAncestorsProvider', () {
    test('returns empty map when chick not found', () async {
      when(() => mockChickRepo.getById('missing'))
          .thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(chickAncestorsProvider('missing').future);

      expect(result, isEmpty);
    });

    test('returns pseudo-bird for chick with no egg', () async {
      when(() => mockChickRepo.getById('chick-1')).thenAnswer(
        (_) async => const Chick(
          id: 'chick-1',
          userId: 'user-1',
          name: 'Baby',
          gender: BirdGender.female,
          healthStatus: ChickHealthStatus.healthy,
        ),
      );
      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(chickAncestorsProvider('chick-1').future);

      expect(result, hasLength(1));
      expect(result['chick-1'], isNotNull);
      expect(result['chick-1']!.name, 'Baby');
      expect(result['chick-1']!.gender, BirdGender.female);
    });

    test('resolves parent chain from egg to breeding pair', () async {
      when(() => mockChickRepo.getById('chick-1')).thenAnswer(
        (_) async => const Chick(
          id: 'chick-1',
          userId: 'user-1',
          eggId: 'egg-1',
          gender: BirdGender.unknown,
          healthStatus: ChickHealthStatus.healthy,
        ),
      );
      when(() => mockEggRepo.getById('egg-1')).thenAnswer(
        (_) async => Egg(
          id: 'egg-1',
          userId: 'user-1',
          incubationId: 'inc-1',
          layDate: DateTime(2024),
        ),
      );
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          breedingPairId: 'pair-1',
        ),
      );
      when(() => mockPairRepo.getById('pair-1')).thenAnswer(
        (_) async => const BreedingPair(
          id: 'pair-1',
          userId: 'user-1',
          maleId: 'father-1',
          femaleId: 'mother-1',
        ),
      );

      final father = createTestBird(id: 'father-1', gender: BirdGender.male);
      final mother =
          createTestBird(id: 'mother-1', gender: BirdGender.female);

      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => [father, mother]);

      final container = createContainer();
      addTearDown(container.dispose);

      final result =
          await container.read(chickAncestorsProvider('chick-1').future);

      // Should contain pseudo-bird for chick + father + mother
      expect(result, hasLength(3));
      expect(result.containsKey('chick-1'), isTrue);
      expect(result.containsKey('father-1'), isTrue);
      expect(result.containsKey('mother-1'), isTrue);
      // Pseudo-bird should have parent IDs set
      expect(result['chick-1']!.fatherId, 'father-1');
      expect(result['chick-1']!.motherId, 'mother-1');
    });
  });

  group('treeViewModeProvider', () {
    test('default is tree mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(treeViewModeProvider), TreeViewMode.tree);
    });

    test('can be changed to list mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(treeViewModeProvider.notifier).state = TreeViewMode.list;
      expect(container.read(treeViewModeProvider), TreeViewMode.list);
    });

    test('can toggle back to tree mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(treeViewModeProvider.notifier).state = TreeViewMode.list;
      container.read(treeViewModeProvider.notifier).state = TreeViewMode.tree;
      expect(container.read(treeViewModeProvider), TreeViewMode.tree);
    });
  });

  group('repairOrphanBirdsProvider', () {
    test('repairs bird with null parents when chick-egg-pair chain exists',
        () async {
      final orphanBird = createTestBird(
        id: 'bird-orphan',
        fatherId: null,
        motherId: null,
      );

      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => [orphanBird]);
      when(() => mockChickRepo.getAll('user-1')).thenAnswer(
        (_) async => [
          const Chick(
            id: 'chick-1',
            userId: 'user-1',
            eggId: 'egg-1',
            birdId: 'bird-orphan',
            gender: BirdGender.unknown,
            healthStatus: ChickHealthStatus.healthy,
          ),
        ],
      );
      when(() => mockEggRepo.getAll('user-1')).thenAnswer(
        (_) async => [
          Egg(
            id: 'egg-1',
            userId: 'user-1',
            incubationId: 'inc-1',
            layDate: DateTime(2024),
          ),
        ],
      );
      when(() => mockIncubationRepo.getAll('user-1')).thenAnswer(
        (_) async => [
          const Incubation(
            id: 'inc-1',
            userId: 'user-1',
            breedingPairId: 'pair-1',
          ),
        ],
      );
      when(() => mockPairRepo.getAll('user-1')).thenAnswer(
        (_) async => [
          const BreedingPair(
            id: 'pair-1',
            userId: 'user-1',
            maleId: 'father-1',
            femaleId: 'mother-1',
          ),
        ],
      );
      when(() => mockBirdRepo.saveAll(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final repairedCount =
          await container.read(repairOrphanBirdsProvider.future);

      expect(repairedCount, 1);
      final captured =
          verify(() => mockBirdRepo.saveAll(captureAny())).captured;
      final savedBirds = captured.first as List<Bird>;
      expect(savedBirds, hasLength(1));
      expect(savedBirds.first.fatherId, 'father-1');
      expect(savedBirds.first.motherId, 'mother-1');
    });

    test('skips birds that already have parent IDs', () async {
      final birdWithParents = createTestBird(
        id: 'bird-1',
        fatherId: 'existing-father',
        motherId: 'existing-mother',
      );

      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => [birdWithParents]);
      when(() => mockChickRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockEggRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockIncubationRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockPairRepo.getAll('user-1'))
          .thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final repairedCount =
          await container.read(repairOrphanBirdsProvider.future);

      expect(repairedCount, 0);
      verifyNever(() => mockBirdRepo.saveAll(any()));
    });

    test('returns 0 when no orphan birds exist', () async {
      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockChickRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockEggRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockIncubationRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockPairRepo.getAll('user-1'))
          .thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final repairedCount =
          await container.read(repairOrphanBirdsProvider.future);

      expect(repairedCount, 0);
    });

    test('skips orphan bird without corresponding promoted chick', () async {
      final orphanBird = createTestBird(
        id: 'bird-no-chick',
        fatherId: null,
        motherId: null,
      );

      when(() => mockBirdRepo.getAll('user-1'))
          .thenAnswer((_) async => [orphanBird]);
      when(() => mockChickRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockEggRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockIncubationRepo.getAll('user-1'))
          .thenAnswer((_) async => []);
      when(() => mockPairRepo.getAll('user-1'))
          .thenAnswer((_) async => []);

      final container = createContainer();
      addTearDown(container.dispose);

      final repairedCount =
          await container.read(repairOrphanBirdsProvider.future);

      expect(repairedCount, 0);
    });
  });
}

class _TestPedigreeDepthNotifier extends PedigreeDepthNotifier {
  final int _initial;

  _TestPedigreeDepthNotifier(this._initial);

  @override
  int build() => _initial;
}
