import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetic_charts.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/epistasis_interactions_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/lethal_warning.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/dihybrid_punnett_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/results_summary_banner.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/sex_specific_results.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner
          Padding(
            padding: AppSpacing.screenPadding,
            child: ResultsSummaryBanner(results: results),
          ),

          // Lethal combination warning
          if (lethalAnalysis != null && lethalAnalysis.hasWarnings) ...[
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
          const SizedBox(height: AppSpacing.md),

          // Results header with toggles
          _ResultsHeader(
            showSexSpecific: showSexSpecific,
            showGenotype: showGenotype,
            onToggleSex: (value) {
              ref.read(showSexSpecificProvider.notifier).state = value;
            },
            onToggleGenotype: (value) {
              ref.read(showGenotypeProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Offspring results
          Padding(
            padding: AppSpacing.screenPadding,
            child: showSexSpecific
                ? SexSpecificResults(
                    results: results,
                    showGenotype: showGenotype,
                  )
                : Column(
                    children: results
                        .map(
                          (result) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: OffspringPrediction(
                              result: result,
                              showGenotype: showGenotype,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Bar chart
          if (chartData.isNotEmpty)
            Padding(
              padding: AppSpacing.screenPadding,
              child: OffspringProbabilityBarChart(
                data: _localizeChartData(chartData, context),
                title: 'genetics.probability_chart'.tr(),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Punnett square with locus selector
          if (punnett != null) ...[
            if (availableLoci.length > 1)
              Padding(
                padding: AppSpacing.screenPadding,
                child: PunnettLocusSelector(availableLoci: availableLoci),
              ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: PunnettSquareWidget(data: punnett),
            ),

            // Dihybrid (4×4) Punnett square when 2+ loci available
            if (availableLoci.length >= 2) ...[
              const SizedBox(height: AppSpacing.lg),
              DihybridPunnettSection(availableLoci: availableLoci),
            ],
          ],
        ],
      ),
    );
  }
}

/// Results header with sex-specific and genotype toggles.
class _ResultsHeader extends StatelessWidget {
  final bool showSexSpecific;
  final bool showGenotype;
  final ValueChanged<bool> onToggleSex;
  final ValueChanged<bool> onToggleGenotype;

  const _ResultsHeader({
    required this.showSexSpecific,
    required this.showGenotype,
    required this.onToggleSex,
    required this.onToggleGenotype,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              AppIcon(AppIcons.dna, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'genetics.results_title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _ToggleRow(
                  label: 'genetics.show_sex_specific'.tr(),
                  value: showSexSpecific,
                  onChanged: onToggleSex,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ToggleRow(
                  label: 'genetics.show_genotype'.tr(),
                  value: showGenotype,
                  onChanged: onToggleGenotype,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

/// Replaces the English "carrier" word in chart labels with the localized term.
List<GeneticChartItem> _localizeChartData(
  List<GeneticChartItem> data,
  BuildContext context,
) {
  final carrierLabel = 'genetics.carrier'.tr().toLowerCase();
  return data.map((item) {
    final localizedLabel = item.label.replaceAll(
      ' carrier)',
      ' $carrierLabel)',
    );
    return GeneticChartItem(
      label: localizedLabel,
      value: item.value,
      color: item.color,
    );
  }).toList();
}
