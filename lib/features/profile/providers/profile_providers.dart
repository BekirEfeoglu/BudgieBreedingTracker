import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/remote/storage/storage_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../home/providers/home_providers.dart';

// ---------------------------------------------------------------------------
// User Profile Stream
// ---------------------------------------------------------------------------

/// Stream of the current user's profile.
final userProfileProvider = StreamProvider<Profile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return Stream.value(null);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchProfile(userId);
});

// ---------------------------------------------------------------------------
// Avatar Upload
// ---------------------------------------------------------------------------

class AvatarUploadState {
  final bool isUploading;
  final String? error;
  final bool isSuccess;

  const AvatarUploadState({
    this.isUploading = false,
    this.error,
    this.isSuccess = false,
  });

  AvatarUploadState copyWith({
    bool? isUploading,
    String? error,
    bool? isSuccess,
  }) => AvatarUploadState(
    isUploading: isUploading ?? this.isUploading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

class AvatarUploadNotifier extends Notifier<AvatarUploadState> {
  @override
  AvatarUploadState build() => const AvatarUploadState();

  /// Upload an avatar image file.
  Future<void> uploadAvatar(XFile file) async {
    state = state.copyWith(isUploading: true, error: null, isSuccess: false);
    try {
      final userId = ref.read(currentUserIdProvider);
      final storageService = ref.read(storageServiceProvider);
      final profileRepo = ref.read(profileRepositoryProvider);

      // Upload to Supabase Storage
      final avatarUrl = await storageService.uploadAvatar(
        userId: userId,
        file: file,
      );

      // Update profile with new avatar URL
      final profile = await profileRepo.getById(userId);
      if (profile != null) {
        await profileRepo.save(profile.copyWith(avatarUrl: avatarUrl));
      }

      state = state.copyWith(isUploading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('AvatarUpload', 'Failed to upload avatar: $e');
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Remove the current avatar.
  Future<void> removeAvatar() async {
    state = state.copyWith(isUploading: true, error: null, isSuccess: false);
    try {
      final userId = ref.read(currentUserIdProvider);
      final storageService = ref.read(storageServiceProvider);
      final profileRepo = ref.read(profileRepositoryProvider);

      // Delete from storage
      await storageService.deleteAvatar(userId: userId);

      // Clear avatar URL on profile
      final profile = await profileRepo.getById(userId);
      if (profile != null) {
        await profileRepo.save(profile.copyWith(avatarUrl: null));
      }

      state = state.copyWith(isUploading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('AvatarUpload', 'Failed to remove avatar: $e');
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  void reset() => state = const AvatarUploadState();
}

final avatarUploadStateProvider =
    NotifierProvider<AvatarUploadNotifier, AvatarUploadState>(
      AvatarUploadNotifier.new,
    );

// ---------------------------------------------------------------------------
// Password Change
// ---------------------------------------------------------------------------

class PasswordChangeState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const PasswordChangeState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  PasswordChangeState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) => PasswordChangeState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

class PasswordChangeNotifier extends Notifier<PasswordChangeState> {
  @override
  PasswordChangeState build() => const PasswordChangeState();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final authActions = ref.read(authActionsProvider);
      await authActions.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final errorKey = msg.contains('invalid') || msg.contains('credentials')
          ? 'password_incorrect'
          : 'password_change_error';
      state = state.copyWith(isLoading: false, error: errorKey);
    } catch (e) {
      AppLogger.error('PasswordChange', 'Failed: $e');
      state = state.copyWith(isLoading: false, error: 'password_change_error');
    }
  }

  void reset() => state = const PasswordChangeState();
}

final passwordChangeStateProvider =
    NotifierProvider<PasswordChangeNotifier, PasswordChangeState>(
      PasswordChangeNotifier.new,
    );

// ---------------------------------------------------------------------------
// Profile Completion
// ---------------------------------------------------------------------------

class CompletionItem {
  final String labelKey;
  final bool isCompleted;

  const CompletionItem({required this.labelKey, required this.isCompleted});
}

class ProfileCompletion {
  final double percentage;
  final List<CompletionItem> items;

  const ProfileCompletion({required this.percentage, required this.items});
}

/// Calculates profile completion from 6 factors.
final profileCompletionProvider = Provider.family<ProfileCompletion, String>((
  ref,
  userId,
) {
  final profile = ref.watch(userProfileProvider).value;
  final stats = ref.watch(profileStatsProvider(userId)).value;

  final items = [
    CompletionItem(
      labelKey: 'profile.completion_name',
      isCompleted: profile?.fullName != null && profile!.fullName!.isNotEmpty,
    ),
    CompletionItem(
      labelKey: 'profile.completion_avatar',
      isCompleted: profile?.avatarUrl != null,
    ),
    CompletionItem(
      labelKey: 'profile.completion_first_bird',
      isCompleted: (stats?.totalBirds ?? 0) > 0,
    ),
    CompletionItem(
      labelKey: 'profile.completion_first_pair',
      isCompleted: (stats?.totalPairs ?? 0) > 0,
    ),
    CompletionItem(
      labelKey: 'profile.completion_first_chick',
      isCompleted: (stats?.totalChicks ?? 0) > 0,
    ),
    CompletionItem(
      labelKey: 'profile.completion_premium',
      isCompleted: profile?.hasPremium == true,
    ),
  ];

  final completed = items.where((i) => i.isCompleted).length;
  final percentage = items.isEmpty ? 0.0 : completed / items.length;

  return ProfileCompletion(percentage: percentage, items: items);
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

  final emailVerified = user?.emailConfirmedAt != null;
  final hasProfile = profile?.fullName != null && profile!.fullName!.isNotEmpty;
  final hasAvatar = profile?.avatarUrl != null;

  final factors = [
    const SecurityFactor(
      labelKey: 'profile.security_factor_password',
      isCompleted: true, // User has a password to be logged in
      points: 25,
    ),
    const SecurityFactor(
      labelKey: 'profile.security_factor_2fa',
      isCompleted: false, // Check from auth metadata when available
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
/// Uses SQL COUNT queries (via home_providers) instead of full entity lists.
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
