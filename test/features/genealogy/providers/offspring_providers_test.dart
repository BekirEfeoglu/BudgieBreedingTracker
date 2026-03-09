import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/offspring_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('filterOffspringBirds', () {
    final birds = [
      createTestBird(
        id: 'male-alive',
        gender: BirdGender.male,
        status: BirdStatus.alive,
      ),
      createTestBird(
        id: 'female-dead',
        gender: BirdGender.female,
        status: BirdStatus.dead,
      ),
      createTestBird(
        id: 'unknown-alive',
        gender: BirdGender.unknown,
        status: BirdStatus.alive,
      ),
    ];

    test('returns original list for all', () {
      final result = filterOffspringBirds(birds, OffspringFilter.all);
      expect(result, same(birds));
    });

    test('filters male birds', () {
      final result = filterOffspringBirds(birds, OffspringFilter.male);
      expect(result.map((b) => b.id), ['male-alive']);
    });

    test('filters female birds', () {
      final result = filterOffspringBirds(birds, OffspringFilter.female);
      expect(result.map((b) => b.id), ['female-dead']);
    });

    test('filters alive birds', () {
      final result = filterOffspringBirds(birds, OffspringFilter.alive);
      expect(result.map((b) => b.id), ['male-alive', 'unknown-alive']);
    });

    test('filters dead birds', () {
      final result = filterOffspringBirds(birds, OffspringFilter.dead);
      expect(result.map((b) => b.id), ['female-dead']);
    });
  });

  group('filterOffspringChicks', () {
    final chicks = [
      const Chick(id: 'male', userId: 'user-1', gender: BirdGender.male),
      const Chick(id: 'female', userId: 'user-1', gender: BirdGender.female),
      const Chick(id: 'unknown', userId: 'user-1', gender: BirdGender.unknown),
    ];

    test('returns original list for all', () {
      final result = filterOffspringChicks(chicks, OffspringFilter.all);
      expect(result, same(chicks));
    });

    test('filters male chicks', () {
      final result = filterOffspringChicks(chicks, OffspringFilter.male);
      expect(result.map((c) => c.id), ['male']);
    });

    test('filters female chicks', () {
      final result = filterOffspringChicks(chicks, OffspringFilter.female);
      expect(result.map((c) => c.id), ['female']);
    });

    test('returns all chicks for alive filter', () {
      final result = filterOffspringChicks(chicks, OffspringFilter.alive);
      expect(result, same(chicks));
    });

    test('returns empty list for dead filter', () {
      final result = filterOffspringChicks(chicks, OffspringFilter.dead);
      expect(result, isEmpty);
    });
  });

  group('offspringFilterProvider', () {
    test('defaults to all and can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(offspringFilterProvider), OffspringFilter.all);
      container.read(offspringFilterProvider.notifier).state =
          OffspringFilter.female;
      expect(container.read(offspringFilterProvider), OffspringFilter.female);
    });
  });
}
