import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preference_model.freezed.dart';
part 'user_preference_model.g.dart';

@freezed
abstract class UserPreference with _$UserPreference {
  const UserPreference._();

  const factory UserPreference({
    required String id,
    required String userId,
    @Default('system') String theme,
    @Default('tr') String language,
    @Default(true) bool notificationsEnabled,
    @Default(false) bool compactView,
    @Default(true) bool emailNotifications,
    @Default(true) bool pushNotifications,
    String? customSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserPreference;

  factory UserPreference.fromJson(Map<String, dynamic> json) =>
      _$UserPreferenceFromJson(json);
}
