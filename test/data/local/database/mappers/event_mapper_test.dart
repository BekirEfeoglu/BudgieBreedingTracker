import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/event_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

void main() {
  final eventDate = DateTime.utc(2024, 5, 10);

  group('EventRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = EventRow(
        id: 'ev1',
        title: 'Vet Visit',
        eventDate: eventDate,
        type: EventType.healthCheck,
        userId: 'u1',
        status: EventStatus.active,
        description: 'Annual checkup',
        birdId: 'b1',
        breedingPairId: null,
        notes: 'Bring records',
        endDate: null,
        reminderDate: DateTime.utc(2024, 5, 9),
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.id, 'ev1');
      expect(model.title, 'Vet Visit');
      expect(model.eventDate, eventDate);
      expect(model.type, EventType.healthCheck);
      expect(model.userId, 'u1');
      expect(model.status, EventStatus.active);
      expect(model.description, 'Annual checkup');
      expect(model.birdId, 'b1');
      expect(model.breedingPairId, isNull);
    });
  });

  group('EventModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      final model = Event(
        id: 'ev1',
        title: 'Feeding',
        eventDate: eventDate,
        type: EventType.feeding,
        userId: 'u1',
        status: EventStatus.completed,
        birdId: 'b1',
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'ev1');
      expect(companion.title.value, 'Feeding');
      expect(companion.eventDate.value, eventDate);
      expect(companion.type.value, EventType.feeding);
      expect(companion.userId.value, 'u1');
      expect(companion.status.value, EventStatus.completed);
      expect(companion.birdId.value, 'b1');
      expect(companion.isDeleted.value, false);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      final model = Event(
        id: 'ev1',
        title: 'Test',
        eventDate: eventDate,
        type: EventType.custom,
        userId: 'u1',
      );
      final companion = model.toCompanion();

      expect(
        companion.updatedAt.value!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
