import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

/// A compact row of colored dots summarizing egg statuses.
class EggSummaryRow extends StatelessWidget {
  final List<Egg> eggs;

  const EggSummaryRow({super.key, required this.eggs});

  @override
  Widget build(BuildContext context) {
    if (eggs.isEmpty) {
      return Text(
        'eggs.summary_no_eggs'.tr(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final hatched = eggs.where((e) => e.status == EggStatus.hatched).length;
    final fertile = eggs
        .where(
          (e) =>
              e.status == EggStatus.fertile || e.status == EggStatus.incubating,
        )
        .length;

    return Row(
      children: [
        // Egg/chick icons colored by status
        ...eggs.map(
          (egg) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: AppIcon(
              egg.status == EggStatus.hatched ? AppIcons.hatched : AppIcons.egg,
              size: 16,
              color: _getStatusColor(egg.status),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Summary text
        Text(
          '${'eggs.summary_count'.tr(namedArgs: {'count': '${eggs.length}'})}'
          '${hatched > 0 ? ' • ${'eggs.summary_hatched'.tr(namedArgs: {'count': '$hatched'})}' : ''}'
          '${fertile > 0 ? ' • ${'eggs.summary_fertile'.tr(namedArgs: {'count': '$fertile'})}' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static Color _getStatusColor(EggStatus status) {
    return switch (status) {
      EggStatus.laid => AppColors.stageNew,
      EggStatus.fertile => AppColors.success,
      EggStatus.infertile => AppColors.neutral400,
      EggStatus.incubating => AppColors.stageOngoing,
      EggStatus.hatched => AppColors.stageCompleted,
      EggStatus.damaged => AppColors.error,
      EggStatus.discarded => AppColors.neutral500,
      EggStatus.empty => AppColors.neutral300,
      EggStatus.unknown => AppColors.neutral300,
    };
  }
}
