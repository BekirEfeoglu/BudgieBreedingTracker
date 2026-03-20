import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

/// Data class representing genetic mutation information.
class GeneticMutation {
  final String name;
  final String? allele;
  final bool isVisible;

  const GeneticMutation({
    required this.name,
    this.allele,
    this.isVisible = true,
  });
}

/// Card widget displaying a bird's genetic information.
///
/// Used in bird detail screen to show known mutations and carrier status.
class GeneticInfoCard extends StatelessWidget {
  final List<GeneticMutation> mutations;
  final String? primaryColor;
  final String? secondaryColor;
  final VoidCallback? onViewDetails;

  const GeneticInfoCard({
    super.key,
    required this.mutations,
    this.primaryColor,
    this.secondaryColor,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                AppIcon(
                  AppIcons.dna,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'genetics.genetic_info'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onViewDetails != null)
                  TextButton(
                    onPressed: onViewDetails,
                    child: Text('common.view'.tr()),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Color info
            if (primaryColor != null) ...[
              _InfoRow(
                label: 'genetics.primary_color'.tr(),
                value: primaryColor!,
                icon: const AppIcon(AppIcons.colorPalette, size: 14),
              ),
              if (secondaryColor != null)
                _InfoRow(
                  label: 'genetics.secondary_color'.tr(),
                  value: secondaryColor!,
                  icon: const AppIcon(AppIcons.colorPalette, size: 14),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Mutations
            if (mutations.isEmpty)
              Text(
                'genetics.no_mutations'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: mutations.map((m) {
                  return Chip(
                    avatar: Icon(
                      m.isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 14,
                    ),
                    label: Text(
                      m.allele != null ? '${m.name} (${m.allele})' : m.name,
                      style: theme.textTheme.labelSmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: m.isVisible
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          IconTheme(
            data: IconThemeData(
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
