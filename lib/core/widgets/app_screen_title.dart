import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_icon.dart';

/// Reusable app bar title with a leading icon and optional subtitle.
class AppScreenTitle extends StatelessWidget {
  final String title;
  final String? iconAsset;
  final IconData? icon;
  final String? subtitle;
  final double iconSize;

  const AppScreenTitle({
    super.key,
    required this.title,
    this.iconAsset,
    this.icon,
    this.subtitle,
    this.iconSize = 20,
  }) : assert(iconAsset != null || icon != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = DefaultTextStyle.of(context).style;
    final effectiveColor =
        defaultTextStyle.color ??
        IconTheme.of(context).color ??
        theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconAsset != null)
          AppIcon(iconAsset!, size: iconSize, color: effectiveColor)
        else
          Icon(icon, size: iconSize, color: effectiveColor),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: subtitle == null
              ? Text(title, overflow: TextOverflow.ellipsis)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, overflow: TextOverflow.ellipsis),
                    Text(
                      subtitle!,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
