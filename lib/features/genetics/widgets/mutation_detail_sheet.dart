import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inheritance_badge.dart';

/// Shows a bottom sheet with detailed mutation information.
Future<void> showMutationDetailSheet(
  BuildContext context, {
  required BudgieMutationRecord mutation,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (_) => _MutationDetailContent(mutation: mutation),
  );
}

class _MutationDetailContent extends StatelessWidget {
  final BudgieMutationRecord mutation;

  const _MutationDetailContent({required this.mutation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title + badge
          Row(
            children: [
              Expanded(
                child: Text(
                  mutation.localizationKey.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InheritanceBadge(type: mutation.inheritanceType),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Category
          Text(
            _categoryKey(mutation.category).tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Inheritance type
          _DetailRow(
            label: 'genetics.inheritance_type'.tr(),
            value: mutation.inheritanceType.labelKey.tr(),
          ),

          // Alleles
          _DetailRow(
            label: 'genetics.alleles'.tr(),
            value: mutation.alleles.join(' / '),
          ),

          // Allele symbol
          _DetailRow(
            label: 'genetics.allele_symbol'.tr(),
            value: mutation.alleleSymbol,
          ),

          // Visual effect
          if (mutation.visualEffect != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'genetics.visual_effect'.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                mutation.visualEffect!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],

          // Z-chromosome linkage info (sex-linked mutations only)
          if (mutation.isSexLinked) ...[
            const SizedBox(height: AppSpacing.lg),
            _ZLinkageSection(mutationId: mutation.id),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _categoryKey(String category) {
    final key = category
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    return 'genetics.category_$key';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows Z-chromosome linkage info for sex-linked mutations.
class _ZLinkageSection extends StatelessWidget {
  final String mutationId;

  const _ZLinkageSection({required this.mutationId});

  @override
  Widget build(BuildContext context) {
    final linkages = _linkageMap[mutationId];
    if (linkages == null || linkages.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'genetics.z_linkage'.tr(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'genetics.z_gene_order'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...linkages.map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Text(
                        l.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'genetics.z_linkage_rate'.tr(
                          args: [l.centiMorgans.toString()],
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Z-chromosome linkage rates for sex-linked mutations.
/// Gene order: Opaline — Cinnamon — Ino — Slate.
typedef _LinkageEntry = ({String label, int centiMorgans});

const _linkageMap = <String, List<_LinkageEntry>>{
  'opaline': [
    (label: 'Ino', centiMorgans: 30),
    (label: 'Cinnamon', centiMorgans: 34),
    (label: 'Slate', centiMorgans: 40),
  ],
  'cinnamon': [
    (label: 'Ino', centiMorgans: 3),
    (label: 'Slate', centiMorgans: 5),
    (label: 'Opaline', centiMorgans: 34),
  ],
  'ino': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
  'slate': [
    (label: 'Ino', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 5),
    (label: 'Opaline', centiMorgans: 40),
  ],
  // Pearly, Pallid & Texas Clearbody share the ino locus position.
  'pearly': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
  'pallid': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
  'texas_clearbody': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
};
