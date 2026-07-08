import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../shared/providers/auth.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_providers.dart';

/// Default values for admin system settings.
const settingDefaults = <String, bool>{
  'maintenance_mode': false,
  'registration_open': true,
  'email_verification_required': true,
  'premium_enabled': true,
  'rate_limiting_enabled': true,
  'two_factor_required': false,
  'auto_backup_enabled': false,
  'auto_cleanup_enabled': false,
  'global_push_enabled': true,
  'email_alerts_enabled': true,
};

/// Determines the category string for a given setting key.
String categoryForKey(String key) {
  if (key == 'app_version') return 'release';
  if (key.contains('maintenance') ||
      key.contains('registration') ||
      key.contains('email_verification')) {
    return 'maintenance';
  }
  if (key.contains('rate_limiting') || key.contains('two_factor')) {
    return 'security';
  }
  if (key.contains('backup') || key.contains('cleanup')) return 'backup';
  if (key.contains('push') || key.contains('email_alerts')) {
    return 'notification';
  }
  if (key.contains('storage')) return 'storage';
  if (key.contains('community')) return 'community';
  return 'general';
}

class AdminPlatformVersionConfig {
  const AdminPlatformVersionConfig({
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedBuild,
    required this.storeUrl,
    this.releaseNotesTr,
    this.releaseNotesEn,
    this.releaseNotesDe,
  });

  final String latestVersion;
  final int latestBuild;
  final int minSupportedBuild;
  final String storeUrl;
  final String? releaseNotesTr;
  final String? releaseNotesEn;
  final String? releaseNotesDe;

  factory AdminPlatformVersionConfig.fromValue(
    Object? value, {
    required String defaultStoreUrl,
  }) {
    if (value is String) {
      return AdminPlatformVersionConfig(
        latestVersion: value.trim(),
        latestBuild: 0,
        minSupportedBuild: 0,
        storeUrl: defaultStoreUrl,
      );
    }

    if (value is Map) {
      return AdminPlatformVersionConfig(
        latestVersion:
            _readString(value, const [
              'latest_version',
              'latestVersion',
              'version',
            ]) ??
            AppConstants.appVersion,
        latestBuild:
            _readInt(value, const ['latest_build', 'latestBuild']) ?? 0,
        minSupportedBuild:
            _readInt(value, const [
              'min_supported_build',
              'minSupportedBuild',
              'minimum_build',
            ]) ??
            0,
        storeUrl:
            _readString(value, const ['store_url', 'storeUrl']) ??
            defaultStoreUrl,
        releaseNotesTr: _readString(value, const [
          'release_notes_tr',
          'releaseNotesTr',
        ]),
        releaseNotesEn: _readString(value, const [
          'release_notes_en',
          'releaseNotesEn',
        ]),
        releaseNotesDe: _readString(value, const [
          'release_notes_de',
          'releaseNotesDe',
        ]),
      );
    }

    return AdminPlatformVersionConfig(
      latestVersion: AppConstants.appVersion,
      latestBuild: 0,
      minSupportedBuild: 0,
      storeUrl: defaultStoreUrl,
    );
  }

  AdminPlatformVersionConfig copyWith({
    String? latestVersion,
    int? latestBuild,
    int? minSupportedBuild,
    String? storeUrl,
    String? releaseNotesTr,
    String? releaseNotesEn,
    String? releaseNotesDe,
  }) {
    return AdminPlatformVersionConfig(
      latestVersion: latestVersion ?? this.latestVersion,
      latestBuild: latestBuild ?? this.latestBuild,
      minSupportedBuild: minSupportedBuild ?? this.minSupportedBuild,
      storeUrl: storeUrl ?? this.storeUrl,
      releaseNotesTr: releaseNotesTr ?? this.releaseNotesTr,
      releaseNotesEn: releaseNotesEn ?? this.releaseNotesEn,
      releaseNotesDe: releaseNotesDe ?? this.releaseNotesDe,
    );
  }

  Map<String, Object?> toJson() => {
    'latest_version': latestVersion,
    'latest_build': latestBuild,
    'min_supported_build': minSupportedBuild,
    'store_url': storeUrl,
    'release_notes_tr': releaseNotesTr,
    'release_notes_en': releaseNotesEn,
    'release_notes_de': releaseNotesDe,
  };
}

class AdminAppVersionConfig {
  const AdminAppVersionConfig({required this.ios, required this.android});

  final AdminPlatformVersionConfig ios;
  final AdminPlatformVersionConfig android;

