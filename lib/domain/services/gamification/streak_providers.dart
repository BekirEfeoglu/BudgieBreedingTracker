import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/logger.dart';
import '../../../data/models/user_streak_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/providers/notification_settings_shared_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../notifications/notification_providers.dart';
import '../notifications/streak_reminder_scheduler.dart';
import 'streak_service.dart';

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
  try {
    final userId = ref.read(currentUserIdProvider);
    final tzName = tz.local.name;
    final result = await ref
        .read(streakServiceProvider)
        .checkIn(userId, tzName);
    if (result != null && result.awardedXp > 0) {
      ref.read(lastStreakCheckinProvider.notifier).state = result;
      ref.invalidate(streakProvider);
    }
    if (result != null) {
      // Reschedule the smart streak reminder (respects the toggle + >=3
      // guard). Runs for any non-null result — including a same-day no-op —
      // so the reminder always reflects the current streak.
      await ref.read(notificationToggleSettingsReadyProvider.future);
      final enabled =
          ref.read(notificationToggleSettingsProvider).streakReminder;
      await StreakReminderScheduler(
        ref.read(notificationServiceProvider),
      ).scheduleNext(currentStreak: result.currentStreak, enabled: enabled);
    }
  } catch (e, st) {
    // Non-fatal side effect (matches StreakService.checkIn convention):
    // never let a check-in or reminder-scheduling failure escape this
    // fire-and-forget microtask.
    AppLogger.warning('[runDailyCheckin] failed: $e\n$st');
  }
}
