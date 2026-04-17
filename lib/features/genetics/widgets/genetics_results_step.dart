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
import 'package:budgie_breeding_tracker/features/genetics/widgets/lethal_warning.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/dihybrid_punnett_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/results_summary_banner.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/sex_specific_results.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

part 'genetics_results_step_helpers.dart';
part 'genetics_results_step_slivers.dart';

/// Step 2: Results with offspring predictions, charts, and Punnett square.
class GeneticsResultsStep extends ConsumerWidget {
  const GeneticsResultsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handle async loading/error state from isolate-backed calculation
    final rawResultsAsync = ref.watch(offspringResultsProvider);
    if (rawResultsAsync.isLoading) {
      return const LoadingState();
    }
    if (rawResultsAsync.hasError) {
      return Center(
        child: Text('errors.unknown_error'.tr()),
      );
    }
    final rawResults = rawResultsAsync.value;
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
      final hasParentSelections = rawResults != null;
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasParentSelections
                    ? 'genetics.no_results_hint_filtered'.tr()
                    : 'genetics.no_results_hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
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
          totalResultCount: results.length,
          filteredResultCount: filteredResults.length,
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
          child: CustomScrollView(
            slivers: [
              // Summary banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: ResultsSummaryBanner(results: results),
                  ),
                ),
              ),
              // Lethal warning
              if (lethalAnalysis != null &&
                  lethalAnalysis.hasWarnings)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: LethalWarning(analysis: lethalAnalysis),
                    ),
                  ),
                ),
              // Epistasis interactions
              if (epistasisInteractions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: EpistasisInteractionsCard(
                        interactions: epistasisInteractions,
                      ),
                    ),
                  ),
                ),
              // Results list — sex-specific uses box adapter (has "show more"),
              // grouped list uses SliverList for true lazy rendering
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.sm),
              ),
              if (showSexSpecific)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: SexSpecificResults(
                      results: filteredResults,
                      showGenotype: showGenotype,
                    ),
                  ),
                )
              else
                ..._buildGroupedSlivers(filteredResults, showGenotype),
              // Chart
              if (chartData.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Padding(
                      padding: AppSpacing.screenPadding,
                      child: OffspringProbabilityBarChart(
                        data: _localizeChartData(chartData, context),
                        title: 'genetics.probability_chart'.tr(),
                      ),
                    ),
                  ),
                ),
              // Punnett square
              if (punnett != null) ...[
                if (availableLoci.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Padding(
                        padding: AppSpacing.screenPadding,
                        child: PunnettLocusSelector(
                          availableLoci: availableLoci,
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: PunnettSquareWidget(data: punnett),
                  ),
                ),
                if (availableLoci.length >= 2)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: DihybridPunnettSection(
                        availableLoci: availableLoci,
                      ),
                    ),
                  ),
              ],
              // Bottom padding for FAB clearance
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl * 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

