part of 'more_screen.dart';

void _showMoreAboutDialog(BuildContext context, WidgetRef ref) {
  final year = DateTime.now().year.toString();
  final appInfo = ref.read(appInfoProvider);
  final version = appInfo.when(
    data: (info) => 'v${info.version}',
    loading: () => 'v1.0.0',
    error: (_, __) => 'v1.0.0',
  );
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 88,
                height: 88,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'more.about_app_name'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                version,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(LucideIcons.user, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'more.about_developer'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () => launchUrl(Uri.parse('mailto:support@budgiebreedingtracker.online')),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  children: [
                    Icon(LucideIcons.mail, size: 16, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'support@budgiebreedingtracker.online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () => launchUrl(Uri.parse('https://budgiebreedingtracker.online/')),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  children: [
                    Icon(LucideIcons.globe, size: 16, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'budgiebreedingtracker.online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(LucideIcons.copyright, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'more.about_legalese'.tr(args: [year]),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      showLicensePage(
                        context: context,
                        applicationName: 'more.about_app_name'.tr(),
                        applicationVersion: version,
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: AppIcon(AppIcons.bird, size: 48, color: colorScheme.primary),
                        ),
                      );
                    },
                    child: Text('more.about_licenses'.tr()),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('common.close'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: IconTheme(
        data: IconThemeData(color: theme.colorScheme.primary, size: 24),
        child: icon,
      ),
      title: Text(title),
      trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            'premium.pro_badge'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.premiumGoldDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const Icon(LucideIcons.chevronRight, size: 18),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
