import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// Records gamification side effects without blocking the primary mutation.
///
/// XP and badges are server-authoritative and optional from the user's current
/// form action perspective: a failed XP write must not turn a successful bird,
/// breeding, marketplace, or community mutation into a user-visible failure.
void recordGamificationAction(
  Ref ref, {
  required String userId,
  required XpAction action,
  String? referenceId,
  bool checkVerifiedBreeder = false,
}) {
  unawaited(
    _recordGamificationAction(
      ref,
      userId: userId,
      action: action,
      referenceId: referenceId,
      checkVerifiedBreeder: checkVerifiedBreeder,
    ),
  );
}

Future<void> _recordGamificationAction(
  Ref ref, {
  required String userId,
  required XpAction action,
  String? referenceId,
  required bool checkVerifiedBreeder,
}) async {
  try {
    final repo = ref.read(gamificationRepositoryProvider);
    await repo.recordAction(userId, action, referenceId: referenceId);
    if (checkVerifiedBreeder) {
      await repo.checkVerifiedBreeder(userId);
    }
  } catch (e, st) {
    AppLogger.warning(
      'Gamification side effect failed for ${action.name}: $e\n$st',
    );
  }
}
