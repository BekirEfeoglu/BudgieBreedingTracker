part of 'notification_settings_screen.dart';

class _BatteryWarningDismissedNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Load persisted dismissed state asynchronously on first build.
    _loadPersistedState();
    return false;
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed =
        prefs.getBool(AppPreferences.keyBatteryWarningDismissed) ?? false;
    if (dismissed && !state) {
      state = true;
    }
  }
}

final _batteryWarningDismissedProvider =
    NotifierProvider<_BatteryWarningDismissedNotifier, bool>(
      _BatteryWarningDismissedNotifier.new,
    );

/// Warning banner for Android battery optimization.
///
/// Shown at the top of notification settings to advise disabling
/// battery optimization for reliable notification delivery.
class _BatteryOptimizationBanner extends ConsumerStatefulWidget {
  const _BatteryOptimizationBanner({
    required this.isDismissed,
    this.onDismiss,
  });

  final bool isDismissed;
  final VoidCallback? onDismiss;

  @override
  ConsumerState<_BatteryOptimizationBanner> createState() =>
      _BatteryOptimizationBannerState();
}

class _BatteryOptimizationBannerState
    extends ConsumerState<_BatteryOptimizationBanner> {
  String _oemSteps = '';

  @override
  void initState() {
    super.initState();
    _loadOemSteps();
  }

  Future<void> _loadOemSteps() async {
    final manufacturer =
        await NotificationPermissionHandler.getDeviceManufacturer();
    if (!mounted) return;
    final steps = _oemBatterySteps(manufacturer);
    if (steps.isNotEmpty) {
      setState(() => _oemSteps = steps);
    }
  }

  String _oemBatterySteps(String manufacturer) {
    return switch (manufacturer) {
      'samsung' => 'notifications.battery_steps_samsung'.tr(),
      'xiaomi' || 'redmi' || 'poco' => 'notifications.battery_steps_xiaomi'
          .tr(),
      'huawei' || 'honor' => 'notifications.battery_steps_huawei'.tr(),
      'oppo' || 'realme' || 'oneplus' => 'notifications.battery_steps_oppo'
          .tr(),
      'vivo' || 'iqoo' => 'notifications.battery_steps_vivo'.tr(),
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDismissed || !Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.batteryWarning,
                color: theme.colorScheme.onErrorContainer,
                size: AppSpacing.xxl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'notifications.battery_optimization_warning'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'notifications.battery_optimization_steps'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
          if (_oemSteps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _oemSteps,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'notifications.battery_optimization_dismiss'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: () {
                  ref
                      .read(notificationServiceProvider)
                      .requestBatteryOptimizationExemptionIfNeeded();
                },
                icon: const Icon(LucideIcons.settings, size: 16),
                label: Text('notifications.battery_open_settings'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Warning banner shown when notification permission is denied.
///
/// Guides the user to open system notification settings to grant permission.
/// Only visible on Android when [notificationPermissionGrantedProvider] is false.
/// Automatically re-checks permission status when the user returns from
/// system settings (via [WidgetsBindingObserver.didChangeAppLifecycleState]).
class _NotificationPermissionBanner extends ConsumerStatefulWidget {
  const _NotificationPermissionBanner();

  @override
  ConsumerState<_NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends ConsumerState<_NotificationPermissionBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      _recheckPermission();
    }
  }

  Future<void> _recheckPermission() async {
    final notifService = ref.read(notificationServiceProvider);
    if (!notifService.isInitialized) return;

    final enabled = await notifService.areNotificationsEnabled();
    if (!mounted) return;

    final wasDisabled =
        ref.read(notificationPermissionGrantedProvider) == false;
    ref.read(notificationPermissionGrantedProvider.notifier).state = enabled;

    // Permission was just granted from settings — reschedule notifications.
    if (enabled && wasDisabled) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != 'anonymous') {
        try {
          await ref.read(notificationReschedulerProvider).rescheduleAll(userId);
        } catch (e) {
          AppLogger.warning(
            '[NotificationSettings] Reschedule after permission grant '
            'failed: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final granted = ref.watch(notificationPermissionGrantedProvider);
    if (granted) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.bellOff,
                color: theme.colorScheme.onErrorContainer,
                size: AppSpacing.xxl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'notifications.permission_denied_banner'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'notifications.permission_denied_banner_desc'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () {
                NotificationPermissionHandler.openNotificationSettings();
              },
              icon: const Icon(LucideIcons.settings, size: 16),
              label: Text('notifications.open_settings'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
