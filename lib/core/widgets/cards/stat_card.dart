import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../animations/count_up_animation.dart';


class StatCard extends StatefulWidget {
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
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isPressed = false;

  String _buildSemanticsLabel() {
    final buffer = StringBuffer('${widget.label}: ${widget.value}');
    if (widget.trendPercent != null && widget.trendUp != null) {
      if (widget.trendPercent == 0) {
        buffer.write(', ${'statistics.trend_stable'.tr()}');
      } else {
        final direction = widget.trendUp!
            ? 'statistics.trend_up'.tr()
            : 'statistics.trend_down'.tr();
        buffer.write(', $direction ${widget.trendPercent!.abs().toStringAsFixed(0)}%');
      }
    }
    return buffer.toString();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && mounted) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null && mounted) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null && mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);

    final semanticsLabel = _buildSemanticsLabel();

    final cardContent = Card(
      color: Colors.transparent, // Background handled by gradient container
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(
          color: cardColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withValues(alpha: 0.2),
                cardColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: widget.isHorizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.icon != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: IconTheme(
                          data: IconThemeData(size: 28, color: cardColor),
                          child: widget.icon!,
                        ),
                      ),
                    if (widget.icon != null) const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedStatValue(value: widget.value, color: cardColor),
                        const SizedBox(height: 2),
                        Text(
                          widget.label,
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
                    if (widget.icon != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: IconTheme(
                          data: IconThemeData(size: 20, color: cardColor),
                          child: widget.icon!,
                        ),
                      ),
                    const Spacer(),
                    _AnimatedStatValue(value: widget.value, color: cardColor),
                    if (widget.trendPercent != null && widget.trendUp != null) ...[
                      const SizedBox(height: 2),
                      _TrendIndicator(percent: widget.trendPercent!, isUp: widget.trendUp!),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      widget.label,
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
    );

    return Semantics(
      label: semanticsLabel,
      button: widget.onTap != null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: cardContent,
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
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
      );
    }

    return CountUpAnimation(
      end: numericValue,
      duration: const Duration(milliseconds: 800),
      suffix: isPercent ? '%' : null,
      precision: numericValue % 1 == 0 ? 0 : 1,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
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
