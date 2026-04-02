import '../../core/enums/gamification_enums.dart';
import '../../domain/services/gamification/gamification_service.dart';
import '../models/badge_model.dart';
import '../models/user_badge_model.dart';
import '../models/user_level_model.dart';
import '../models/xp_transaction_model.dart';
import '../remote/api/gamification_remote_source.dart';

class GamificationRepository {
  final GamificationRemoteSource _remoteSource;
  late final GamificationService _service;

  GamificationRepository({
    required GamificationRemoteSource remoteSource,
  }) : _remoteSource = remoteSource {
    _service = GamificationService(_remoteSource);
  }

  Future<List<Badge>> getBadges() async {
    final rows = await _remoteSource.fetchBadges();
    return rows.map((r) => Badge.fromJson(r)).toList();
  }

  Future<List<UserBadge>> getUserBadges(String userId) async {
    final rows = await _remoteSource.fetchUserBadges(userId);
    return rows.map((r) => UserBadge.fromJson(r)).toList();
  }

  Future<UserLevel?> getUserLevel(String userId) async {
    final row = await _remoteSource.fetchUserLevel(userId);
    if (row == null) return null;
    return UserLevel.fromJson(row);
  }

  Future<List<XpTransaction>> getXpHistory(
    String userId, {
    int limit = 50,
  }) async {
    final rows = await _remoteSource.fetchXpTransactions(userId, limit: limit);
    return rows.map((r) => XpTransaction.fromJson(r)).toList();
  }

  Future<List<UserLevel>> getLeaderboard({int limit = 100}) async {
    final rows = await _remoteSource.fetchLeaderboard(limit: limit);
    return rows.map((r) => UserLevel.fromJson(r)).toList();
  }

  Future<void> recordAction(
    String userId,
    XpAction action, {
    String? referenceId,
  }) async {
    await _service.recordAction(userId, action, referenceId: referenceId);
  }

  Future<void> checkVerifiedBreeder(String userId) async {
    await _service.checkVerifiedBreeder(userId);
  }
}
