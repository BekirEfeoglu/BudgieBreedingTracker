import 'package:uuid/uuid.dart';

import '../../../core/enums/gamification_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/remote/api/gamification_remote_source.dart';
import 'level_calculator.dart';
import 'xp_constants.dart';

class GamificationService {
  final GamificationRemoteSource _remoteSource;

  GamificationService(this._remoteSource);

  Future<void> recordAction(
    String userId,
    XpAction action, {
    String? referenceId,
  }) async {
    try {
      final xpAmount = XpConstants.getXpAmount(action);
      if (xpAmount <= 0) return;

      // Check daily limit
      final dailyLimit = XpConstants.getDailyLimit(action);
      if (dailyLimit != null) {
        final todayCount =
            await _remoteSource.fetchDailyActionCount(userId, action.toJson());
        if (todayCount >= dailyLimit) return;
      }

      // Insert XP transaction
      await _remoteSource.insertXpTransaction({
        'id': const Uuid().v4(),
        'user_id': userId,
        'action': action.toJson(),
        'amount': xpAmount,
        if (referenceId != null) 'reference_id': referenceId,
      });

      // Update user level
      await _updateUserLevel(userId, xpAmount);

      // Update badge progress
      await _updateBadgeProgress(userId, action);
    } catch (e, st) {
      AppLogger.error('gamification recordAction error', e, st);
    }
  }

  Future<void> _updateUserLevel(String userId, int addedXp) async {
    try {
      final existing = await _remoteSource.fetchUserLevel(userId);
      final currentTotalXp =
          (existing?['total_xp'] as int? ?? 0) + addedXp;
      final levelResult = LevelCalculator.calculateLevel(currentTotalXp);
      final title = LevelCalculator.titleForLevel(levelResult.level);

      final levelData = <String, dynamic>{
        'user_id': userId,
        'total_xp': currentTotalXp,
        'level': levelResult.level,
        'current_level_xp': levelResult.currentLevelXp,
        'next_level_xp': levelResult.nextLevelXp,
        'title': title,
      };

      if (existing != null) {
        levelData['id'] = existing['id'] as String;
      } else {
        levelData['id'] = const Uuid().v4();
      }

      await _remoteSource.upsertUserLevel(levelData);

      // Sync to profile (level/title only — does not reset is_verified_breeder)
      await _remoteSource.updateProfileLevelInfo(
        userId,
        level: levelResult.level,
        title: title,
      );
    } catch (e, st) {
      AppLogger.error('gamification updateUserLevel error', e, st);
    }
  }

  Future<void> _updateBadgeProgress(
    String userId,
    XpAction action,
  ) async {
    try {
      final badges = await _remoteSource.fetchBadges();
      final userBadges = await _remoteSource.fetchUserBadges(userId);

      final userBadgeMap = <String, Map<String, dynamic>>{};
      for (final ub in userBadges) {
        userBadgeMap[ub['badge_key'] as String] = ub;
      }

      // Map XpAction to related badge keys
      final relatedBadgeKeys = _getRelatedBadgeKeys(action);
      if (relatedBadgeKeys.isEmpty) return;

      for (final badge in badges) {
        final badgeKey = badge['key'] as String;
        if (!relatedBadgeKeys.contains(badgeKey)) continue;

        final existing = userBadgeMap[badgeKey];
        final currentProgress = (existing?['progress'] as int? ?? 0) + 1;
        final requirement = badge['requirement'] as int? ?? 1;
        final isNowUnlocked = currentProgress >= requirement;
        final wasAlreadyUnlocked = existing?['is_unlocked'] as bool? ?? false;

        final badgeData = <String, dynamic>{
          'user_id': userId,
          'badge_id': badge['id'] as String,
          'badge_key': badgeKey,
          'progress': currentProgress,
          'is_unlocked': isNowUnlocked,
        };

        if (existing != null) {
          badgeData['id'] = existing['id'] as String;
        } else {
          badgeData['id'] = const Uuid().v4();
        }

        if (isNowUnlocked && !wasAlreadyUnlocked) {
          badgeData['unlocked_at'] = DateTime.now().toIso8601String();

          // Award bonus XP for unlocking
          final xpReward = badge['xp_reward'] as int? ?? 0;
          if (xpReward > 0) {
            await _remoteSource.insertXpTransaction({
              'id': const Uuid().v4(),
              'user_id': userId,
              'action': XpAction.unlockBadge.toJson(),
              'amount': xpReward,
              'reference_id': badge['id'] as String,
            });
            // Update level directly without triggering badge progress again
            final existingLevel = await _remoteSource.fetchUserLevel(userId);
            final updatedTotalXp = (existingLevel?['total_xp'] as int? ?? 0) + xpReward;
            final bonusLevelResult = LevelCalculator.calculateLevel(updatedTotalXp);
            final bonusTitle = LevelCalculator.titleForLevel(bonusLevelResult.level);

            final bonusLevelData = <String, dynamic>{
              'user_id': userId,
              'total_xp': updatedTotalXp,
              'level': bonusLevelResult.level,
              'current_level_xp': bonusLevelResult.currentLevelXp,
              'next_level_xp': bonusLevelResult.nextLevelXp,
              'title': bonusTitle,
            };

            if (existingLevel != null) {
              bonusLevelData['id'] = existingLevel['id'] as String;
            } else {
              bonusLevelData['id'] = const Uuid().v4();
            }

            await _remoteSource.upsertUserLevel(bonusLevelData);
          }
        }

        await _remoteSource.upsertUserBadge(badgeData);
      }
    } catch (e, st) {
      AppLogger.error('gamification updateBadgeProgress error', e, st);
    }
  }

