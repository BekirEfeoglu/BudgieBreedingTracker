part of 'backup_screen.dart';

class _InfoCard extends StatelessWidget {
  const _InfoCard({this.lastExport, required this.dateFormat});

  final DateTime? lastExport;
  final AppDateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = lastExport != null
        ? dateFormat.formatter(withTime: true).format(lastExport!)
        : 'backup.never'.tr();

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            AppIcon(
              AppIcons.database,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'backup.last_export'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(dateText, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.icon});

  final String title;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(size: 18, color: theme.colorScheme.primary),
            child: icon!,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  final Widget icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: AppSpacing.touchTargetMd,
                height: AppSpacing.touchTargetMd,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: IconTheme(
                  data: IconThemeData(color: color),
                  child: icon,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                Semantics(
                  label: 'common.loading'.tr(),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                AppIcon(
                  AppIcons.export,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium-gated auto-backup schedule picker. Free users see an upsell tile;
/// premium users pick a frequency (persisted via [BackupScheduler]). The
/// backup itself runs on app resume when due (see app.dart `_onAppResumed`).
class _AutoBackupSection extends ConsumerWidget {
  const _AutoBackupSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(effectivePremiumProvider);
    final dateFormat = ref.watch(dateFormatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'settings.auto_backup_title'.tr(),
          icon: const AppIcon(AppIcons.backup),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!isPremium)
          _ExportTile(
            icon: const AppIcon(AppIcons.backup),
            color: AppColors.info,
            title: 'settings.auto_backup_title'.tr(),
            subtitle: 'settings.auto_backup_premium_hint'.tr(),
            isLoading: false,
            onTap: () => context.push(AppRoutes.premium),
          )
        else
          ref
              .watch(backupScheduleControllerProvider)
              .when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LoadingState(),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('settings.auto_backup_error'.tr()),
                ),
                data: (schedule) => _AutoBackupControls(
                  schedule: schedule,
                  dateFormat: dateFormat,
                ),
              ),
      ],
    );
  }
}

class _AutoBackupControls extends ConsumerWidget {
  const _AutoBackupControls({required this.schedule, required this.dateFormat});

  final BackupScheduleState schedule;
  final AppDateFormat dateFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'settings.auto_backup_desc'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final freq in BackupFrequency.values)
          ListTile(
            title: Text(freq.labelKey.tr()),
            trailing: schedule.frequency == freq
                ? Icon(LucideIcons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => ref
                .read(backupScheduleControllerProvider.notifier)
                .setFrequency(freq),
          ),
        if (schedule.lastBackup != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
            ),
            child: Text(
              'settings.auto_backup_last'.tr(
                args: [
                  dateFormat.formatter(withTime: true).format(
                    schedule.lastBackup!,
                  ),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
