import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

Event _buildEvent({
  String id = 'event-1',
  String title = 'Health check',
  DateTime? eventDate,
  EventType type = EventType.healthCheck,
  String userId = 'user-1',
  EventStatus status = EventStatus.active,
  String? description,
  String? birdId,
  String? breedingPairId,
  String? notes,
  DateTime? endDate,
  DateTime? reminderDate,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isDeleted = false,
}) {
  return Event(
    id: id,
    title: title,
    eventDate: eventDate ?? DateTime(2024, 2, 1),
    type: type,
    userId: userId,
    status: status,
    description: description,
    birdId: birdId,
    breedingPairId: breedingPairId,
    notes: notes,
    endDate: endDate,
    reminderDate: reminderDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

void main() {
  group('Event model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final event = _buildEvent(
          id: 'event-42',
          title: 'Mating plan',
          eventDate: DateTime(2024, 2, 10),
          type: EventType.mating,
          userId: 'user-42',
          status: EventStatus.completed,
          description: 'Pair introduced',
          birdId: 'bird-1',
          breedingPairId: 'pair-1',
          notes: 'Successful',
          endDate: DateTime(2024, 2, 11),
          reminderDate: DateTime(2024, 2, 9, 20, 0),
          createdAt: DateTime(2024, 2, 9, 8, 0),
          updatedAt: DateTime(2024, 2, 10, 8, 0),
          isDeleted: true,
        );

        final restored = Event.fromJson(event.toJson());
        expect(restored, event);
      });

      test('applies default status and isDeleted', () {
        final event = Event.fromJson({
          'id': 'event-1',
          'title': 'Simple event',
          'event_date': DateTime(2024, 2, 1).toIso8601String(),
          'type': 'custom',
          'user_id': 'user-1',
        });

        expect(event.status, EventStatus.active);
        expect(event.isDeleted, isFalse);
      });

      test('falls back to custom type and active status', () {
        final event = Event.fromJson({
          'id': 'event-1',
          'title': 'Invalid event',
          'event_date': DateTime(2024, 2, 1).toIso8601String(),
          'type': 'invalid-type',
          'status': 'invalid-status',
          'user_id': 'user-1',
        });

        expect(event.type, EventType.custom);
        expect(event.status, EventStatus.active);
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final event = _buildEvent(title: 'Old title', notes: 'Old');
        final updated = event.copyWith(title: 'New title', notes: 'New');

        expect(updated.title, 'New title');
        expect(updated.notes, 'New');
        expect(updated.id, event.id);
        expect(updated.userId, event.userId);
      });
    });
  });
}
