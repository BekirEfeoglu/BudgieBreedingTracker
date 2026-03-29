import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_models.dart';
import 'admin_settings_actions.dart';
import 'admin_settings_widgets.dart';

/// Content body for the admin settings screen.
class AdminSettingsContent extends ConsumerStatefulWidget {
  final Map<String, Map<String, dynamic>> settings;
  const AdminSettingsContent({super.key, required this.settings});

  @override
  ConsumerState<AdminSettingsContent> createState() =>
      _AdminSettingsContentState();
}

class _AdminSettingsContentState extends ConsumerState<AdminSettingsContent> {
  String? _updatingKey;
  bool _isResetting = false;

  bool _val(String key) {
    final stored = widget.settings[key]?['value'];
    if (stored != null) return stored == true;
    return settingDefaults[key] ?? true;
  }

  String? _updatedAt(String key) {
    final raw = widget.settings[key]?['updated_at'] as String?;
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return 'admin.setting_last_change'.tr(
      args: [
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}',
      ],
    );
  }

  int _activeIn(List<String> keys) => keys.where(_val).length;

  Widget _toggle(
    String key,
    String titleKey,
    String descKey, {
    bool showDivider = true,
    bool requireConfirm = false,
    String? confirmTitleKey,
    String? confirmDescKey,
  }) {
    return EnhancedToggleSetting(
      title: 'admin.$titleKey'.tr(),
      subtitle: 'admin.$descKey'.tr(),
      value: _val(key),
      isUpdating: _updatingKey == key,
      lastUpdated: _updatedAt(key),
      showDivider: showDivider,
      onChanged: (v) => _handleToggle(
        key,
        v,
        requireConfirm: requireConfirm,
        confirmTitleKey: confirmTitleKey,
        confirmDescKey: confirmDescKey,
      ),
    );
  }

  Future<void> _handleToggle(
    String key,
    bool value, {
    bool requireConfirm = false,
    String? confirmTitleKey,
    String? confirmDescKey,
  }) async {
    setState(() => _updatingKey = key);
    await updateAdminSetting(
      context: context,
      ref: ref,
      key: key,
      value: value,
      requireConfirm: requireConfirm,
      confirmTitle:
          confirmTitleKey != null ? 'admin.$confirmTitleKey'.tr() : null,
      confirmMessage:
          confirmDescKey != null ? 'admin.$confirmDescKey'.tr() : null,
    );
    if (mounted) setState(() => _updatingKey = null);
  }

  Future<void> _resetToDefaults() async {
    setState(() => _isResetting = true);
    await resetAdminSettingsToDefaults(context: context, ref: ref);
    if (mounted) setState(() => _isResetting = false);
  }

  @override
  Widget build(BuildContext context) {
    // Typed snapshot for read-only access — writes still use string-keyed updateSetting().
    final typedSettings = AdminSystemSettings.fromSettingsMap(widget.settings);

    const systemKeys = [
      'maintenance_mode',
      'registration_open',
      'email_verification_required',
    ];
    const featureKeys = ['premium_enabled'];
    const securityKeys = ['rate_limiting_enabled', 'two_factor_required'];
    const dataKeys = ['auto_backup_enabled', 'auto_cleanup_enabled'];
    const notifKeys = ['global_push_enabled', 'email_alerts_enabled'];
    final allKeys = [
      ...systemKeys,
      ...featureKeys,
      ...securityKeys,
      ...dataKeys,
      ...notifKeys,
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsOverviewBanner(
            activeCount: _activeIn(allKeys),
            totalCount: allKeys.length,
            lastUpdatedAt: typedSettings.lastUpdated,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSystemSection(systemKeys),
          const SizedBox(height: AppSpacing.lg),
          _buildFeatureSection(featureKeys),
          const SizedBox(height: AppSpacing.lg),
          _buildSecuritySection(securityKeys),
          const SizedBox(height: AppSpacing.lg),
          _buildDataSection(dataKeys),
          const SizedBox(height: AppSpacing.lg),
          _buildNotificationSection(notifKeys),
          const SizedBox(height: AppSpacing.xl),
          ResetDefaultsButton(
            isLoading: _isResetting,
            onPressed: _resetToDefaults,
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildSystemSection(List<String> keys) => AccentSettingsSection(
    title: 'admin.system_settings'.tr(),
    description: 'admin.system_settings_desc'.tr(),
    icon: const AppIcon(AppIcons.settings),
    accentColor: AppColors.primary,
    activeCount: _activeIn(keys),
    totalCount: keys.length,
    children: [
      _toggle('maintenance_mode', 'maintenance_mode', 'maintenance_mode_desc',
          requireConfirm: true,
          confirmTitleKey: 'confirm_maintenance',
          confirmDescKey: 'confirm_maintenance_desc'),
      _toggle('registration_open', 'registration_open', 'registration_open_desc'),
      _toggle('email_verification_required', 'email_verification',
          'email_verification_desc', showDivider: false),
    ],
  );

  Widget _buildFeatureSection(List<String> keys) => AccentSettingsSection(
    title: 'admin.feature_flags'.tr(),
    description: 'admin.feature_flags_desc'.tr(),
    icon: const Icon(LucideIcons.flag),
    accentColor: AppColors.warning,
    activeCount: _activeIn(keys),
    totalCount: keys.length,
    children: [
      _toggle('premium_enabled', 'premium_features', 'premium_features_desc',
          showDivider: false),
    ],
  );

  Widget _buildSecuritySection(List<String> keys) => AccentSettingsSection(
    title: 'admin.security'.tr(),
    description: 'admin.security_settings_desc'.tr(),
    icon: const AppIcon(AppIcons.security),
    accentColor: AppColors.error,
    activeCount: _activeIn(keys),
    totalCount: keys.length,
    children: [
      _toggle('rate_limiting_enabled', 'rate_limiting_enabled', 'rate_limiting_desc'),
      _toggle('two_factor_required', 'two_factor_required', 'two_factor_required_desc',
          showDivider: false,
          requireConfirm: true,
          confirmTitleKey: 'confirm_two_factor',
          confirmDescKey: 'confirm_two_factor_desc'),
    ],
  );

  Widget _buildDataSection(List<String> keys) => AccentSettingsSection(
    title: 'admin.data_management'.tr(),
    description: 'admin.data_management_desc'.tr(),
    icon: const AppIcon(AppIcons.backup),
    accentColor: AppColors.info,
    activeCount: _activeIn(keys),
    totalCount: keys.length,
    children: [
      _toggle('auto_backup_enabled', 'auto_backup', 'auto_backup_desc'),
      _toggle('auto_cleanup_enabled', 'auto_cleanup', 'auto_cleanup_desc',
          showDivider: false),
    ],
  );

  Widget _buildNotificationSection(List<String> keys) => AccentSettingsSection(
    title: 'admin.notification_settings'.tr(),
    description: 'admin.notification_settings_desc'.tr(),
    icon: const AppIcon(AppIcons.notification),
    accentColor: AppColors.budgieGreen,
    activeCount: _activeIn(keys),
    totalCount: keys.length,
    children: [
      _toggle('global_push_enabled', 'global_push', 'global_push_desc'),
      _toggle('email_alerts_enabled', 'email_alerts', 'email_alerts_desc',
          showDivider: false),
    ],
  );
}
