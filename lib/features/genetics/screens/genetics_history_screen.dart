import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Screen showing saved genetics calculation history.
class GeneticsHistoryScreen extends ConsumerStatefulWidget {
  const GeneticsHistoryScreen({super.key});

  @override
  ConsumerState<GeneticsHistoryScreen> createState() =>
      _GeneticsHistoryScreenState();
}

class _GeneticsHistoryScreenState extends ConsumerState<GeneticsHistoryScreen> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final historyAsync = ref.watch(geneticsHistoryStreamProvider(userId));
    final theme = Theme.of(context);
    final isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelectionMode
              ? '${_selectedIds.length} ${'common.selected'.tr()}'
              : 'genetics.history'.tr(),
        ),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: _clearSelection,
              )
            : null,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: '${'common.data_load_error'.tr()}: $e',
          onRetry: () => ref.invalidate(geneticsHistoryStreamProvider(userId)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    AppIcons.calculator,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'genetics.no_history'.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(geneticsHistoryStreamProvider(userId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _HistoryCard(
                  key: ValueKey(entry.id),
                  entry: entry,
                  isSelected: _selectedIds.contains(entry.id),
                  isSelectionMode: isSelectionMode,
                  onSelect: () => _toggleSelection(entry.id),
                  onLongPress: () {
                    if (!isSelectionMode) {
                      _toggleSelection(entry.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _selectedIds.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(
                  AppRoutes.geneticsCompare,
                  extra: _selectedIds.toList(),
                );
                _clearSelection();
              },
              icon: const Icon(LucideIcons.gitCompare),
              label: Text('genetics.compare_selected'.tr()),
            )
          : null,
    );
  }
}

/// Card showing a saved genetics calculation summary.
class _HistoryCard extends ConsumerWidget {
  final GeneticsHistory entry;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onSelect;
  final VoidCallback onLongPress;

  const _HistoryCard({
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
    final fatherMutations = _mutationNames(entry.fatherGenotype);
    final motherMutations = _mutationNames(entry.motherGenotype);

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
              // Header: date + delete button + selection checkbox
              Row(
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
                    child: Text(
                      _formatDate(entry.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
              ),
              const SizedBox(height: AppSpacing.sm),

              // Parents summary
              Row(
                children: [
                  Expanded(
                    child: _ParentChip(
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
                    child: _ParentChip(
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
              ),
              const SizedBox(height: AppSpacing.sm),

              // Results summary
              Text(
                '${results.length} ${'genetics.total_variations'.tr()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              // Top 3 results
              if (results.isNotEmpty)
                Padding(
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
                        backgroundColor: phenotypeColor(
                          r.compoundPhenotype ?? r.phenotype,
                        ).withValues(alpha: 0.15),
                      );
                    }).toList(),
                  ),
                ),

              // Notes
              if (entry.notes != null && entry.notes!.isNotEmpty)
                Padding(
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    // Load the genotypes into the calculator and navigate to results
    final father = parseStoredGenotype(entry.fatherGenotype, BirdGender.male);
    final mother = parseStoredGenotype(entry.motherGenotype, BirdGender.female);

    ref.read(fatherGenotypeProvider.notifier).state = father;
    ref.read(motherGenotypeProvider.notifier).state = mother;
    ref.read(wizardStepProvider.notifier).state = 2; // Go to results step

    context.pop(); // Go back to calculator (now showing saved results)
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
      ref.read(geneticsHistorySaveProvider.notifier).deleteEntry(entry.id);
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

  List<String> _mutationNames(Map<String, String> genotype) {
    return genotype.keys.map((id) {
      final record = MutationDatabase.getById(id);
      return record?.localizationKey.tr() ??
          PhenotypeLocalizer.localizeMutation(id);
    }).toList();
  }
}

/// Compact chip showing parent mutations.
class _ParentChip extends StatelessWidget {
  final String label;
  final List<String> mutations;
  final Color color;
  final Widget icon;

  const _ParentChip({
    required this.label,
    required this.mutations,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  mutations.isEmpty
                      ? 'genetics.mutation_normal'.tr()
                      : mutations.join(', '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
