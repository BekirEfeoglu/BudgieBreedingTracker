import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetic_charts.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/epistasis_interactions_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/grouped_results_list.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/lethal_warning.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/dihybrid_punnett_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/results_summary_banner.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/sex_specific_results.dart';

part 'genetics_results_step_helpers.dart';

/// Step 2: Results with offspring predictions, charts, and Punnett square.
class GeneticsResultsStep extends ConsumerWidget {
  const GeneticsResultsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawResults = ref.watch(offspringResultsProvider);
    final results = ref.watch(enrichedOffspringResultsProvider);
    final punnett = ref.watch(punnettSquareProvider);
    final chartData = ref.watch(offspringChartDataProvider);
    final showSexSpecific = ref.watch(showSexSpecificProvider);
    final showGenotype = ref.watch(showGenotypeProvider);
    final availableLoci = ref.watch(availablePunnettLociProvider);
    final lethalAnalysis = ref.watch(lethalAnalysisProvider);
    final epistasisInteractions = ref.watch(epistasisInteractionsProvider);
    final activeFilter = ref.watch(offspringFilterProvider);

    if (rawResults == null || rawResults.isEmpty || results == null) {
      return Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                AppIcons.dna,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'genetics.no_results'.tr(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final filteredResults = _applyFilter(results, activeFilter);

    return Column(
      children: [
        _ResultsHeader(
          showSexSpecific: showSexSpecific,
          showGenotype: showGenotype,
          activeFilter: activeFilter,
          onToggleSex: (value) {
            ref.read(showSexSpecificProvider.notifier).state = value;
          },
          onToggleGenotype: (value) {
            ref.read(showGenotypeProvider.notifier).state = value;
          },
          onFilterChanged: (filter) {
            ref.read(offspringFilterProvider.notifier).state = filter;
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: ResultsSummaryBanner(results: results),
                ),
                if (lethalAnalysis != null &&
                    lethalAnalysis.hasWarnings) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: AppSpacing.screenPadding,
                    child: LethalWarning(analysis: lethalAnalysis),
                  ),
                ],
                if (epistasisInteractions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: AppSpacing.screenPadding,
                    child: EpistasisInteractionsCard(
                      interactions: epistasisInteractions,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: showSexSpecific
                      ? SexSpecificResults(
                          results: filteredResults,
                          showGenotype: showGenotype,
                        )
                      : GroupedResultsList(
                          results: filteredResults,
                          showGenotype: showGenotype,
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (chartData.isNotEmpty)
                  Padding(
                    padding: AppSpacing.screenPadding,
                    child: OffspringProbabilityBarChart(
                      data: _localizeChartData(chartData, context),
                      title: 'genetics.probability_chart'.tr(),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (punnett != null) ...[
                  if (availableLoci.length > 1)
                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: PunnettLocusSelector(
                        availableLoci: availableLoci,
                      ),
                    ),
                  Padding(
                    padding: AppSpacing.screenPadding,
                    child: PunnettSquareWidget(data: punnett),
                  ),
                  if (availableLoci.length >= 2) ...[
                    const SizedBox(height: AppSpacing.lg),
                    DihybridPunnettSection(
                      availableLoci: availableLoci,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

