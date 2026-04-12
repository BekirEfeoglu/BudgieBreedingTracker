import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/action_feedback_providers.dart';
import '../providers/admin_auth_utils.dart';
import '../providers/admin_providers.dart';

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
  Future<bool> updateSetting({
    required String key,
    required bool value,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      await client.from(SupabaseConstants.systemSettingsTable).upsert({
        'key': key,
        'value': value,
        'category': categoryForKey(key),
        'is_public': false,
        'updated_by': client.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'key');
      ref.invalidate(adminSystemSettingsProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e, st) {
      AppLogger.error('AdminSettingsAction.updateSetting', e, st);
      state = state.copyWith(isLoading: false, error: 'admin.setting_update_error'.tr());
      return false;
    }
  }

  /// Resets all settings to their defaults.
  Future<bool> resetToDefaults() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final now = DateTime.now().toUtc().toIso8601String();
      final userId = client.auth.currentUser?.id;
      await Future.wait(
        settingDefaults.entries.map((entry) =>
          client.from(SupabaseConstants.systemSettingsTable).upsert({
            'key': entry.key,
            'value': entry.value,
            'category': categoryForKey(entry.key),
            'is_public': false,
            'updated_by': userId,
            'updated_at': now,
          }, onConflict: 'key'),
        ),
      );
      ref.invalidate(adminSystemSettingsProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e, st) {
      AppLogger.error('AdminSettingsAction.resetToDefaults', e, st);
      state = state.copyWith(isLoading: false, error: 'admin.setting_update_error'.tr());
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
