import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile_model.dart';
import '../repositories/repository_providers.dart';
import 'auth_state_providers.dart';

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
