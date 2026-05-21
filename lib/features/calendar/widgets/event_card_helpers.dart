part of 'event_card.dart';

/// Returns a widget icon for an [EventType].
///
/// Domain events (breeding, egg, hatching, chick) use SVG AppIcons so they
/// stay visually consistent with the rest of the app. Generic activity events
/// (feeding, cleaning, medication, weightCheck) remain on LucideIcons as
/// allowed by anti-pattern #24.
Widget eventTypeIconWidget(EventType type, {double size = 20, Color? color}) {
  switch (type) {
    case EventType.breeding:
    case EventType.mating:
      return AppIcon(AppIcons.pair, size: size, color: color);
    case EventType.egg:
    case EventType.eggLaying:
      return AppIcon(AppIcons.egg, size: size, color: color);
    case EventType.hatching:
      return AppIcon(AppIcons.hatched, size: size, color: color);
    case EventType.chick:
      return AppIcon(AppIcons.chick, size: size, color: color);
    case EventType.banding:
      return AppIcon(AppIcons.ring, size: size, color: color);
    case EventType.healthCheck:
    case EventType.health:
      return AppIcon(AppIcons.health, size: size, color: color);
    case EventType.weightCheck:
      return AppIcon(AppIcons.weight, size: size, color: color);
    case EventType.vaccination:
      return Icon(LucideIcons.syringe, size: size, color: color);
    case EventType.medication:
      return Icon(LucideIcons.pill, size: size, color: color);
    case EventType.feeding:
      return Icon(LucideIcons.wheat, size: size, color: color);
    case EventType.cleaning:
    case EventType.cageChange:
      return Icon(LucideIcons.sparkles, size: size, color: color);
    case EventType.custom:
    case EventType.other:
    case EventType.unknown:
      return AppIcon(AppIcons.calendar, size: size, color: color);
  }
}

/// Returns a display label for an [EventType].
String eventTypeLabel(EventType type) {
  return switch (type) {
    EventType.breeding => 'calendar.breeding_start'.tr(),
    EventType.mating => 'calendar.breeding_start'.tr(),
    EventType.egg || EventType.eggLaying => 'calendar.egg_laid'.tr(),
    EventType.hatching || EventType.chick => 'calendar.expected_hatch'.tr(),
    EventType.banding => 'calendar.milestone_banding'.tr(),
    EventType.vaccination => 'calendar.vaccination'.tr(),
    EventType.healthCheck || EventType.health => 'calendar.health_check'.tr(),
    EventType.medication => 'calendar.medication'.tr(),
    EventType.feeding => 'calendar.feeding'.tr(),
    EventType.cleaning || EventType.cageChange => 'calendar.cleaning'.tr(),
    EventType.weightCheck => 'calendar.weight_check'.tr(),
    EventType.custom ||
    EventType.other ||
    EventType.unknown => 'calendar.general'.tr(),
  };
}

/// Badge showing event status (completed, cancelled, pending).
class EventStatusBadge extends StatelessWidget {
  final EventStatus status;

  const EventStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = eventStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        eventStatusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Returns a display label for an [EventStatus].
String eventStatusLabel(EventStatus status) {
  return switch (status) {
    EventStatus.active => 'calendar.status_active'.tr(),
    EventStatus.completed => 'calendar.status_completed'.tr(),
    EventStatus.cancelled => 'calendar.status_cancelled'.tr(),
    EventStatus.pending => 'calendar.status_pending'.tr(),
    EventStatus.unknown => 'calendar.status_active'.tr(),
  };
}

/// Returns a color for an [EventStatus].
Color eventStatusColor(EventStatus status) {
  return switch (status) {
    EventStatus.active => AppColors.success,
    EventStatus.completed => AppColors.primaryLight,
    EventStatus.cancelled => AppColors.error,
    EventStatus.pending => AppColors.warning,
    EventStatus.unknown => AppColors.neutral400,
  };
}

/// Centralized event type color constants.
abstract class EventTypeColors {
  static const breeding = AppColors.genderFemale;
  static const egg = AppColors.warning;
  static const hatching = AppColors.success;
  static const vaccination = AppColors.vaccination;
  static const health = AppColors.primaryLight;
  static const medication = AppColors.deepOrange;
  static const feeding = AppColors.feeding;
  static const cleaning = AppColors.info;
  static const weight = AppColors.neutral500;
  static const general = AppColors.neutral400;
}

/// Returns a color for an [EventType].
Color eventTypeColor(EventType type) {
  return switch (type) {
    EventType.breeding || EventType.mating => EventTypeColors.breeding,
    EventType.egg || EventType.eggLaying => EventTypeColors.egg,
    EventType.hatching || EventType.chick => EventTypeColors.hatching,
    EventType.banding => EventTypeColors.hatching,
    EventType.vaccination => EventTypeColors.vaccination,
    EventType.healthCheck || EventType.health => EventTypeColors.health,
    EventType.medication => EventTypeColors.medication,
    EventType.feeding => EventTypeColors.feeding,
    EventType.cleaning || EventType.cageChange => EventTypeColors.cleaning,
    EventType.weightCheck => EventTypeColors.weight,
    EventType.custom ||
    EventType.other ||
    EventType.unknown => EventTypeColors.general,
  };
}
