import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/data/models/user_streak_model.dart';

/// Shows a one-shot SnackBar celebrating a streak update after app launch.
///
/// No auto-navigation — this is purely informational. Callers are
/// responsible for clearing the source state so it fires only once per
/// check-in (see `lastStreakCheckinProvider`).
void showStreakCelebration(BuildContext context, StreakCheckinResult result) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final String message;
  if (result.milestoneUnlocked != null) {
    message = 'gamification.streak_milestone'.tr(
      namedArgs: {'count': '${result.currentStreak}'},
    );
  } else if (result.graceConsumed) {
    message = 'gamification.streak_grace_saved'.tr(
      namedArgs: {'count': '${result.currentStreak}'},
    );
  } else {
    message = 'gamification.streak_celebration'.tr(
      namedArgs: {
        'count': '${result.currentStreak}',
        'xp': '${result.awardedXp}',
      },
    );
  }

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}
