import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction_details.dart';

/// Card showing a predicted offspring phenotype with probability,
/// sex indicator, carrier status, compound phenotype name,
/// and optional genotype. Tap to expand full details.
class OffspringPrediction extends StatefulWidget {
  final OffspringResult result;
  final bool showGenotype;

  /// When true, hides the circular progress indicator (used in grouped view).
  final bool hideProgress;

  const OffspringPrediction({
    super.key,
    required this.result,
    this.showGenotype = false,
    this.hideProgress = false,
  });

  @override
  State<OffspringPrediction> createState() => _OffspringPredictionState();
}

class _OffspringPredictionState extends State<OffspringPrediction>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _copyGenotype(BuildContext context, String genotype) {
    Clipboard.setData(ClipboardData(text: genotype));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('genetics.genotype_copied'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _hasExpandableContent =>
      widget.result.carriedMutations.length > 2 ||
      widget.result.maskedMutations.isNotEmpty ||
      (widget.showGenotype && widget.result.genotype != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;
    final percentage = (result.probability * 100).toStringAsFixed(1);
    final rawDisplayName =
        result.compoundPhenotype ??
        (result.isCarrier
            ? result.phenotype.replaceAll(' (carrier)', '')
            : result.phenotype);
    final displayName = PhenotypeLocalizer.localizePhenotype(rawDisplayName);
    final localizedCarriedMutations = PhenotypeLocalizer.localizeMutationList(
      result.carriedMutations,
    );
    final localizedMaskedMutations = PhenotypeLocalizer.localizeMutationList(
      result.maskedMutations,
    );
    final sexLabel = switch (result.sex) {
      OffspringSex.male => 'genetics.male_offspring'.tr(),
      OffspringSex.female => 'genetics.female_offspring'.tr(),
      OffspringSex.both => '',
    };
    final semanticLabel = [
      displayName,
      '%$percentage',
      if (sexLabel.isNotEmpty) sexLabel,
      if (result.isCarrier) 'genetics.carrier'.tr(),
    ].join(', ');

    return Semantics(
      label: semanticLabel,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: _expanded
            ? theme.colorScheme.surfaceContainerHigh
            : null,
        child: InkWell(
          onTap: _hasExpandableContent
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _expanded ? 3 : 0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusMd),
                      bottomLeft: Radius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      children: [
                        _buildCollapsedRow(theme, result, displayName,
                            percentage, localizedCarriedMutations),
                        if (_expanded) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.sm),
                          ExpandedDetails(
                            result: result,
                            localizedCarriedMutations:
                                localizedCarriedMutations,
                            localizedMaskedMutations:
                                localizedMaskedMutations,
                            showGenotype: widget.showGenotype,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedRow(
    ThemeData theme,
    OffspringResult result,
    String displayName,
    String percentage,
    List<String> localizedCarriedMutations,
  ) {
    return Row(
      children: [
        BirdColorSimulation(
          visualMutations: result.visualMutations,
          carriedMutations: result.carriedMutations,
          phenotype: result.compoundPhenotype ?? result.phenotype,
          height: _expanded ? 96 : (widget.showGenotype ? 80 : 64),
          isFemale: switch (result.sex) {
            OffspringSex.female => true,
            OffspringSex.male => false,
            OffspringSex.both => null,
          },
        ),
        const SizedBox(width: AppSpacing.md),
        SexIcon(sex: result.sex),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhenotypeBadges(displayName: displayName, result: result),
              if (result.carriedMutations.isNotEmpty && !_expanded) ...[
                const SizedBox(height: 1),
                Text(
                  localizedCarriedMutations.join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warningTextAdaptive(context),
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
              if (result.maskedMutations.isNotEmpty && !_expanded) ...[
                const SizedBox(height: 1),
                Text(
                  'genetics.masked_mutations'.tr(
                    args: [
                      PhenotypeLocalizer.localizeMutationList(
                        result.maskedMutations,
                      ).join(', '),
                    ],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
              if (!_expanded &&
                  widget.showGenotype &&
                  result.genotype != null) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onLongPress: () => _copyGenotype(context, result.genotype!),
                  child: Text(
                    result.genotype!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!widget.hideProgress) ...[
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: result.probability < 0.05 && result.probability > 0
                      ? 0.05
                      : result.probability,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                  strokeWidth: 5,
                ),
                Text(
                  '%$percentage',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_hasExpandableContent) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}

