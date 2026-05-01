import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile_model.dart';
import '../../../data/providers/entity_count_providers.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';
import 'profile_providers.dart';

// ---------------------------------------------------------------------------
// 2FA Status (async check)
// ---------------------------------------------------------------------------

/// Checks if the current user has 2FA (TOTP) enabled.
final isTwoFactorEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(twoFactorServiceProvider);
  return service.isEnabled();
});

// ---------------------------------------------------------------------------
// Profile Stats
// ---------------------------------------------------------------------------

class ProfileStats {
  final int totalBirds;
  final int totalPairs;
  final int totalEggs;
  final int totalChicks;

  const ProfileStats({
    this.totalBirds = 0,
    this.totalPairs = 0,
    this.totalEggs = 0,
    this.totalChicks = 0,
  });
}

// ---------------------------------------------------------------------------
// Security Score
// ---------------------------------------------------------------------------

class SecurityFactor {
  final String labelKey;
  final bool isCompleted;
  final int points;

  const SecurityFactor({
    required this.labelKey,
    required this.isCompleted,
    required this.points,
  });
}

class SecurityScore {
  final int score;
  final List<SecurityFactor> factors;

  const SecurityScore({required this.score, required this.factors});

  String get levelKey {
    if (score >= 80) return 'profile.security_excellent';
    if (score >= 60) return 'profile.security_high';
    if (score >= 40) return 'profile.security_medium';
    return 'profile.security_low';
  }
}

/// Computes account security score from multiple factors.
final securityScoreProvider = Provider.family<SecurityScore, String>((
  ref,
  userId,
) {
  final profile = ref.watch(userProfileProvider).value;
  final user = ref.watch(currentUserProvider);
  final is2FAEnabled = ref.watch(isTwoFactorEnabledProvider).value ?? false;

  final emailVerified = user?.emailConfirmedAt != null;
  final hasProfile = profile?.fullName != null && profile!.fullName!.isNotEmpty;
  final hasAvatar = profile?.avatarUrl != null;

  final factors = [
    const SecurityFactor(
      labelKey: 'profile.security_factor_password',
      isCompleted: true, // User has a password to be logged in
      points: 25,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_2fa',
      isCompleted: is2FAEnabled,
      points: 30,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_email',
      isCompleted: emailVerified,
      points: 20,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_profile',
      isCompleted: hasProfile && hasAvatar,
      points: 15,
    ),
    SecurityFactor(
      labelKey: 'profile.security_factor_premium',
      isCompleted: profile?.hasPremium == true,
      points: 10,
    ),
  ];

  final score = factors
      .where((f) => f.isCompleted)
      .fold(0, (sum, f) => sum + f.points);

  return SecurityScore(score: score, factors: factors);
});

// ---------------------------------------------------------------------------
// Profile Stats (bird/pair/chick counts)
// ---------------------------------------------------------------------------

/// Provides bird/pair/egg/chick counts for the profile header.
/// Uses SQL COUNT queries (via entity_count_providers) instead of full entity lists.
final profileStatsProvider = Provider.family<AsyncValue<ProfileStats>, String>((
  ref,
  userId,
) {
  final birdsCount = ref.watch(birdCountProvider(userId));
  final pairsCount = ref.watch(activeBreedingCountProvider(userId));
  final eggsCount = ref.watch(eggCountProvider(userId));
  final chicksCount = ref.watch(chickCountProvider(userId));

  return birdsCount.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (birds) => pairsCount.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (pairs) => eggsCount.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (eggs) => chicksCount.when(
          loading: () => const AsyncLoading(),
          error: (e, st) => AsyncError(e, st),
          data: (chicks) => AsyncData(
            ProfileStats(
              totalBirds: birds,
              totalPairs: pairs,
              totalEggs: eggs,
              totalChicks: chicks,
            ),
          ),
        ),
      ),
    ),
  );
});
