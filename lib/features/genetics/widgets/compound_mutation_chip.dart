import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';

/// Chip for compound heterozygote: two mutations at the same locus.
///
/// Shows "Mutation1 / Mutation2" with a compound badge. Deleting removes both.
class CompoundMutationChip extends StatelessWidget {
  final List<BudgieMutationRecord> records;
  final VoidCallback onRemove;

  const CompoundMutationChip({
    super.key,
    required this.records,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = records.map((r) => r.localizationKey.tr()).join(' / ');

    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'genetics.compound_short'.tr(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
      onDeleted: onRemove,
      deleteIcon: const Icon(LucideIcons.x, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
