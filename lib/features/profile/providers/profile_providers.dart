import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_providers.dart';

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
