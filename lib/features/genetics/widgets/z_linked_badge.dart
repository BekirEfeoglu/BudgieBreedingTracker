import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

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

/// Linkage rates between Z-chromosome loci (centiMorgans).
const _linkageRates = <String, Map<String, int>>{
  'opaline': {'cinnamon': 34, 'ino': 30, 'slate': 40},
  'cinnamon': {'ino': 3, 'slate': 5, 'opaline': 34},
  'ino': {'slate': 2, 'cinnamon': 3, 'opaline': 30},
  'slate': {'ino': 2, 'cinnamon': 5, 'opaline': 40},
  'pallid': {'slate': 2, 'cinnamon': 3, 'opaline': 30},
  'texas_clearbody': {'slate': 2, 'cinnamon': 3, 'opaline': 30},
  'pearly': {'slate': 2, 'cinnamon': 3, 'opaline': 30},
};

String _linkageMutName(String id) {
  final record = MutationDatabase.getById(id);
  if (record == null) return id;
  return PhenotypeLocalizer.localizePhenotype(record.name);
}

/// Tappable badge showing "Z-linked" with popup linkage details.
class ZLinkedBadge extends StatelessWidget {
  final List<String> linkedIds;

  const ZLinkedBadge({super.key, required this.linkedIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showLinkagePopup(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.link, size: 8, color: theme.colorScheme.tertiary),
            const SizedBox(width: 2),
            Text(
              'genetics.z_linked'.tr(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
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
        final cM = _linkageRates[a]?[b] ?? _linkageRates[b]?[a];
        if (cM != null) {
          pairs.add('${_linkageMutName(a)} ↔ ${_linkageMutName(b)}: ~$cM cM');
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
