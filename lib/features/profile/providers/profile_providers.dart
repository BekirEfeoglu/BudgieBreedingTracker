import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_providers.dart';
import 'profile_stats_providers.dart';

// Re-export split provider files for backward compatibility.
export 'profile_form_providers.dart';
export 'profile_stats_providers.dart';

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
