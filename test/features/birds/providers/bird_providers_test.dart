import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';

import '../../../helpers/mocks.dart';

Bird _bird({
  required String id,
  required String name,
  BirdGender gender = BirdGender.unknown,
  BirdStatus status = BirdStatus.alive,
  String? ring,
  String? cage,
  DateTime? birthDate,
  DateTime? createdAt,
}) {
  return Bird(
    id: id,
    name: name,
    gender: gender,
    userId: 'user-1',
    status: status,
    ringNumber: ring,
    cageNumber: cage,
    birthDate: birthDate,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  const userId = 'user-1';

  late MockBirdRepository repo;
  late List<Bird> birds;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [birdRepositoryProvider.overrideWithValue(repo)],
    );
  }

  setUp(() {
    repo = MockBirdRepository();
    birds = [
      _bird(
        id: 'b1',
        name: 'Alpha',
        gender: BirdGender.male,
        status: BirdStatus.alive,
        ring: 'TR-001',
        cage: 'C1',
        birthDate: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 10),
      ),
      _bird(
        id: 'b2',
        name: 'beta',
        gender: BirdGender.female,
        status: BirdStatus.dead,
        ring: 'TR-002',
        cage: 'C2',
        birthDate: DateTime(2023, 6, 1),
        createdAt: DateTime(2024, 1, 9),
      ),
      _bird(
        id: 'b3',
        name: 'Gamma',
        gender: BirdGender.unknown,
        status: BirdStatus.sold,
        ring: 'TR-999',
        cage: 'A7',
        birthDate: null,
        createdAt: DateTime(2024, 1, 8),
      ),
      _bird(
        id: 'b4',
        name: 'Delta',
        gender: BirdGender.female,
        status: BirdStatus.gifted,
        ring: 'TR-010',
        cage: 'B2',
        birthDate: DateTime(2024, 2, 1),
        createdAt: DateTime(2024, 1, 7),
      ),
    ];

    when(() => repo.watchAll(any())).thenAnswer((_) => Stream.value(birds));
  });

  group('birdsStreamProvider', () {
    test('delegates to repository.watchAll', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(birdsStreamProvider(userId), (_, __) {});
      final result = await container.read(birdsStreamProvider(userId).future);

      expect(result, birds);
      verify(() => repo.watchAll(userId)).called(1);
    });
  });

  group('filteredBirdsProvider', () {
    test('returns all birds for BirdFilter.all', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdFilterProvider.notifier).state = BirdFilter.all;
      final result = container.read(filteredBirdsProvider(birds));

      expect(result, hasLength(4));
    });

    test('filters male/female/alive/dead/sold correctly', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdFilterProvider.notifier).state = BirdFilter.male;
      expect(container.read(filteredBirdsProvider(birds)), hasLength(1));

      container.read(birdFilterProvider.notifier).state = BirdFilter.female;
      expect(container.read(filteredBirdsProvider(birds)), hasLength(2));

      container.read(birdFilterProvider.notifier).state = BirdFilter.alive;
      expect(container.read(filteredBirdsProvider(birds)), hasLength(1));

      container.read(birdFilterProvider.notifier).state = BirdFilter.dead;
      expect(container.read(filteredBirdsProvider(birds)), hasLength(1));

      container.read(birdFilterProvider.notifier).state = BirdFilter.sold;
      expect(container.read(filteredBirdsProvider(birds)), hasLength(1));

      container.read(birdFilterProvider.notifier).state = BirdFilter.gifted;
      expect(container.read(filteredBirdsProvider(birds)), hasLength(1));
      expect(container.read(filteredBirdsProvider(birds)).single.id, 'b4');
    });
  });

  group('searchedAndFilteredBirdsProvider', () {
    test('returns filtered birds when query is empty', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdFilterProvider.notifier).state = BirdFilter.alive;
      container.read(birdSearchQueryProvider.notifier).state = '';

      final result = container.read(searchedAndFilteredBirdsProvider(birds));

      expect(result.map((e) => e.id), ['b1']);
    });

    test('supports case-insensitive name search', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdFilterProvider.notifier).state = BirdFilter.all;
      container.read(birdSearchQueryProvider.notifier).state = 'BETA';

      final result = container.read(searchedAndFilteredBirdsProvider(birds));

      expect(result.map((e) => e.id), ['b2']);
    });

    test('supports ring number and cage number search', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdFilterProvider.notifier).state = BirdFilter.all;
      container.read(birdSearchQueryProvider.notifier).state = 'tr-999';
      expect(
        container.read(searchedAndFilteredBirdsProvider(birds)).single.id,
        'b3',
      );

      container.read(birdSearchQueryProvider.notifier).state = 'c2';
      expect(
        container.read(searchedAndFilteredBirdsProvider(birds)).single.id,
        'b2',
      );
    });
  });

  group('sortedAndFilteredBirdsProvider', () {
    test('sorts by name asc and desc', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdFilterProvider.notifier).state = BirdFilter.all;
      container.read(birdSearchQueryProvider.notifier).state = '';

      container.read(birdSortProvider.notifier).state = BirdSort.nameAsc;
      expect(
        container.read(sortedAndFilteredBirdsProvider(birds)).map((e) => e.id),
        ['b1', 'b2', 'b4', 'b3'],
      );

      container.read(birdSortProvider.notifier).state = BirdSort.nameDesc;
      expect(
        container.read(sortedAndFilteredBirdsProvider(birds)).map((e) => e.id),
        ['b3', 'b4', 'b2', 'b1'],
      );
    });

    test('sorts by age and handles null birthDate', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdSortProvider.notifier).state = BirdSort.ageNewest;
      expect(
        container.read(sortedAndFilteredBirdsProvider(birds)).map((e) => e.id),
        ['b4', 'b1', 'b2', 'b3'],
      );

      container.read(birdSortProvider.notifier).state = BirdSort.ageOldest;
      expect(
        container.read(sortedAndFilteredBirdsProvider(birds)).map((e) => e.id),
        ['b3', 'b2', 'b1', 'b4'],
      );
    });

    test('sorts by created date newest and oldest', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(birdSortProvider.notifier).state = BirdSort.dateNewest;
      expect(
        container.read(sortedAndFilteredBirdsProvider(birds)).map((e) => e.id),
        ['b1', 'b2', 'b3', 'b4'],
      );

      container.read(birdSortProvider.notifier).state = BirdSort.dateOldest;
      expect(
        container.read(sortedAndFilteredBirdsProvider(birds)).map((e) => e.id),
        ['b4', 'b3', 'b2', 'b1'],
      );
    });

    test('sorts naturally by ring number and keeps missing rings last', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final ringBirds = [
        _bird(id: 'no-ring', name: 'No Ring'),
        _bird(id: 'ring-10', name: 'Ring 10', ring: 'TR-10'),
        _bird(id: 'ring-2', name: 'Ring 2', ring: 'TR-2'),
      ];

      container.read(birdSortProvider.notifier).state = BirdSort.ringAsc;
      expect(
        container
            .read(sortedAndFilteredBirdsProvider(ringBirds))
            .map((e) => e.id),
        ['ring-2', 'ring-10', 'no-ring'],
      );

      container.read(birdSortProvider.notifier).state = BirdSort.ringDesc;
      expect(
        container
            .read(sortedAndFilteredBirdsProvider(ringBirds))
            .map((e) => e.id),
        ['ring-10', 'ring-2', 'no-ring'],
      );
    });
  });

  group('birdListViewModeProvider', () {
    test('defaults to list mode and can switch to grid mode', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      expect(container.read(birdListViewModeProvider), BirdListViewMode.list);

      container
          .read(birdListViewModeProvider.notifier)
          .setMode(BirdListViewMode.grid);

      expect(container.read(birdListViewModeProvider), BirdListViewMode.grid);
    });
  });

  group('enum labels', () {
    test('BirdFilter labels are non-empty', () {
      for (final value in BirdFilter.values) {
        expect(value.label, isNotEmpty);
      }
    });

    test('BirdSort labels are non-empty', () {
      for (final value in BirdSort.values) {
        expect(value.label, isNotEmpty);
      }
    });
  });

  group('cageSummariesProvider', () {
    test('groups alive birds by cage number with unassigned birds last', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = container.read(
        cageSummariesProvider([
          _bird(id: 'b1', name: 'Mavi 2', cage: 'K10'),
          _bird(id: 'b2', name: 'Mavi 1', cage: 'K2'),
          _bird(id: 'b3', name: 'Disi', cage: 'K2'),
          _bird(id: 'b4', name: 'Eski', cage: 'K2', status: BirdStatus.dead),
          _bird(id: 'b5', name: 'Atanmamis'),
        ]),
      );

      expect(result.map((summary) => summary.cageNumber), ['K2', 'K10', null]);
      expect(result.first.birds.map((bird) => bird.name), ['Disi', 'Mavi 1']);
      expect(result.first.aliveCount, 2);
      expect(result.last.isUnassigned, isTrue);
      expect(result.last.birds.single.id, 'b5');
    });

    test('returns empty list when there are no alive birds', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final result = container.read(
        cageSummariesProvider([
          _bird(id: 'b1', name: 'Eski', status: BirdStatus.dead, cage: 'K1'),
          _bird(id: 'b2', name: 'Satildi', status: BirdStatus.sold),
        ]),
      );

      expect(result, isEmpty);
    });
  });
}
