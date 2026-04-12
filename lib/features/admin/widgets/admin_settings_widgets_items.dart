part of 'admin_settings_widgets.dart';

/// Enhanced toggle setting with status dot and optional last-updated text.
class EnhancedToggleSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool isUpdating;
  final String? lastUpdated;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  const EnhancedToggleSetting({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.isUpdating = false,
    this.lastUpdated,
    this.showDivider = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                    if (lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          lastUpdated!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isUpdating)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: AppSpacing.lg),
      ],
    );
  }
}

/// Button to reset all settings to defaults.
class ResetDefaultsButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const ResetDefaultsButton({
    super.key,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                LucideIcons.rotateCcw,
                color: theme.colorScheme.error,
                size: 20,
              ),
        label: Text(
          'admin.reset_defaults'.tr(),
          style: TextStyle(color: theme.colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
