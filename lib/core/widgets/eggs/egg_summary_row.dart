import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

import 'egg_status_utils.dart';

/// A compact row of colored dots summarizing egg statuses.
class EggSummaryRow extends StatelessWidget {
  final List<EggStatus> statuses;

  const EggSummaryRow({super.key, required this.statuses});

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return Text(
        'eggs.summary_no_eggs'.tr(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final hatched = statuses
        .where((status) => status == EggStatus.hatched)
        .length;
    final fertile = statuses
        .where(
          (status) =>
              status == EggStatus.fertile || status == EggStatus.incubating,
        )
        .length;

    return Row(
      children: [
        // Egg/chick icons colored by status
        ...statuses.map(
          (status) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: AppIcon(
              status == EggStatus.hatched ? AppIcons.hatched : AppIcons.egg,
              size: 16,
              color: getEggStatusColor(status),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Summary text
        Text(
          '${'eggs.summary_count'.tr(namedArgs: {'count': '${statuses.length}'})}'
          '${hatched > 0 ? ' • ${'eggs.summary_hatched'.tr(namedArgs: {'count': '$hatched'})}' : ''}'
          '${fertile > 0 ? ' • ${'eggs.summary_fertile'.tr(namedArgs: {'count': '$fertile'})}' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
