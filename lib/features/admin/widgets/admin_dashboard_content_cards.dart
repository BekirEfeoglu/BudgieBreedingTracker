part of 'admin_dashboard_content.dart';

/// Single admin stat card.
class DashboardStatCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final Color color;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numericValue = double.tryParse(value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth < AdminConstants.compactGridBreakpoint / 2;
        final valueStyle =
            (isCompact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium)
                ?.copyWith(color: color, fontWeight: FontWeight.bold);

        return Card(
          child: Padding(
            padding: isCompact
                ? const EdgeInsets.all(AppSpacing.md)
                : AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: color,
                    size: isCompact ? 20 : 24,
                  ),
                  child: icon,
                ),
                SizedBox(height: isCompact ? AppSpacing.xxs : AppSpacing.xs),
                if (numericValue != null)
                  Flexible(
                    fit: FlexFit.loose,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: numericValue),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(v.toInt().toString(), style: valueStyle),
                      ),
                    ),
                  )
                else
                  Flexible(
                    fit: FlexFit.loose,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: valueStyle),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Quick action button for dashboard.
class DashboardQuickActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const DashboardQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            children: [
              IconTheme(
                data: IconThemeData(color: theme.colorScheme.primary, size: 24),
                child: icon,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
