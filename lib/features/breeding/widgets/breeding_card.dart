import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/shared/widgets/eggs.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

import 'breeding_card_header.dart';
import 'breeding_card_progress.dart';
import 'breeding_card_footer.dart';

/// Composite breeding card with stage-colored left border.
class BreedingCard extends StatelessWidget {
  final BreedingPair pair;
  final Incubation? incubation;
  final List<Egg> eggs;
  final Map<String, Bird>? birdsMap;
  final VoidCallback? onTap;

  const BreedingCard({
    super.key,
    required this.pair,
    this.incubation,
    this.eggs = const [],
    this.birdsMap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysElapsed = incubation?.daysElapsed ?? 0;
    final totalDays = incubation?.totalIncubationDays();
    final isComplete = incubation?.isComplete ?? false;
    final stageColor = isComplete
        ? IncubationCalculator.getCompletedStageColor()
        : IncubationCalculator.getStageColor(daysElapsed, totalDays: totalDays);
    final handleTap =
        onTap ??
        () =>
            context.push(AppRoutes.breedingDetail.replaceFirst(':id', pair.id));
    final maleName = pair.maleId == null ? null : birdsMap?[pair.maleId]?.name;
    final femaleName = pair.femaleId == null
        ? null
        : birdsMap?[pair.femaleId]?.name;
    final semanticLabel = [
      if (maleName != null) maleName,
      if (femaleName != null) femaleName,
      if (maleName == null && femaleName == null) 'nav.breeding'.tr(),
      if (pair.cageNumber case final cage? when cage.isNotEmpty)
        '${'breeding.cage_label'.tr()}: $cage',
    ].join(', ');

    return Semantics(
      label: semanticLabel,
      button: true,
      onTap: handleTap,
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: handleTap,
          excludeFromSemantics: true,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: stageColor, width: 4)),
            ),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BreedingCardHeader(pair: pair, birdsMap: birdsMap),
                  if (incubation != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    BreedingCardProgress(incubation: incubation!),
                  ],
                  if (eggs.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    EggSummaryRow(eggs: eggs),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  BreedingCardFooter(pair: pair, incubation: incubation),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
