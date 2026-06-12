import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

/// Domain service that enforces free tier entity limits.
///
/// Called by form notifiers before creating new entities.
/// Premium users bypass all checks (caller responsibility).
///
/// Two-layer enforcement:
/// 1. Client-side: queries local repository (offline-first, instant)
/// 2. Server-side: validates via `validate-free-tier-limit` Edge Function
///    (authoritative, prevents client-side bypass on rooted/jailbroken devices)
///
/// If the Edge Function is unavailable (offline, not deployed), the client-side
/// guard is the only enforcement. Server-side validation is non-blocking for
/// offline scenarios.
class FreeTierLimitService {
  final BirdRepository _birdRepo;
  final BreedingPairRepository _breedingPairRepo;
  final IncubationRepository _incubationRepo;
  final EdgeFunctionClient? _edgeFunctionClient;

  const FreeTierLimitService({
    required BirdRepository birdRepo,
    required BreedingPairRepository breedingPairRepo,
    required IncubationRepository incubationRepo,
    EdgeFunctionClient? edgeFunctionClient,
  }) : _birdRepo = birdRepo,
       _breedingPairRepo = breedingPairRepo,
       _incubationRepo = incubationRepo,
       _edgeFunctionClient = edgeFunctionClient;

  /// Throws [FreeTierLimitException] if bird count >= [AppConstants.freeTierMaxBirds].
  Future<void> guardBirdLimit(String userId) async {
    final count = await _birdRepo.getCount(userId);
    if (count >= AppConstants.freeTierMaxBirds) {
      AppLogger.warning(
        '[FreeTier] Bird limit reached for $userId: '
        '$count/${AppConstants.freeTierMaxBirds}',
      );
      throw FreeTierLimitException('bird', AppConstants.freeTierMaxBirds);
    }
    await _validateServerSide('birds');
  }

  /// Throws [FreeTierLimitException] if active breeding pair count >= limit.
  Future<void> guardBreedingPairLimit(String userId) async {
    final activeCount = await _breedingPairRepo.getActiveCount(userId);
    if (activeCount >= AppConstants.freeTierMaxBreedingPairs) {
      AppLogger.warning(
        '[FreeTier] Breeding pair limit reached for $userId: '
        '$activeCount/${AppConstants.freeTierMaxBreedingPairs}',
      );
      throw FreeTierLimitException(
        'breeding',
        AppConstants.freeTierMaxBreedingPairs,
      );
    }
    await _validateServerSide('breeding_pairs');
  }

  /// Throws [FreeTierLimitException] if active incubation count >= limit.
  Future<void> guardIncubationLimit(String userId) async {
    final activeCount = await _incubationRepo.getActiveCount(userId);
    if (activeCount >= AppConstants.freeTierMaxActiveIncubations) {
      AppLogger.warning(
        '[FreeTier] Incubation limit reached for $userId: '
        '$activeCount/${AppConstants.freeTierMaxActiveIncubations}',
      );
      throw FreeTierLimitException(
        'incubation',
        AppConstants.freeTierMaxActiveIncubations,
      );
    }
    await _validateServerSide('incubations');
  }

  /// Server-side validation via `validate-free-tier-limit` Edge Function.
  ///
  /// Fail policy:
  /// - Function not deployed (404) → fail-open (development / staged rollout).
  /// - Network/transient/no-session errors (no HTTP status) → fail-open
  ///   (kullanıcı offline durumda kalmasın).
  /// - Server explicitly rejected (4xx other than 404, or 5xx) → fail-closed.
  ///   Bu, rooted device + simulated network failure gibi senaryolarda
  ///   client-side guard'ın atlanmasını engeller.
  static const _validTables = {'birds', 'breeding_pairs', 'incubations'};

  Future<void> _validateServerSide(String table) async {
    if (_edgeFunctionClient == null) return;
    assert(_validTables.contains(table), 'Invalid table: $table');
    if (!_validTables.contains(table)) return;

    EdgeFunctionResult result;
    try {
      result = await _edgeFunctionClient.invoke(
        'validate-free-tier-limit',
        body: {'table': table},
      );
    } catch (e) {
      // Network/timeout exception thrown by the client — treat as offline.
      AppLogger.info(
        '[FreeTier] Server-side validation threw for $table: $e — '
        'falling back to client-side guard',
      );
      return;
    }

    if (result.success) {
      final allowed = result.data?['allowed'] as bool? ?? true;
      if (!allowed) {
        final limit = result.data?['limit'] as int? ?? 0;
        AppLogger.warning('[FreeTier] Server rejected: $table limit=$limit');
        throw FreeTierLimitException(table, limit);
      }
      return;
    }

    // Non-success: decide based on the error category.
    final errorMsg = result.error ?? '';

    // 404 → function not deployed yet (development / staged rollout). Honor
    // client-side guard.
    if (errorMsg.startsWith('404 NOT_FOUND')) {
      AppLogger.info(
        '[FreeTier] validate-free-tier-limit not deployed; '
        'client-side guard is the only enforcement.',
      );
      return;
    }

    // No authenticated session (guest mode etc.) → fail-open. Insert path
    // will fail at RLS layer if user is actually unauthenticated.
    if (errorMsg.contains('No authenticated session')) {
      AppLogger.info('[FreeTier] No session for $table validation — skip.');
      return;
    }

    // Explicit server response (Status 4xx/5xx other than 404) → fail-closed.
    // Treat the request as if the limit was reached so callers do not silently
    // bypass enforcement on rooted/jailbroken devices.
    final isServerError =
        errorMsg.startsWith('Status 4') || errorMsg.startsWith('Status 5');
    if (isServerError) {
      AppLogger.warning(
        '[FreeTier] Server validation failed for $table ($errorMsg) — '
        'fail-closed.',
      );
      // limit=0 communicates "limit reached" without exposing the real number,
      // which the server refused to compute. UI surfaces a generic upsell.
      throw FreeTierLimitException(table, 0);
    }

    // Anything else (FunctionException with no status code, retry exhausted,
    // unknown shape) → treat as transient/offline.
    AppLogger.info(
      '[FreeTier] Server validation indeterminate for $table ($errorMsg) — '
      'relying on client-side guard.',
    );
  }
}
