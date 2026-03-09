import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

/// Footer section of the breeding card showing dates and remaining days.
class BreedingCardFooter extends StatelessWidget {
  final BreedingPair pair;
  final Incubation? incubation;

  const BreedingCardFooter({
    super.key,
    required this.pair,
    this.incubation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        if (pair.pairingDate != null) ...[
          AppIcon(AppIcons.calendar, size: 12,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(dateFormat.format(pair.pairingDate!), style: subtitleStyle),
        ],
        if (incubation?.computedExpectedHatchDate != null) ...[
          const SizedBox(width: AppSpacing.md),
          AppIcon(AppIcons.egg, size: 12,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            dateFormat.format(incubation!.computedExpectedHatchDate!),
            style: subtitleStyle,
          ),
        ],
        const Spacer(),
        if (incubation != null && incubation!.isActive) ...[
          Text(
            'breeding.days_remaining'.tr(args: [incubation!.daysRemaining.toString()]),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
