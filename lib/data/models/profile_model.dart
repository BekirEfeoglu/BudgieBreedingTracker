import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    required String email,
    @Default(false) bool isPremium,
    @Default(SubscriptionStatus.free)
    @JsonKey(unknownEnumValue: SubscriptionStatus.free)
    SubscriptionStatus subscriptionStatus,
    String? fullName,
    String? avatarUrl,
    String? role,
    String? language,
    DateTime? premiumExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

extension ProfileX on Profile {
  bool get isAdmin => role == 'admin';
  bool get isFounder => role == 'founder';
  bool get hasPremium =>
      isPremium ||
      subscriptionStatus == SubscriptionStatus.premium ||
      subscriptionStatus == SubscriptionStatus.trial;

  String get resolvedDisplayName =>
      (fullName != null && fullName!.trim().isNotEmpty)
          ? fullName!
          : email.split('@').first;
}
