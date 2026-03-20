import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';

import '../../../helpers/mocks.dart';

Chick _chick({
  required String id,
  ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
  DateTime? hatchDate,
  DateTime? weanDate,
  String? birdId,
  String? name,
  String? ring,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    healthStatus: healthStatus,
    hatchDate: hatchDate ?? DateTime(2024, 1, 1),
    weanDate: weanDate,
    birdId: birdId,
    name: name,
    ringNumber: ring,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  late MockChickRepository chickRepo;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        chickRepositoryProvider.overrideWithValue(chickRepo),
      ],
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    chickRepo = MockChickRepository();

    when(() => chickRepo.watchAll(any())).thenAnswer(
      (_) => Stream.value([
        _chick(
          id: 'c1',
          healthStatus: ChickHealthStatus.healthy,
          name: 'Lemon',
          ring: 'R-1',
        ),
        _chick(
          id: 'c2',
          healthStatus: ChickHealthStatus.sick,
          name: 'Sky',
          ring: 'R-2',
        ),
      ]),
    );
  });

  group('chicksStreamProvider', () {
    test('delegates to repository.watchAll', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(chicksStreamProvider('user-1'), (_, __) {});
      final chicks = await container.read(
        chicksStreamProvider('user-1').future,
      );

      expect(chicks, hasLength(2));
      verify(() => chickRepo.watchAll('user-1')).called(1);
    });
  });

  group('filter/search providers', () {
    test('filteredChicksProvider respects filter state', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final chicks = [
        _chick(id: 'healthy', healthStatus: ChickHealthStatus.healthy),
        _chick(id: 'sick', healthStatus: ChickHealthStatus.sick),
        _chick(id: 'deceased', healthStatus: ChickHealthStatus.deceased),
      ];

      container.read(chickFilterProvider.notifier).state = ChickFilter.healthy;
      expect(container.read(filteredChicksProvider(chicks)).map((e) => e.id), [
        'healthy',
      ]);

      container.read(chickFilterProvider.notifier).state = ChickFilter.sick;
      expect(container.read(filteredChicksProvider(chicks)).map((e) => e.id), [
        'sick',
      ]);

      container.read(chickFilterProvider.notifier).state = ChickFilter.deceased;
      expect(container.read(filteredChicksProvider(chicks)).map((e) => e.id), [
        'deceased',
      ]);

      container.read(chickFilterProvider.notifier).state = ChickFilter.unweaned;
      final unweanedChicks = [
        _chick(id: 'unweaned'),
        _chick(id: 'promoted', birdId: 'bird-1'),
      ];
      expect(
        container.read(filteredChicksProvider(unweanedChicks)).map((e) => e.id),
        ['unweaned'],
      );
    });

    test('searchedAndFilteredChicksProvider applies query', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final chicks = [
        _chick(id: 'c1', name: 'Lemon', ring: 'TR-001'),
        _chick(id: 'c2', name: 'Sky', ring: 'TR-ABC'),
      ];
      container.read(chickFilterProvider.notifier).state = ChickFilter.all;
      container.read(chickSearchQueryProvider.notifier).state = 'abc';

      final result = container.read(searchedAndFilteredChicksProvider(chicks));
      expect(result.single.id, 'c2');
    });
  });
}