  factory AdminAppVersionConfig.fromSettingValue(Object? value) {
    if (value is Map) {
      return AdminAppVersionConfig(
        ios: AdminPlatformVersionConfig.fromValue(
          value['ios'] ?? value,
          defaultStoreUrl: AppConstants.appStoreProductUrl,
        ),
        android: AdminPlatformVersionConfig.fromValue(
          value['android'] ?? value,
          defaultStoreUrl: AppConstants.playStoreUrl,
        ),
      );
    }

    return AdminAppVersionConfig(
      ios: AdminPlatformVersionConfig.fromValue(
        value,
        defaultStoreUrl: AppConstants.appStoreProductUrl,
      ),
      android: AdminPlatformVersionConfig.fromValue(
        value,
        defaultStoreUrl: AppConstants.playStoreUrl,
      ),
    );
  }

  Map<String, Object?> toJson() => {
    'ios': ios.toJson(),
    'android': android.toJson(),
  };
}

String? _readString(Map<dynamic, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

int? _readInt(Map<dynamic, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

/// State for admin settings operations.
class AdminSettingsActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AdminSettingsActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AdminSettingsActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) => AdminSettingsActionState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

/// Notifier that handles admin settings Supabase operations.
class AdminSettingsActionNotifier extends Notifier<AdminSettingsActionState> {
  @override
  AdminSettingsActionState build() => const AdminSettingsActionState();

  /// Updates a single setting in Supabase system_settings table.
  Future<bool> updateSetting({required String key, required bool value}) async {
    return _updateSettingValue(
      key: key,
      value: value,
      category: categoryForKey(key),
      isPublic: false,
    );
  }

  Future<bool> updateJsonSetting({
    required String key,
    required Object? value,
    String? category,
    bool isPublic = false,
  }) {
    return _updateSettingValue(
      key: key,
      value: value,
      category: category ?? categoryForKey(key),
      isPublic: isPublic,
    );
  }

  Future<bool> _updateSettingValue({
    required String key,
    required Object? value,
    required String category,
    required bool isPublic,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      await client.rpc(
        'admin_update_system_setting',
        params: {
          'p_key': key,
          'p_value': value,
          'p_category': category,
          'p_is_public': isPublic,
        },
      );
      // Invalidate AND await the next fetch before returning success.
      // Without the await, the caller clears its `_updatingKey`
      // spinner immediately and the Switch re-reads from the *stale*
      // settings prop for one frame, snapping back to the old value
      // before flipping to the new one — visible flicker.
      ref.invalidate(adminSystemSettingsProvider);
      await ref.read(adminSystemSettingsProvider.future);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e, st) {
      AppLogger.error('AdminSettingsAction.updateSetting', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.setting_update_error'.tr(),
      );
      return false;
    }
  }

  /// Resets all settings to their defaults.
  Future<bool> resetToDefaults() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final settings = settingDefaults.entries
          .map(
            (entry) => <String, dynamic>{
              'key': entry.key,
              'value': entry.value,
              'category': categoryForKey(entry.key),
              'is_public': false,
            },
          )
          .toList();
      await client.rpc(
        'admin_reset_system_settings',
        params: {'p_settings': settings},
      );
      ref.invalidate(adminSystemSettingsProvider);
      await ref.read(adminSystemSettingsProvider.future);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e, st) {
      AppLogger.error('AdminSettingsAction.resetToDefaults', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.setting_update_error'.tr(),
      );
      return false;
    }
  }

  void reset() => state = const AdminSettingsActionState();
}

/// Provider for admin settings actions.
final adminSettingsActionProvider =
    NotifierProvider<AdminSettingsActionNotifier, AdminSettingsActionState>(
      AdminSettingsActionNotifier.new,
    );

/// Updates a single setting via the notifier, with optional confirmation dialog.
Future<void> updateAdminSetting({
  required BuildContext context,
  required WidgetRef ref,
  required String key,
  required bool value,
  bool requireConfirm = false,
  String? confirmTitle,
  String? confirmMessage,
}) async {
  if (requireConfirm) {
    final confirmed = await showConfirmDialog(
      context,
      title: confirmTitle ?? 'admin.confirm_maintenance'.tr(),
      message: confirmMessage ?? 'admin.confirm_maintenance_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
  }
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(adminSettingsActionProvider.notifier);
  final success = await notifier.updateSetting(key: key, value: value);
  if (success) {
    ActionFeedbackService.show('admin.setting_updated'.tr());
  } else {
    messenger.showSnackBar(
      SnackBar(content: Text('admin.setting_update_error'.tr())),
    );
  }
}

/// Resets all settings to their defaults via the notifier, after confirmation.
Future<bool> resetAdminSettingsToDefaults({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'admin.confirm_reset_defaults'.tr(),
    message: 'admin.confirm_reset_defaults_desc'.tr(),
    isDestructive: true,
  );
  if (confirmed != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(adminSettingsActionProvider.notifier);
  final success = await notifier.resetToDefaults();
  if (success) {
    ActionFeedbackService.show('admin.defaults_restored'.tr());
    return true;
  } else {
    messenger.showSnackBar(
      SnackBar(content: Text('admin.setting_update_error'.tr())),
    );
    return false;
  }
}