  List<String> _getRelatedBadgeKeys(XpAction action) => switch (action) {
        XpAction.addBird => ['first_bird', 'bird_lover_10', 'bird_paradise_50'],
        XpAction.createBreeding => ['first_breeding', 'breeder_10', 'breeder_50'],
        XpAction.recordChick => ['first_chick', 'chick_100'],
        XpAction.sharePost => ['social_butterfly_50'],
        XpAction.addComment => ['commenter_100'],
        XpAction.createListing => ['market_pro_20'],
        XpAction.addHealthRecord => ['health_tracker_50'],
        _ => [],
      };

  /// Minimum entity counts required for verified breeder status.
  static const _verifiedBreederCriteria = {
    'birds': 3,
    'breeding_pairs': 1,
    'chicks': 1,
  };

  /// Check and update verified breeder status.
  ///
  /// Criteria: level >= 5 AND at least 3 birds, 1 breeding pair, 1 chick.
  Future<void> checkVerifiedBreeder(String userId) async {
    try {
      final userLevel = await _remoteSource.fetchUserLevel(userId);
      final level = userLevel?['level'] as int? ?? 0;

      if (level < 5) return;

      final counts = await _remoteSource.fetchEntityCounts(userId);
      final meetsCriteria = _verifiedBreederCriteria.entries.every(
        (e) => (counts[e.key] ?? 0) >= e.value,
      );

      if (!meetsCriteria) {
        AppLogger.info(
          'Verified breeder check for $userId: level=$level, '
          'birds=${counts['birds']}, breeding=${counts['breeding_pairs']}, '
          'chicks=${counts['chicks']} — criteria not met',
        );
        return;
      }

      // Check if already verified
      final userBadges = await _remoteSource.fetchUserBadges(userId);
      final verifiedBadge = userBadges
          .where((ub) => ub['badge_key'] == 'verified_breeder')
          .firstOrNull;

      if (verifiedBadge != null &&
          (verifiedBadge['is_unlocked'] as bool? ?? false)) {
        return; // Already verified
      }

      // Unlock verified_breeder badge
      final badges = await _remoteSource.fetchBadges();
      final badge = badges
          .where((b) => b['key'] == 'verified_breeder')
          .firstOrNull;

      if (badge == null) return;

      final badgeData = <String, dynamic>{
        'id': verifiedBadge?['id'] as String? ?? const Uuid().v4(),
        'user_id': userId,
        'badge_id': badge['id'] as String,
        'badge_key': 'verified_breeder',
        'progress': 1,
        'is_unlocked': true,
        'unlocked_at': DateTime.now().toIso8601String(),
      };

      await _remoteSource.upsertUserBadge(badgeData);

      // Update profile verification
      final title = LevelCalculator.titleForLevel(level);
      await _remoteSource.updateProfileVerification(
        userId,
        isVerified: true,
        level: level,
        title: title,
      );

      AppLogger.info(
        'Verified breeder unlocked for $userId: level=$level, '
        'birds=${counts['birds']}, breeding=${counts['breeding_pairs']}, '
        'chicks=${counts['chicks']}',
      );
    } catch (e, st) {
      AppLogger.error('gamification checkVerifiedBreeder error', e, st);
    }
  }
}
