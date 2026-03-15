import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

/// Banner showing summary statistics for offspring results:
/// - Total phenotype variations
/// - Highest probability phenotype
/// - Carrier offspring ratio
class ResultsSummaryBanner extends StatelessWidget {
  final List<OffspringResult> results;

  const ResultsSummaryBanner({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final totalVariations = results.length;
    final topResult = results.first; // Already sorted by probability
    final rawTopLabel =
        topResult.compoundPhenotype ??
        (topResult.isCarrier
            ? topResult.phenotype.replaceAll(' (carrier)', '')
            : topResult.phenotype);
    final localizedTopLabel = PhenotypeLocalizer.localizePhenotype(rawTopLabel);
    final carrierCount = results.where((r) => r.isCarrier).length;
    final carrierProb = results
        .where((r) => r.isCarrier)
        .fold(0.0, (sum, r) => sum + r.probability);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.primaryContainer),
      ),
      child: Row(
        children: [
          // Total variations
          Expanded(
            child: _StatColumn(
              value: '$totalVariations',
              label: 'genetics.total_variations'.tr(),
              theme: theme,
            ),
          ),
          _VerticalDivider(theme: theme),
          // Top phenotype
          Expanded(
            flex: 2,
            child: _StatColumn(
              value: '${(topResult.probability * 100).toStringAsFixed(0)}%',
              label: localizedTopLabel,
              theme: theme,
            ),
          ),
          if (carrierCount > 0) ...[
            _VerticalDivider(theme: theme),
            // Carrier ratio
            Expanded(
              child: _StatColumn(
                value: '${(carrierProb * 100).toStringAsFixed(0)}%',
                label: 'genetics.carrier_ratio'.tr(),
                theme: theme,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final ThemeData theme;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final ThemeData theme;

  const _VerticalDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: theme.colorScheme.outlineVariant,
    );
  }
}
