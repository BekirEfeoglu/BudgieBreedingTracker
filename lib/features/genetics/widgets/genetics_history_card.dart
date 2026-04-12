import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_colors.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_history_parent_chip.dart';

/// Card showing a saved genetics calculation summary.
class GeneticsHistoryCard extends ConsumerWidget {
  final GeneticsHistory entry;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onSelect;
  final VoidCallback onLongPress;

  const GeneticsHistoryCard({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onSelect,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final results = parseHistoryResults(entry.resultsJson);
    final fatherMutations = PhenotypeLocalizer.localizeGenotypeKeys(
      entry.fatherGenotype,
    );
    final motherMutations = PhenotypeLocalizer.localizeGenotypeKeys(
      entry.motherGenotype,
    );

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelectionMode ? onSelect : () => _showDetail(context, ref),
        onLongPress: onLongPress,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: AppSpacing.sm),
              _buildParentsSummary(
                context,
                fatherMutations: fatherMutations,
                motherMutations: motherMutations,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${results.length} ${'genetics.total_variations'.tr()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (results.isNotEmpty) _buildResultChips(context, results),
              if (entry.notes != null && entry.notes!.isNotEmpty)
                _buildNotes(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (isSelectionMode) ...[
          Checkbox(
            value: isSelected,
            onChanged: (_) => onSelect(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Icon(
          LucideIcons.clock,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _formatDate(entry.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (entry.isStale) ...[
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: 'genetics.stale_calculation'.tr(),
                  child: Icon(
                    LucideIcons.alertTriangle,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!isSelectionMode)
          IconButton(
            icon: AppIcon(
              AppIcons.delete,
              size: 16,
              color: theme.colorScheme.error,
            ),
            onPressed: () => _onDelete(context, ref),
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchTargetMin,
              minHeight: AppSpacing.touchTargetMin,
            ),
            tooltip: 'common.delete'.tr(),
          ),
      ],
    );
  }

  Widget _buildParentsSummary(
    BuildContext context, {
    required List<String> fatherMutations,
    required List<String> motherMutations,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: GeneticsHistoryParentChip(
            label: 'genetics.father_mutations'.tr(),
            mutations: fatherMutations,
            color: AppColors.genderMale.withValues(alpha: 0.1),
            icon: const AppIcon(
              AppIcons.male,
              size: 14,
              color: AppColors.genderMale,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          LucideIcons.x,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GeneticsHistoryParentChip(
            label: 'genetics.mother_mutations'.tr(),
            mutations: motherMutations,
            color: AppColors.genderFemale.withValues(alpha: 0.1),
            icon: const AppIcon(
              AppIcons.female,
              size: 14,
              color: AppColors.genderFemale,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultChips(
    BuildContext context,
    List<OffspringResult> results,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: results.take(3).map((r) {
          final rawLabel =
              r.compoundPhenotype ??
              (r.isCarrier
                  ? r.phenotype.replaceAll(' (carrier)', '')
                  : r.phenotype);
          final localizedLabel =
              PhenotypeLocalizer.localizePhenotype(rawLabel);
          return Chip(
            label: Text(
              '$localizedLabel (${(r.probability * 100).toStringAsFixed(1)}%)',
              style: theme.textTheme.labelSmall,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            backgroundColor:
                (r.visualMutations.isNotEmpty
                        ? phenotypeColorFromMutations(r.visualMutations)
                        : phenotypeColor(
                            r.compoundPhenotype ?? r.phenotype,
                          ))
                    .withValues(alpha: 0.15),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        entry.notes!,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    final father = parseStoredGenotype(entry.fatherGenotype, BirdGender.male);
    final mother = parseStoredGenotype(entry.motherGenotype, BirdGender.female);

    ref.read(fatherGenotypeProvider.notifier).state = father;
    ref.read(motherGenotypeProvider.notifier).state = mother;
    ref.read(wizardStepProvider.notifier).state = 2;

    context.pop();
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('common.confirm_delete'.tr()),
        content: Text('genetics.delete_history_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(geneticsHistorySaveProvider.notifier)
          .deleteEntry(entry.id);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

