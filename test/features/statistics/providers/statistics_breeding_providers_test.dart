import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockIncubationRepository repo;

  setUp(() {
    repo = MockIncubationRepository();
  });

  group('incubationsStreamProvider', () {
    test('delegates to repository.watchAll', () async {
      final incubations = [
        Incubation(
          id: 'i1',
          breedingPairId: 'bp1',
          userId: 'u1',
          status: IncubationStatus.active,
          startDate: DateTime(2024, 1, 1),
        ),
      ];
      when(
        () => repo.watchAll('u1'),
      ).thenAnswer((_) => Stream.value(incubations));

      final container = ProviderContainer(
        overrides: [incubationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.listen(incubationsStreamProvider('u1'), (_, __) {});
      final result = await container.read(
        incubationsStreamProvider('u1').future,
      );

      expect(result, hasLength(1));
      expect(result.first.status, IncubationStatus.active);
    });
  });
}
