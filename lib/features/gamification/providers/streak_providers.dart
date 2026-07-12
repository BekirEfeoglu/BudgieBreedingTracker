import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../data/models/user_streak_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/gamification/streak_service.dart';

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService(ref.watch(gamificationRepositoryProvider));
});

/// Current user's streak state (null when anonymous / no row yet).
final streakProvider = FutureProvider<UserStreak?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return ref.watch(streakServiceProvider).getStreak(userId);
});

/// Holds the most recent check-in result so the home screen can show a
/// one-shot launch celebration. Cleared after it is displayed.
class LastStreakCheckinNotifier extends Notifier<StreakCheckinResult?> {
  @override
  StreakCheckinResult? build() => null;
}

final lastStreakCheckinProvider =
    NotifierProvider<LastStreakCheckinNotifier, StreakCheckinResult?>(
  LastStreakCheckinNotifier.new,
);

/// Fire-and-forget daily check-in. Called from app init (deferred microtask).
/// Uses the IANA zone set on tz.local by the notification service init.
Future<void> runDailyCheckin(Ref ref) async {
  final userId = ref.read(currentUserIdProvider);
  final tzName = tz.local.name;
  final result = await ref.read(streakServiceProvider).checkIn(userId, tzName);
  if (result != null && result.currentStreak > 0) {
    ref.read(lastStreakCheckinProvider.notifier).state = result;
    ref.invalidate(streakProvider);
  }
}
