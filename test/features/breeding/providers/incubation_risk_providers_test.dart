import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/breeding/incubation_risk_assistant.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/incubation_risk_providers.dart';

void main() {
  const userId = 'test-user';
  final now = DateTime(2026, 5, 17);

  ProviderContainer createContainer({
    required AsyncValue<List<Egg>> eggs,
    AsyncValue<List<BreedingPair>>? pairs,
    AsyncValue<List<Incubation>>? incubations,
    AsyncValue<List<Chick>>? chicks,
  }) {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        incubationRiskNowProvider.overrideWithValue(now),
        breedingPairsStreamProvider(
          userId,
        ).overrideWithValue(pairs ?? AsyncValue.data([_pair('pair-1')])),
        allIncubationsStreamProvider(userId).overrideWithValue(
          incubations ??
              AsyncValue.data([_incubation('inc-1', pairId: 'pair-1')]),
        ),
        eggsStreamProvider(userId).overrideWithValue(eggs),
        chicksStreamProvider(
          userId,
        ).overrideWithValue(chicks ?? const AsyncValue.data([])),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('incubationRiskSummaryProvider', () {
    test('stays loading until all risk input streams have emitted', () {
      final container = createContainer(
        eggs: const AsyncValue<List<Egg>>.loading(),
      );

      expect(
        container.read(incubationRiskSummaryProvider(userId)).isLoading,
        isTrue,
      );
    });

    test('returns data when all risk input streams have emitted', () {
      final container = createContainer(
        eggs: AsyncValue.data([
          _egg('egg-1', incubationId: 'inc-1', status: EggStatus.infertile),
        ]),
      );
      final summary = container.read(incubationRiskSummaryProvider(userId));
      expect(summary.hasValue, isTrue);
      expect(
        summary.requireValue.risks.map((risk) => risk.type),
        contains(IncubationRiskType.highUnsuccessfulEggRate),
      );
    });

    test('propagates source stream errors instead of returning clean data', () {
      final error = Exception('eggs failed');
      final container = createContainer(
        eggs: AsyncValue<List<Egg>>.error(error, StackTrace.current),
      );

      expect(
        container.read(incubationRiskSummaryProvider(userId)).hasError,
        isTrue,
      );
    });
  });
}

BreedingPair _pair(String id) => BreedingPair(id: id, userId: 'test-user');

Incubation _incubation(String id, {String? pairId}) {
  return Incubation(
    id: id,
    userId: 'test-user',
    status: IncubationStatus.active,
    breedingPairId: pairId,
    startDate: DateTime(2026, 4, 1),
  );
}

Egg _egg(String id, {String? incubationId, EggStatus status = EggStatus.laid}) {
  return Egg(
    id: id,
    userId: 'test-user',
    incubationId: incubationId,
    status: status,
    layDate: DateTime(2026, 4, 1),
  );
}
