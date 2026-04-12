import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';

part 'notification_schedule_model.freezed.dart';
part 'notification_schedule_model.g.dart';

@freezed
abstract class NotificationSchedule with _$NotificationSchedule {
  const NotificationSchedule._();

  const factory NotificationSchedule({
    required String id,
    required String userId,
    @JsonKey(unknownEnumValue: NotificationType.custom)
    required NotificationType type,
    required String title,
    String? message,
    required DateTime scheduledAt,
    @Default(true) bool isActive,
    @Default(false) bool isRecurring,
    int? intervalMinutes,
    String? relatedEntityId,
    @Default(NotificationPriority.normal)
    @JsonKey(unknownEnumValue: NotificationPriority.normal)
    NotificationPriority priority,
    String? metadata,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _NotificationSchedule;

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) =>
      _$NotificationScheduleFromJson(json);
}
