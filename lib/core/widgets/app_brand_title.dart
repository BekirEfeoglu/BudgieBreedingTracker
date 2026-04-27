import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

/// Branded app title widget with bird icon and styled text.
///
/// Displays the app name as "Budgie" (bold primary) + "Breeding" (medium accent)
/// + "Tracker" (bold primary) with an optional bird icon.
class AppBrandTitle extends StatelessWidget {
  /// Controls the overall size of the brand title.
  final AppBrandSize size;

  /// Whether to show the bird icon before the text.
  final bool showIcon;

  const AppBrandTitle({
    super.key,
    this.size = AppBrandSize.medium,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = size == AppBrandSize.small;

    final primaryColor = theme.colorScheme.primary;
    final accentColor = isDark ? AppColors.accentLight : AppColors.accent;

    final double fontSize = switch (size) {
      AppBrandSize.small => 16,
      AppBrandSize.medium => 20,
      AppBrandSize.large => 26,
    };

    final double iconSize = switch (size) {
      AppBrandSize.small => 17,
      AppBrandSize.medium => 26,
      AppBrandSize.large => 52,
    };

    final double iconSpacing = switch (size) {
      AppBrandSize.small => AppSpacing.xs,
      AppBrandSize.medium => AppSpacing.sm,
      AppBrandSize.large => AppSpacing.md,
    };

    final shadows = isCompact
        ? <Shadow>[]
        : [
            Shadow(
              color: primaryColor.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
      height: 1.2,
      shadows: shadows,
    );

    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Budgie ',
            style: baseStyle.copyWith(color: primaryColor),
          ),
          TextSpan(
            text: 'Breeding ',
            style: baseStyle.copyWith(
              color: accentColor,
              fontWeight: isCompact ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0,
              fontStyle: isCompact ? FontStyle.normal : FontStyle.italic,
              shadows: isCompact
                  ? const []
                  : [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.20),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
          ),
          TextSpan(
            text: 'Tracker',
            style: baseStyle.copyWith(color: primaryColor),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );

    final Widget content;

    if (!showIcon) {
      content = text;
    } else if (size == AppBrandSize.large) {
      content = _LargeIcon(iconSize: iconSize);
    } else if (isCompact) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.bird, size: iconSize, color: primaryColor),
          SizedBox(width: iconSpacing),
          Flexible(child: text),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.bird, size: iconSize, color: primaryColor),
          SizedBox(width: iconSpacing),
          Flexible(child: text),
          SizedBox(width: iconSpacing),
          Transform.scale(
            scaleX: -1,
            child: AppIcon(AppIcons.bird, size: iconSize, color: accentColor),
          ),
        ],
      );
    }

    return Semantics(
      label: 'BudgieBreedingTracker',
      excludeSemantics: true,
      child: size == AppBrandSize.large
          ? content
          : FittedBox(fit: BoxFit.scaleDown, child: content),
    );
  }
}

/// Large app logo image for splash/login.
class _LargeIcon extends StatelessWidget {
  final double iconSize;

  const _LargeIcon({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final containerSize = iconSize * 3.0;

    return Image.asset(
      'assets/images/budgie-icon.png',
      width: containerSize,
      height: containerSize,
      fit: BoxFit.contain,
      cacheWidth: (containerSize * 2).toInt(),
      cacheHeight: (containerSize * 2).toInt(),
    );
  }
}

enum AppBrandSize { small, medium, large }
