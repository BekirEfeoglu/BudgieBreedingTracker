import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_streak_model.freezed.dart';
part 'user_streak_model.g.dart';

@freezed
abstract class UserStreak with _$UserStreak {
  const UserStreak._();

  const factory UserStreak({
    required String userId,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    DateTime? lastCheckInDate,
    @Default(0) int graceUsedThisMonth,
    DateTime? graceMonth,
    DateTime? updatedAt,
  }) = _UserStreak;

  factory UserStreak.fromJson(Map<String, dynamic> json) =>
      _$UserStreakFromJson(json);
}

@freezed
abstract class StreakCheckinResult with _$StreakCheckinResult {
  const StreakCheckinResult._();

  const factory StreakCheckinResult({
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    @Default(false) bool graceConsumed,
    @Default(0) int awardedXp,
    String? milestoneUnlocked,
  }) = _StreakCheckinResult;

  factory StreakCheckinResult.fromJson(Map<String, dynamic> json) =>
      _$StreakCheckinResultFromJson(json);
}
