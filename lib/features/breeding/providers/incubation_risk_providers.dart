import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/breeding/incubation_risk_assistant.dart';

final incubationRiskAssistantProvider = Provider<IncubationRiskAssistant>((
  ref,
) {
  return const IncubationRiskAssistant();
});

final incubationRiskNowProvider = Provider<DateTime>((ref) => DateTime.now());

final incubationRiskSummaryProvider =
    Provider.family<AsyncValue<IncubationRiskSummary>, String>((ref, userId) {
      final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
      final incubationsAsync = ref.watch(allIncubationsStreamProvider(userId));
      final eggsAsync = ref.watch(eggsStreamProvider(userId));
      final chicksAsync = ref.watch(chicksStreamProvider(userId));

      return pairsAsync.when(
        data: (pairs) => incubationsAsync.when(
          data: (incubations) => eggsAsync.when(
            data: (eggs) => chicksAsync.when(
              data: (chicks) => AsyncValue.data(
                ref
                    .watch(incubationRiskAssistantProvider)
                    .assess(
                      now: ref.watch(incubationRiskNowProvider),
                      pairs: pairs,
                      incubations: incubations,
                      eggs: eggs,
                      chicks: chicks,
                    ),
              ),
              loading: () => const AsyncValue.loading(),
              error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
            ),
            loading: () => const AsyncValue.loading(),
            error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
          ),
          loading: () => const AsyncValue.loading(),
          error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
        ),
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });

final pairIncubationRisksProvider =
    Provider.family<AsyncValue<List<IncubationRisk>>, String>((ref, pairId) {
      final userId = ref.watch(currentUserIdProvider);
      final summary = ref.watch(incubationRiskSummaryProvider(userId));
      return summary.whenData((summary) => summary.risksForPair(pairId));
    });

final incubationRisksProvider =
    Provider.family<AsyncValue<List<IncubationRisk>>, String>((
      ref,
      incubationId,
    ) {
      final userId = ref.watch(currentUserIdProvider);
      final summary = ref.watch(incubationRiskSummaryProvider(userId));
      return summary.whenData(
        (summary) => summary.risksForIncubation(incubationId),
      );
    });
