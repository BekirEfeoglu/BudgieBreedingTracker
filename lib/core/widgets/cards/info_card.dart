import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

class InfoCard extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const InfoCard({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '${subtitle ?? ''}: $title',
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                if (icon != null) ...[
                  ExcludeSemantics(
                    child: IconTheme(
                      data: IconThemeData(
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: icon!,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
