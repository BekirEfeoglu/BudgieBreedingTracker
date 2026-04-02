import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_badge_model.freezed.dart';
part 'user_badge_model.g.dart';

@freezed
abstract class UserBadge with _$UserBadge {
  const UserBadge._();

  const factory UserBadge({
    required String id,
    required String userId,
    required String badgeId,
    @Default('') String badgeKey,
    @Default(0) int progress,
    @Default(false) bool isUnlocked,
    DateTime? unlockedAt,
    DateTime? createdAt,
  }) = _UserBadge;

  factory UserBadge.fromJson(Map<String, dynamic> json) => _$UserBadgeFromJson(json);
}

extension UserBadgeX on UserBadge {
  double progressPercent(int requirement) {
    if (requirement <= 0) return 0;
    return (progress / requirement).clamp(0.0, 1.0);
  }
}
