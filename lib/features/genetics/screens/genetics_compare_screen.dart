import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';

/// Screen for comparing multiple genetics history calculations.
class GeneticsCompareScreen extends ConsumerWidget {
  final List<String> historyIds;

  const GeneticsCompareScreen({super.key, required this.historyIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (historyIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('genetics.compare'.tr())),
        body: Center(child: Text('genetics.no_results'.tr())),
      );
    }

    final userId = ref.watch(currentUserIdProvider);
    final historyAsync = ref.watch(geneticsHistoryStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('genetics.compare_title'.tr(args: [historyIds.length.toString()])),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: '${'common.data_load_error'.tr()}: $e',
          onRetry: () => ref.invalidate(geneticsHistoryStreamProvider(userId)),
        ),
        data: (entries) {
          final selectedEntries = entries.where((e) => historyIds.contains(e.id)).toList();

          if (selectedEntries.isEmpty) {
            return Center(child: Text('genetics.no_results'.tr()));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompareTable(entries: selectedEntries),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  final List<GeneticsHistory> entries;

  const _CompareTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract all unique phenotypes across all entries
    final allPhenotypes = <String>{};
    for (final entry in entries) {
      final results = parseHistoryResults(entry.resultsJson);
      for (final r in results) {
        allPhenotypes.add(r.compoundPhenotype ?? (r.isCarrier ? r.phenotype.replaceAll(' (carrier)', '') : r.phenotype));
      }
    }

    // Sort phenotypes arbitrarily (alphabetically for now)
    final sortedPhenotypes = allPhenotypes.toList()..sort();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith(
            (states) => theme.colorScheme.surfaceContainerHigh,
          ),
          columns: [
            DataColumn(
              label: Text(
                'genetics.phenotype'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...entries.map((e) {
              return DataColumn(
                label: _EntryHeader(entry: e),
              );
            }),
          ],
          rows: sortedPhenotypes.map((phenotype) {
            final localizedPhenotype = PhenotypeLocalizer.localizePhenotype(phenotype);
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: BirdColorSimulation(
                          visualMutations: const [],
                          phenotype: phenotype,
                          size: 24.0,
                        ),
                      ),
                      Text(localizedPhenotype),
                    ],
                  ),
                ),
                ...entries.map((e) {
                  final results = parseHistoryResults(e.resultsJson);
                  final match = results.firstWhere(
                    (r) {
                      final p = r.compoundPhenotype ?? (r.isCarrier ? r.phenotype.replaceAll(' (carrier)', '') : r.phenotype);
                      return p == phenotype;
                    },
                    orElse: () => const OffspringResult(
                      phenotype: '',
                      visualMutations: [],
                      probability: 0.0,
                    ),
                  );

                  final prob = match.probability;
                  if (prob == 0.0) {
                    return DataCell(
                      Text(
                        '-',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return DataCell(
                    Text(
                      '${(prob * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EntryHeader extends StatelessWidget {
  final GeneticsHistory entry;

  const _EntryHeader({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fatherMutations = _mutationNames(entry.fatherGenotype);
    final motherMutations = _mutationNames(entry.motherGenotype);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIcons.male, size: 12, color: AppColors.genderMale),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                fatherMutations.isEmpty ? 'genetics.mutation_normal'.tr() : fatherMutations.join(', '),
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIcons.female, size: 12, color: AppColors.genderFemale),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                motherMutations.isEmpty ? 'genetics.mutation_normal'.tr() : motherMutations.join(', '),
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _mutationNames(Map<String, String> genotype) {
    return genotype.keys.map((id) {
      final record = MutationDatabase.getById(id);
      return record?.localizationKey.tr() ?? PhenotypeLocalizer.localizeMutation(id);
    }).toList();
  }
}
