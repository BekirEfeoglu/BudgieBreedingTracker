import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_settings_widgets.dart';

const _settingDefaults = <String, bool>{
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

/// Admin settings screen with categorized system toggles.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(adminSystemSettingsProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminSystemSettingsProvider),
        child: settingsAsync.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(adminSystemSettingsProvider),
          ),
          data: (settings) => _SettingsContent(settings: settings),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  final Map<String, Map<String, dynamic>> settings;
  const _SettingsContent({required this.settings});

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  String? _updatingKey;
  bool _isResetting = false;

  bool _val(String key) {
    final stored = widget.settings[key]?['value'];
    if (stored != null) return stored == true;
    return _settingDefaults[key] ?? true;
  }

  String? _updatedAt(String key) {
    final raw = widget.settings[key]?['updated_at'] as String?;
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return 'admin.setting_last_change'.tr(args: [
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}',
    ]);
  }

  int _activeIn(List<String> keys) => keys.where(_val).length;

  DateTime? get _lastGlobalUpdate {
    DateTime? latest;
    for (final entry in widget.settings.values) {
      final raw = entry['updated_at'] as String?;
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw);
      if (dt != null && (latest == null || dt.isAfter(latest))) latest = dt;
    }
    return latest;
  }

  Widget _toggle(String key, String titleKey, String descKey, {bool showDivider = true,
    bool requireConfirm = false, String? confirmTitleKey, String? confirmDescKey}) {
    return EnhancedToggleSetting(
      title: 'admin.$titleKey'.tr(),
      subtitle: 'admin.$descKey'.tr(),
      value: _val(key),
      isUpdating: _updatingKey == key,
      lastUpdated: _updatedAt(key),
      showDivider: showDivider,
      onChanged: (v) => _updateSetting(key, v,
        requireConfirm: requireConfirm,
        confirmTitle: confirmTitleKey != null ? 'admin.$confirmTitleKey'.tr() : null,
        confirmMessage: confirmDescKey != null ? 'admin.$confirmDescKey'.tr() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const systemKeys = ['maintenance_mode', 'registration_open', 'email_verification_required'];
    const featureKeys = ['premium_enabled'];
    const securityKeys = ['rate_limiting_enabled', 'two_factor_required'];
    const dataKeys = ['auto_backup_enabled', 'auto_cleanup_enabled'];
    const notifKeys = ['global_push_enabled', 'email_alerts_enabled'];
    final allKeys = [...systemKeys, ...featureKeys, ...securityKeys, ...dataKeys, ...notifKeys];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsOverviewBanner(
            activeCount: _activeIn(allKeys),
            totalCount: allKeys.length,
            lastUpdatedAt: _lastGlobalUpdate,
          ),
          const SizedBox(height: AppSpacing.lg),
          AccentSettingsSection(
            title: 'admin.system_settings'.tr(),
            description: 'admin.system_settings_desc'.tr(),
            icon: const AppIcon(AppIcons.settings),
            accentColor: AppColors.primary,
            activeCount: _activeIn(systemKeys),
            totalCount: systemKeys.length,
            children: [
              _toggle('maintenance_mode', 'maintenance_mode', 'maintenance_mode_desc',
                  requireConfirm: true, confirmTitleKey: 'confirm_maintenance', confirmDescKey: 'confirm_maintenance_desc'),
              _toggle('registration_open', 'registration_open', 'registration_open_desc'),
              _toggle('email_verification_required', 'email_verification', 'email_verification_desc', showDivider: false),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AccentSettingsSection(
            title: 'admin.feature_flags'.tr(),
            description: 'admin.feature_flags_desc'.tr(),
            icon: const Icon(LucideIcons.flag),
            accentColor: AppColors.warning,
            activeCount: _activeIn(featureKeys),
            totalCount: featureKeys.length,
            children: [
              _toggle('premium_enabled', 'premium_features', 'premium_features_desc', showDivider: false),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AccentSettingsSection(
            title: 'admin.security'.tr(),
            description: 'admin.security_settings_desc'.tr(),
            icon: const AppIcon(AppIcons.security),
            accentColor: AppColors.error,
            activeCount: _activeIn(securityKeys),
            totalCount: securityKeys.length,
            children: [
              _toggle('rate_limiting_enabled', 'rate_limiting_enabled', 'rate_limiting_desc'),
              _toggle('two_factor_required', 'two_factor_required', 'two_factor_required_desc',
                  showDivider: false, requireConfirm: true,
                  confirmTitleKey: 'confirm_two_factor', confirmDescKey: 'confirm_two_factor_desc'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AccentSettingsSection(
            title: 'admin.data_management'.tr(),
            description: 'admin.data_management_desc'.tr(),
            icon: const AppIcon(AppIcons.backup),
            accentColor: AppColors.info,
            activeCount: _activeIn(dataKeys),
            totalCount: dataKeys.length,
            children: [
              _toggle('auto_backup_enabled', 'auto_backup', 'auto_backup_desc'),
              _toggle('auto_cleanup_enabled', 'auto_cleanup', 'auto_cleanup_desc', showDivider: false),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AccentSettingsSection(
            title: 'admin.notification_settings'.tr(),
            description: 'admin.notification_settings_desc'.tr(),
            icon: const AppIcon(AppIcons.notification),
            accentColor: AppColors.budgieGreen,
            activeCount: _activeIn(notifKeys),
            totalCount: notifKeys.length,
            children: [
              _toggle('global_push_enabled', 'global_push', 'global_push_desc'),
              _toggle('email_alerts_enabled', 'email_alerts', 'email_alerts_desc', showDivider: false),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ResetDefaultsButton(isLoading: _isResetting, onPressed: _resetToDefaults),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Future<void> _updateSetting(String key, bool value, {
    bool requireConfirm = false, String? confirmTitle, String? confirmMessage,
  }) async {
    if (requireConfirm) {
      final confirmed = await showConfirmDialog(context,
        title: confirmTitle ?? 'admin.confirm_maintenance'.tr(),
        message: confirmMessage ?? 'admin.confirm_maintenance_desc'.tr(),
        isDestructive: true,
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    setState(() => _updatingKey = key);
    final client = ref.read(supabaseClientProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await client.from(SupabaseConstants.systemSettingsTable).upsert({
        'key': key, 'value': value, 'category': _categoryForKey(key),
        'is_public': false, 'updated_by': client.auth.currentUser?.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'key');
      ref.invalidate(adminSystemSettingsProvider);
      messenger.showSnackBar(SnackBar(content: Text('admin.setting_updated'.tr())));
    } catch (e, st) {
      AppLogger.error('AdminSettings._updateSetting', e, st);
      messenger.showSnackBar(SnackBar(content: Text('admin.setting_update_error'.tr())));
    } finally {
      if (mounted) setState(() => _updatingKey = null);
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showConfirmDialog(context,
      title: 'admin.confirm_reset_defaults'.tr(),
      message: 'admin.confirm_reset_defaults_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isResetting = true);
    final client = ref.read(supabaseClientProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final entry in _settingDefaults.entries) {
        await client.from(SupabaseConstants.systemSettingsTable).upsert({
          'key': entry.key, 'value': entry.value, 'category': _categoryForKey(entry.key),
          'is_public': false, 'updated_by': client.auth.currentUser?.id,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'key');
      }
      ref.invalidate(adminSystemSettingsProvider);
      messenger.showSnackBar(SnackBar(content: Text('admin.defaults_restored'.tr())));
    } catch (e, st) {
      AppLogger.error('AdminSettings._resetToDefaults', e, st);
      messenger.showSnackBar(SnackBar(content: Text('admin.setting_update_error'.tr())));
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  static String _categoryForKey(String key) {
    if (key.contains('maintenance') || key.contains('registration') || key.contains('email_verification')) {
      return 'maintenance';
    }
    if (key.contains('rate_limiting') || key.contains('two_factor')) return 'security';
    if (key.contains('backup') || key.contains('cleanup')) return 'backup';
    if (key.contains('push') || key.contains('email_alerts')) return 'notification';
    if (key.contains('storage')) return 'storage';
    if (key.contains('community')) return 'community';
    return 'general';
  }
}
