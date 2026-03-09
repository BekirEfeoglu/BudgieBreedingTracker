import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';

extension ProfileRowMapper on ProfileRow {
  Profile toModel() => Profile(
        id: id,
        email: email,
        isPremium: isPremium,
        subscriptionStatus: subscriptionStatus,
        fullName: fullName,
        avatarUrl: avatarUrl,
        role: role,
        language: language,
        premiumExpiresAt: premiumExpiresAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension ProfileModelMapper on Profile {
  ProfilesTableCompanion toCompanion() => ProfilesTableCompanion(
        id: Value(id),
        email: Value(email),
        isPremium: Value(isPremium),
        subscriptionStatus: Value(subscriptionStatus),
        fullName: Value(fullName),
        avatarUrl: Value(avatarUrl),
        role: Value(role),
        language: Value(language),
        premiumExpiresAt: Value(premiumExpiresAt),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
}
