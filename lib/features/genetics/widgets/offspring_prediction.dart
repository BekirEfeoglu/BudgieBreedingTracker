import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction_details.dart';

part 'offspring_prediction_helpers.dart';

// ── Layout constants ──
const double _kBirdHeightExpanded = 80;
const double _kBirdHeightGenotype = 56;
const double _kBirdHeightDefault = 48;
const double _kProgressSize = AppSpacing.touchTargetMin;
const int _kMaxVisibleMutations = 3;
const double _kLowProbabilityThreshold = 0.01;

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

  bool get _hasExpandableContent =>
      widget.result.carriedMutations.length > 2 ||
      widget.result.maskedMutations.isNotEmpty ||
      widget.result.genotype != null;

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

    final borderColor = result.isCarrier
        ? AppColors.warning
        : theme.colorScheme.primary;

    final isDark = theme.brightness == Brightness.dark;
    final cardColor = _expanded
        ? theme.colorScheme.surfaceContainerHigh
        : result.isCarrier
            ? AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.05)
            : null;

    return RepaintBoundary(
      child: Semantics(
        label: semanticLabel,
        expanded: _hasExpandableContent ? _expanded : null,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: cardColor,
          child: InkWell(
            onTap: _hasExpandableContent
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() => _expanded = !_expanded);
                    // ignore: deprecated_member_use
                    SemanticsService.announce(
                      _expanded
                          ? 'genetics.details_expanded'.tr()
                          : 'genetics.details_collapsed'.tr(),
                      ui.TextDirection.ltr,
                    );
                  }
                : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _expanded ? AppSpacing.xs : 3,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? borderColor
                        : borderColor.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusMd),
                      bottomLeft: Radius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
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
          height: _expanded
              ? _kBirdHeightExpanded
              : (widget.showGenotype
                  ? _kBirdHeightGenotype
                  : _kBirdHeightDefault),
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
                _CarrierMutationsSummary(
                  mutations: localizedCarriedMutations,
                  theme: theme,
                ),
              ],
              if (!_expanded &&
                  widget.showGenotype &&
                  result.genotype != null) ...[
                const SizedBox(height: 2),
                Text(
                  result.genotype!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
        if (!widget.hideProgress) ...[
          const SizedBox(width: AppSpacing.sm),
          _ProbabilityIndicator(
            probability: result.probability,
            percentage: percentage,
            theme: theme,
          ),
        ],
        if (_hasExpandableContent) ...[
          const SizedBox(width: AppSpacing.xs),
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              LucideIcons.chevronDown,
              size: 24,
              color: _expanded
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

