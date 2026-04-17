import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';

import 'egg_status_chip.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';

/// Shows a bottom sheet for updating an egg's status.
///
/// Returns the selected [EggStatus] or null if dismissed.
Future<EggStatus?> showEggStatusUpdateSheet(BuildContext context, Egg egg) {
  final transitions = IncubationCalculator.getValidStatusTransitions(
    egg.status,
  );

  if (transitions.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('eggs.transition_not_allowed'.tr())));
    return Future.value(null);
  }

  return showAppBottomSheet<EggStatus>(
    context: context,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${'eggs.egg_label'.tr()} #${egg.eggNumber ?? '?'} - ${'eggs.update_status'.tr()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('${'eggs.current_status'.tr()}: '),
                  EggStatusChip(status: egg.status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('eggs.select_new_status'.tr()),
              const SizedBox(height: AppSpacing.sm),
              ...transitions.map(
                (status) => ListTile(
                  leading: EggStatusChip(status: status),
                  title: Text(_getStatusDescription(status)),
                  onTap: () => Navigator.of(context).pop(status),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      );
    },
  );
}

String _getStatusDescription(EggStatus status) {
  return switch (status) {
    EggStatus.fertile => 'eggs.mark_fertile'.tr(),
    EggStatus.infertile => 'eggs.mark_infertile'.tr(),
    EggStatus.incubating => 'eggs.start_incubation'.tr(),
    EggStatus.hatched => 'eggs.mark_hatched'.tr(),
    EggStatus.damaged => 'eggs.mark_damaged'.tr(),
    EggStatus.discarded => 'eggs.mark_discarded'.tr(),
    _ => '',
  };
}
