import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';

import 'breeding_card_header.dart';
import 'breeding_card_progress.dart';
import 'breeding_card_eggs.dart';
import 'breeding_card_footer.dart';

/// Composite breeding card with stage-colored left border.
class BreedingCard extends ConsumerWidget {
  final BreedingPair pair;
  final Incubation? incubation;
  final List<Egg> eggs;
  final VoidCallback? onTap;

  const BreedingCard({
    super.key,
    required this.pair,
    this.incubation,
    this.eggs = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysElapsed = incubation?.daysElapsed ?? 0;
    final isComplete = incubation?.isComplete ?? false;
    final stageColor = isComplete
        ? IncubationCalculator.getCompletedStageColor()
        : IncubationCalculator.getStageColor(daysElapsed);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/breeding/${pair.id}'),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stageColor, width: 4)),
          ),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BreedingCardHeader(pair: pair),
                if (incubation != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  BreedingCardProgress(incubation: incubation!),
                ],
                if (eggs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  BreedingCardEggs(eggs: eggs),
                ],
                const SizedBox(height: AppSpacing.md),
                BreedingCardFooter(pair: pair, incubation: incubation),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
