import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  final Color? color;
  final VoidCallback? onTap;
  final double? trendPercent;
  final bool? trendUp;
  final bool isHorizontal;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
    this.trendPercent,
    this.trendUp,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $value',
      button: onTap != null,
      child: Card(
        color: cardColor.withValues(alpha: 0.10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(
            color: cardColor.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: isHorizontal
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (icon != null)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: IconTheme(
                            data: IconThemeData(size: 28, color: cardColor),
                            child: icon!,
                          ),
                        ),
                      if (icon != null) const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AnimatedStatValue(value: value, color: cardColor),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs + 2),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: IconTheme(
                            data: IconThemeData(size: 18, color: cardColor),
                            child: icon!,
                          ),
                        ),
                      const Spacer(),
                      _AnimatedStatValue(value: value, color: cardColor),
                      if (trendPercent != null && trendUp != null) ...[
                        const SizedBox(height: 2),
                        _TrendIndicator(percent: trendPercent!, isUp: trendUp!),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStatValue extends StatelessWidget {
  const _AnimatedStatValue({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final numericValue = double.tryParse(value.replaceAll('%', ''));
    final isPercent = value.contains('%');

    if (numericValue == null) {
      return Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: numericValue),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final displayValue = animatedValue % 1 == 0
            ? animatedValue.toInt().toString()
            : animatedValue.toStringAsFixed(0);
        return Text(
          isPercent ? '$displayValue%' : displayValue,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({required this.percent, required this.isUp});

  final double percent;
  final bool isUp;

  @override
  Widget build(BuildContext context) {
    if (percent == 0) {
      return Text(
        'statistics.trend_stable'.tr(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final trendColor = isUp ? AppColors.success : AppColors.error;
    final icon = isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown;
    final sign = isUp ? '+' : '-';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: trendColor),
        const SizedBox(width: 2),
        Text(
          '$sign${percent.abs().toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: trendColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
