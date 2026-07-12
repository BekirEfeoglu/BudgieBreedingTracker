import '../../../core/utils/logger.dart';
import '../../../data/models/user_streak_model.dart';
import '../../../data/repositories/gamification_repository.dart';

/// Orchestrates the daily streak check-in. Server-authoritative: all logic is
/// in the record_daily_checkin RPC; this only calls it and never blocks the
/// primary app flow (a failed check-in is a non-fatal warning).
class StreakService {
  StreakService(this._repo);

  final GamificationRepository _repo;

  Future<StreakCheckinResult?> checkIn(String userId, String timeZone) async {
    if (userId.isEmpty || userId == 'anonymous') return null;
    try {
      return await _repo.recordDailyCheckin(timeZone);
    } catch (e, st) {
      AppLogger.warning('[StreakService] check-in failed: $e\n$st');
      return null;
    }
  }

  Future<UserStreak?> getStreak(String userId) async {
    if (userId.isEmpty || userId == 'anonymous') return null;
    try {
      return await _repo.getStreak(userId);
    } catch (e, st) {
      AppLogger.warning('[StreakService] fetch failed: $e\n$st');
      return null;
    }
  }
}
