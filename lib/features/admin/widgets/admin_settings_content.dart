import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../providers/admin_monitoring_snapshot_providers.dart';
import '../providers/admin_providers.dart';
import 'admin_settings_actions.dart';
import 'admin_settings_widgets.dart';

part 'admin_settings_status_sections.dart';

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
    if (stored == null) return settingDefaults[key] ?? true;
    if (stored is bool) return stored;
    if (stored is String) return stored.toLowerCase() == 'true';
    if (stored is num) return stored != 0;
    AppLogger.warning(
      'AdminSettings: unexpected type ${stored.runtimeType} for key "$key"',
    );
    return settingDefaults[key] ?? true;
  }

  String? _updatedAt(String key) {
    final raw = widget.settings[key]?['updated_at'] as String?;
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    // Locale-aware date — tr/de expect `27.05.2026`, en expects
    // `5/27/2026`. Previously hardcoded `dd.MM.yyyy` shipped to
    // every locale (datetime-format.md violation). Convert to
    // device-local for display since `updated_at` is UTC.
    final locale = context.locale.toLanguageTag();
    final d = DateFormat.yMd(locale).format(dt.toLocal());
    return 'admin.setting_last_change'.tr(args: [d]);
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
      confirmTitle: confirmTitleKey != null
          ? 'admin.$confirmTitleKey'.tr()
          : null,
      confirmMessage: confirmDescKey != null
          ? 'admin.$confirmDescKey'.tr()
          : null,
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
    const featureKeys = [
      'premium_enabled',
      'community_enabled',
      'marketplace_enabled',
      'gamification_enabled',
      'messaging_enabled',
      'genetics_enabled',
    ];
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
          _buildAppUpdateSection(),
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
          const SizedBox(height: AppSpacing.lg),
          const _RolePermissionMatrixSection(),
          const SizedBox(height: AppSpacing.lg),
          const _CronStatusSection(),
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
      _toggle(
        'maintenance_mode',
        'maintenance_mode',
        'maintenance_mode_desc',
        requireConfirm: true,
        confirmTitleKey: 'confirm_maintenance',
        confirmDescKey: 'confirm_maintenance_desc',
      ),
      _toggle(
        'registration_open',
        'registration_open',
        'registration_open_desc',
      ),
      _toggle(
        'email_verification_required',
        'email_verification',
        'email_verification_desc',
        showDivider: false,
      ),
    ],
  );

  Future<void> _editAppVersionSettings() async {
    final current = AdminAppVersionConfig.fromSettingValue(
      widget.settings['app_version']?['value'],
    );
    final updated = await showDialog<AdminAppVersionConfig>(
      context: context,
      builder: (context) => _AppVersionEditDialog(initialValue: current),
    );
    if (updated == null || !mounted) return;

    final raisesMinimumBuild =
        updated.ios.minSupportedBuild > current.ios.minSupportedBuild ||
        updated.android.minSupportedBuild > current.android.minSupportedBuild;
    if (raisesMinimumBuild) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'admin.confirm_min_supported_build'.tr(),
        message: 'admin.confirm_min_supported_build_desc'.tr(),
        isDestructive: true,
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _updatingKey = 'app_version');
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(adminSettingsActionProvider.notifier)
        .updateJsonSetting(
          key: 'app_version',
          value: updated.toJson(),
          isPublic: true,
        );

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'admin.app_version_updated'.tr()
              : 'admin.setting_update_error'.tr(),
        ),
      ),
    );
    if (mounted) setState(() => _updatingKey = null);
  }

  Widget _buildAppUpdateSection() {
    final config = AdminAppVersionConfig.fromSettingValue(
      widget.settings['app_version']?['value'],
    );
    final isUpdating = _updatingKey == 'app_version';
    return AccentSettingsSection(
      title: 'admin.app_update_settings'.tr(),
      description: 'admin.app_update_settings_desc'.tr(),
      icon: const Icon(LucideIcons.uploadCloud),
      accentColor: AppColors.info,
      activeCount: 1,
      totalCount: 1,
      children: [
        _AppVersionPlatformSummary(title: 'admin.ios'.tr(), config: config.ios),
        const Divider(height: 1, indent: AppSpacing.lg),
        _AppVersionPlatformSummary(
          title: 'admin.android'.tr(),
          config: config.android,
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUpdating ? null : _editAppVersionSettings,
              icon: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.edit3, size: 18),
              label: Text('admin.edit_app_update_settings'.tr()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureSection(List<String> keys) => AccentSettingsSection(
    title: 'admin.feature_flags'.tr(),
    description: 'admin.feature_flags_desc'.tr(),
    icon: const Icon(LucideIcons.flag),
    accentColor: AppColors.warning,
    activeCount: _activeIn(keys),
    totalCount: keys.length,
    children: [
      _toggle('premium_enabled', 'premium_features', 'premium_features_desc'),
      _toggle(
        'community_enabled',
        'community_feature',
        'community_feature_desc',
      ),
      _toggle(
        'marketplace_enabled',
        'marketplace_feature',
        'marketplace_feature_desc',
      ),
      _toggle(
        'gamification_enabled',
        'gamification_feature',
        'gamification_feature_desc',
      ),
      _toggle(
        'messaging_enabled',
        'messaging_feature',
        'messaging_feature_desc',
      ),
      _toggle(
        'genetics_enabled',
        'genetics_feature',
        'genetics_feature_desc',
        showDivider: false,
      ),
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
      _toggle(
        'rate_limiting_enabled',
        'rate_limiting_enabled',
        'rate_limiting_desc',
      ),
      _toggle(
        'two_factor_required',
        'two_factor_required',
        'two_factor_required_desc',
        showDivider: false,
        requireConfirm: true,
        confirmTitleKey: 'confirm_two_factor',
        confirmDescKey: 'confirm_two_factor_desc',
      ),
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
      _toggle(
        'auto_cleanup_enabled',
        'auto_cleanup',
        'auto_cleanup_desc',
        showDivider: false,
      ),
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
      _toggle(
        'email_alerts_enabled',
        'email_alerts',
        'email_alerts_desc',
        showDivider: false,
      ),
    ],
  );
}

class _AppVersionPlatformSummary extends StatelessWidget {
  const _AppVersionPlatformSummary({required this.title, required this.config});

  final String title;
  final AdminPlatformVersionConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.smartphone,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'admin.version_summary'.tr(
                    args: [config.latestVersion, config.latestBuild.toString()],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  config.minSupportedBuild == 0
                      ? 'admin.force_update_disabled'.tr()
                      : 'admin.minimum_build_summary'.tr(
                          args: [config.minSupportedBuild.toString()],
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppVersionEditDialog extends StatefulWidget {
  const _AppVersionEditDialog({required this.initialValue});

  final AdminAppVersionConfig initialValue;

  @override
  State<_AppVersionEditDialog> createState() => _AppVersionEditDialogState();
}

class _AppVersionEditDialogState extends State<_AppVersionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _PlatformVersionControllers _ios;
  late final _PlatformVersionControllers _android;

  @override
  void initState() {
    super.initState();
    _ios = _PlatformVersionControllers.fromConfig(widget.initialValue.ios);
    _android = _PlatformVersionControllers.fromConfig(
      widget.initialValue.android,
    );
  }

  @override
  void dispose() {
    _ios.dispose();
    _android.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('admin.edit_app_update_settings'.tr()),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlatformFields('admin.ios'.tr(), _ios),
                const SizedBox(height: AppSpacing.lg),
                _buildPlatformFields('admin.android'.tr(), _android),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(onPressed: _save, child: Text('common.save'.tr())),
      ],
    );
  }

  Widget _buildPlatformFields(
    String title,
    _PlatformVersionControllers controllers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controllers.latestVersion,
          decoration: InputDecoration(labelText: 'admin.latest_version'.tr()),
          validator: _required,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers.latestBuild,
                decoration: InputDecoration(
                  labelText: 'admin.latest_build'.tr(),
                ),
                keyboardType: TextInputType.number,
                validator: _nonNegativeInt,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: controllers.minSupportedBuild,
                decoration: InputDecoration(
                  labelText: 'admin.min_supported_build'.tr(),
                  helperText: 'admin.min_supported_build_hint'.tr(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    _minSupportedBuild(value, controllers.latestBuild.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controllers.storeUrl,
          decoration: InputDecoration(labelText: 'admin.store_url'.tr()),
          keyboardType: TextInputType.url,
          validator: _storeUrl,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controllers.releaseNotesTr,
          decoration: InputDecoration(labelText: 'admin.release_notes_tr'.tr()),
          minLines: 2,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controllers.releaseNotesEn,
          decoration: InputDecoration(labelText: 'admin.release_notes_en'.tr()),
          minLines: 2,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controllers.releaseNotesDe,
          decoration: InputDecoration(labelText: 'admin.release_notes_de'.tr()),
          minLines: 2,
          maxLines: 3,
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'admin.platform_version_required'.tr()
        : null;
  }

  String? _nonNegativeInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0
        ? 'admin.invalid_build_number'.tr()
        : null;
  }

  String? _minSupportedBuild(String? value, String latestBuildValue) {
    final numericError = _nonNegativeInt(value);
    if (numericError != null) return numericError;

    final minimumBuild = int.parse(value!.trim());
    final latestBuild = int.tryParse(latestBuildValue.trim());
    if (latestBuild != null && minimumBuild > latestBuild) {
      return 'admin.min_build_exceeds_latest'.tr();
    }
    return null;
  }

  String? _storeUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return 'admin.invalid_store_url'.tr();
    }
    return null;
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      AdminAppVersionConfig(ios: _ios.toConfig(), android: _android.toConfig()),
    );
  }
}

class _PlatformVersionControllers {
  _PlatformVersionControllers({
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedBuild,
    required this.storeUrl,
    required this.releaseNotesTr,
    required this.releaseNotesEn,
    required this.releaseNotesDe,
  });

  factory _PlatformVersionControllers.fromConfig(
    AdminPlatformVersionConfig config,
  ) {
    return _PlatformVersionControllers(
      latestVersion: TextEditingController(text: config.latestVersion),
      latestBuild: TextEditingController(text: config.latestBuild.toString()),
      minSupportedBuild: TextEditingController(
        text: config.minSupportedBuild.toString(),
      ),
      storeUrl: TextEditingController(text: config.storeUrl),
      releaseNotesTr: TextEditingController(text: config.releaseNotesTr ?? ''),
      releaseNotesEn: TextEditingController(text: config.releaseNotesEn ?? ''),
      releaseNotesDe: TextEditingController(text: config.releaseNotesDe ?? ''),
    );
  }

  final TextEditingController latestVersion;
  final TextEditingController latestBuild;
  final TextEditingController minSupportedBuild;
  final TextEditingController storeUrl;
  final TextEditingController releaseNotesTr;
  final TextEditingController releaseNotesEn;
  final TextEditingController releaseNotesDe;

  AdminPlatformVersionConfig toConfig() {
    return AdminPlatformVersionConfig(
      latestVersion: latestVersion.text.trim(),
      latestBuild: int.parse(latestBuild.text.trim()),
      minSupportedBuild: int.parse(minSupportedBuild.text.trim()),
      storeUrl: storeUrl.text.trim(),
      releaseNotesTr: _blankToNull(releaseNotesTr.text),
      releaseNotesEn: _blankToNull(releaseNotesEn.text),
      releaseNotesDe: _blankToNull(releaseNotesDe.text),
    );
  }

  void dispose() {
    latestVersion.dispose();
    latestBuild.dispose();
    minSupportedBuild.dispose();
    storeUrl.dispose();
    releaseNotesTr.dispose();
    releaseNotesEn.dispose();
    releaseNotesDe.dispose();
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
