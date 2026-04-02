import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_level_model.freezed.dart';
part 'user_level_model.g.dart';

@freezed
abstract class UserLevel with _$UserLevel {
  const UserLevel._();

  const factory UserLevel({
    required String id,
    required String userId,
    @Default(0) int totalXp,
    @Default(1) int level,
    @Default(0) int currentLevelXp,
    @Default(100) int nextLevelXp,
    @Default('') String title,
    DateTime? updatedAt,
  }) = _UserLevel;

  factory UserLevel.fromJson(Map<String, dynamic> json) => _$UserLevelFromJson(json);
}

extension UserLevelX on UserLevel {
  double get levelProgress {
    if (nextLevelXp <= 0) return 0;
    return (currentLevelXp / nextLevelXp).clamp(0.0, 1.0);
  }
}
