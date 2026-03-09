import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/user_preference_model.dart';

extension UserPreferenceRowMapper on UserPreferenceRow {
  UserPreference toModel() => UserPreference(
        id: id,
        userId: userId,
        theme: theme,
        language: language,
        notificationsEnabled: notificationsEnabled,
        compactView: compactView,
        emailNotifications: emailNotifications,
        pushNotifications: pushNotifications,
        customSettings: customSettings,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension UserPreferenceModelMapper on UserPreference {
  UserPreferencesTableCompanion toCompanion() => UserPreferencesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        theme: Value(theme),
        language: Value(language),
        notificationsEnabled: Value(notificationsEnabled),
        compactView: Value(compactView),
        emailNotifications: Value(emailNotifications),
        pushNotifications: Value(pushNotifications),
        customSettings: Value(customSettings),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
}
