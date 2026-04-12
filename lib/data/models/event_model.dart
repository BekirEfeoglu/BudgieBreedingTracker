import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
abstract class Event with _$Event {
  const Event._();
  const factory Event({
    required String id,
    required String title,
    required DateTime eventDate,
    @JsonKey(unknownEnumValue: EventType.custom) required EventType type,
    required String userId,
    @Default(EventStatus.active)
    @JsonKey(unknownEnumValue: EventStatus.active)
    EventStatus status,
    String? description,
    String? birdId,
    String? breedingPairId,
    String? chickId,
    String? notes,
    DateTime? endDate,
    DateTime? reminderDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isDeleted,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
