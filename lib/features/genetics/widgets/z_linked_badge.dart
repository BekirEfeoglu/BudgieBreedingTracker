import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_catalog.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/linkage_display.dart';

/// Z-chromosome sex-linked mutation IDs with known linkage.
const _linkedSexLinkedIds = {
  'opaline',
  'cinnamon',
  'ino',
  'slate',
  'pallid',
  'texas_clearbody',
  'pearly',
};

/// Returns true when 2+ visual mutations are from linked sex-linked loci.
bool hasLinkedSexLinkedMutations(OffspringResult result) {
  final linked = result.visualMutations
      .where(_linkedSexLinkedIds.contains)
      .toList();
  return linked.length >= 2;
}

/// Returns linked sex-linked mutation IDs from an offspring result.
List<String> getLinkedIds(OffspringResult result) {
  return result.visualMutations.where(_linkedSexLinkedIds.contains).toList();
}

/// Tappable badge showing "Z-linked" with popup linkage details.
class ZLinkedBadge extends StatelessWidget {
  final List<String> linkedIds;

  const ZLinkedBadge({super.key, required this.linkedIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'genetics.z_linkage'.tr(),
      child: GestureDetector(
        onTap: () => _showLinkagePopup(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.link,
                  size: 10,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    'genetics.z_linked'.tr(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLinkagePopup(BuildContext context) {
    final theme = Theme.of(context);
    final pairs = <String>[];

    for (var i = 0; i < linkedIds.length; i++) {
      for (var j = i + 1; j < linkedIds.length; j++) {
        final a = linkedIds[i];
        final b = linkedIds[j];
        final info = LinkageCatalog.lookup(a, b);
        if (info != null) {
          pairs.add(
            '${linkageMutationName(a)} ↔ ${linkageMutationName(b)}: '
            '~${info.displayCentiMorgansLabel} cM'
            '${linkageEvidenceSuffix(info.evidence)}',
          );
        }
      }
    }

    if (pairs.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'genetics.z_linkage'.tr(),
          style: theme.textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'genetics.z_gene_order'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...pairs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(p, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }
}
