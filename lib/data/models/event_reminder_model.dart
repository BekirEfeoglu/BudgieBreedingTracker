import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';

part 'event_reminder_model.freezed.dart';
part 'event_reminder_model.g.dart';

@freezed
abstract class EventReminder with _$EventReminder {
  const EventReminder._();

  const factory EventReminder({
    required String id,
    required String userId,
    required String eventId,
    @Default(30) int minutesBefore,
    @Default(ReminderType.notification)
    @JsonKey(unknownEnumValue: ReminderType.unknown)
    ReminderType type,
    @Default(false) bool isSent,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _EventReminder;

  factory EventReminder.fromJson(Map<String, dynamic> json) =>
      _$EventReminderFromJson(json);
}
