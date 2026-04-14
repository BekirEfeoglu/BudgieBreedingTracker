import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
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
        title: Text(
          'genetics.compare_title'.tr(args: [historyIds.length.toString()]),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(geneticsHistoryStreamProvider(userId)),
        ),
        data: (entries) {
          final selectedEntries = entries
              .where((e) => historyIds.contains(e.id))
              .toList();

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
              children: [_CompareTable(entries: selectedEntries)],
            ),
          );
        },
      ),
    );
  }
}

class _CompareTable extends StatefulWidget {
  final List<GeneticsHistory> entries;

  const _CompareTable({required this.entries});

  @override
  State<_CompareTable> createState() => _CompareTableState();
}

class _CompareTableState extends State<_CompareTable> {
  late Map<String, List<OffspringResult>> _parsedResults;

  @override
  void initState() {
    super.initState();
    _parsedResults = {
      for (final e in widget.entries) e.id: parseHistoryResults(e.resultsJson),
    };
  }

  @override
  void didUpdateWidget(_CompareTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _parsedResults = {
        for (final e in widget.entries) e.id: parseHistoryResults(e.resultsJson),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract all unique phenotypes across all entries
    final allPhenotypes = <String>{};
    for (final entry in widget.entries) {
      final results = _parsedResults[entry.id]!;
      for (final r in results) {
        allPhenotypes.add(
          r.compoundPhenotype ??
              (r.isCarrier
                  ? r.phenotype.replaceAll(' (carrier)', '')
                  : r.phenotype),
        );
      }
    }

    // Sort phenotypes arbitrarily (alphabetically for now)
    final sortedPhenotypes = allPhenotypes.toList()..sort();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sticky header row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              color: theme.colorScheme.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      'genetics.phenotype'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...widget.entries.map(
                    (e) => SizedBox(
                      width: 120,
                      child: _EntryHeader(entry: e),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Phenotype rows — shrinkWrap since parent is scrollable
          ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedPhenotypes.length,
              itemBuilder: (context, index) {
                final phenotype = sortedPhenotypes[index];
                final localizedPhenotype =
                    PhenotypeLocalizer.localizePhenotype(phenotype);

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      color: index.isOdd
                          ? theme.colorScheme.surfaceContainerLow
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.sm,
                                ),
                                child: BirdColorSimulation(
                                  visualMutations: const [],
                                  phenotype: phenotype,
                                  height: 48,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  localizedPhenotype,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...widget.entries.map((e) {
                          final results = _parsedResults[e.id]!;
                          final match = results.firstWhere(
                            (r) {
                              final p = r.compoundPhenotype ??
                                  (r.isCarrier
                                      ? r.phenotype
                                          .replaceAll(' (carrier)', '')
                                      : r.phenotype);
                              return p == phenotype;
                            },
                            orElse: () => const OffspringResult(
                              phenotype: '',
                              visualMutations: [],
                              probability: 0.0,
                            ),
                          );

                          final prob = match.probability;
                          return SizedBox(
                            width: 120,
                            child: prob == 0.0
                                ? Text(
                                    '-',
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Text(
                                    '${(prob * 100).toStringAsFixed(1)}%',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
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
    final fatherMutations = PhenotypeLocalizer.localizeGenotypeKeys(
      entry.fatherGenotype,
    );
    final motherMutations = PhenotypeLocalizer.localizeGenotypeKeys(
      entry.motherGenotype,
    );

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
                fatherMutations.isEmpty
                    ? 'genetics.mutation_normal'.tr()
                    : fatherMutations.join(', '),
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
            const AppIcon(
              AppIcons.female,
              size: 12,
              color: AppColors.genderFemale,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                motherMutations.isEmpty
                    ? 'genetics.mutation_normal'.tr()
                    : motherMutations.join(', '),
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
}
