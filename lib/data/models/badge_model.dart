import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';

part 'badge_model.freezed.dart';
part 'badge_model.g.dart';

@freezed
abstract class Badge with _$Badge {
  const Badge._();

  const factory Badge({
    required String id,
    required String key,
    @JsonKey(unknownEnumValue: BadgeCategory.unknown)
    @Default(BadgeCategory.milestone)
    BadgeCategory category,
    @JsonKey(unknownEnumValue: BadgeTier.unknown)
    @Default(BadgeTier.bronze)
    BadgeTier tier,
    @Default('') String nameKey,
    @Default('') String descriptionKey,
    @Default('') String iconPath,
    @Default(0) int xpReward,
    @Default(0) int requirement,
    @Default(0) int sortOrder,
  }) = _Badge;

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
}
