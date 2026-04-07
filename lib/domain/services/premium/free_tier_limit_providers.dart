import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_service.dart';

final freeTierLimitServiceProvider = Provider<FreeTierLimitService>((ref) {
  EdgeFunctionClient? edgeFunctionClient;
  try {
    edgeFunctionClient = EdgeFunctionClient(ref.watch(supabaseClientProvider));
  } catch (e) {
    AppLogger.warning(
      '[FreeTier] Supabase not initialized, server-side validation unavailable: $e',
    );
  }

  return FreeTierLimitService(
    birdRepo: ref.watch(birdRepositoryProvider),
    breedingPairRepo: ref.watch(breedingPairRepositoryProvider),
    incubationRepo: ref.watch(incubationRepositoryProvider),
    edgeFunctionClient: edgeFunctionClient,
  );
});
