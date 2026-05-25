part of 'marketplace_form_screen.dart';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _LinkedBirdCard extends StatelessWidget {
  const _LinkedBirdCard({
    required this.linkedBirdId,
    required this.linkedBirdName,
    required this.onPick,
    required this.onClear,
  });

  final String? linkedBirdId;
  final String? linkedBirdName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (linkedBirdId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.bird, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'marketplace.linked_bird'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    linkedBirdName ?? linkedBirdId!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: Icon(
                LucideIcons.x,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              semanticLabel: 'common.clear'.tr(),
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const AppIcon(AppIcons.bird, size: 18),
      label: Text('marketplace.select_bird'.tr()),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSpacing.touchTargetMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
