import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';

/// Card displaying a health record summary in the list.
class HealthRecordCard extends ConsumerWidget {
  final HealthRecord record;
  final String? animalName;
  final VoidCallback? onTap;

  const HealthRecordCard({
    super.key,
    required this.record,
    this.animalName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/health-records/${record.id}'),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: healthRecordTypeColor(
                  record.type,
                ).withValues(alpha: 0.15),
                child: Icon(
                  healthRecordTypeIcon(record.type),
                  size: 22,
                  color: healthRecordTypeColor(record.type),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            healthRecordTypeLabel(record.type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: healthRecordTypeColor(record.type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            ref
                                .watch(dateFormatProvider)
                                .formatter()
                                .format(record.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (animalName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AppIcon(
                            AppIcons.bird,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              animalName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (record.description != null &&
                        record.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (record.followUpDate != null)
                Tooltip(
                  message: 'health_records.follow_up'.tr(),
                  child: Icon(
                    LucideIcons.calendarDays,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns the icon for a health record type.
IconData healthRecordTypeIcon(HealthRecordType type) => switch (type) {
  HealthRecordType.checkup => LucideIcons.stethoscope,
  HealthRecordType.illness => LucideIcons.thermometer,
  HealthRecordType.injury => LucideIcons.heartPulse,
  HealthRecordType.vaccination => LucideIcons.syringe,
  HealthRecordType.medication => LucideIcons.pill,
  HealthRecordType.death => LucideIcons.heartOff,
  HealthRecordType.unknown => LucideIcons.helpCircle,
};

/// Returns the color for a health record type.
Color healthRecordTypeColor(HealthRecordType type) => switch (type) {
  HealthRecordType.checkup => AppColors.info,
  HealthRecordType.illness => AppColors.warning,
  HealthRecordType.injury => AppColors.error,
  HealthRecordType.vaccination => AppColors.success,
  HealthRecordType.medication => AppColors.medication,
  HealthRecordType.death => AppColors.neutral400,
  HealthRecordType.unknown => AppColors.neutral400,
};

/// Returns the localized label for a health record type.
String healthRecordTypeLabel(HealthRecordType type) => switch (type) {
  HealthRecordType.checkup => 'health_records.type_checkup'.tr(),
  HealthRecordType.illness => 'health_records.type_illness'.tr(),
  HealthRecordType.injury => 'health_records.type_injury'.tr(),
  HealthRecordType.vaccination => 'health_records.type_vaccination'.tr(),
  HealthRecordType.medication => 'health_records.type_medication'.tr(),
  HealthRecordType.death => 'health_records.type_death'.tr(),
  HealthRecordType.unknown => 'health_records.type_unknown'.tr(),
};
