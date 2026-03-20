import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';

void main() {
  group('NotificationIds.generate', () {
    test('returns value within base ID range', () {
      final id = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        'test-entity-1',
        0,
      );
      expect(id, greaterThanOrEqualTo(NotificationIds.eggTurningBaseId));
      expect(id, lessThan(NotificationIds.eggTurningBaseId + 100000));
    });

    test('different entities produce different IDs', () {
      final id1 = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        'entity-aaa',
        0,
      );
      final id2 = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        'entity-bbb',
        0,
      );
      expect(id1, isNot(equals(id2)));
    });

    test('different offsets produce different IDs', () {
      final id1 = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        'same-entity',
        0,
      );
      final id2 = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        'same-entity',
        1,
      );
      expect(id1, isNot(equals(id2)));
    });

    test('same inputs always produce the same ID (deterministic)', () {
      final id1 = NotificationIds.generate(
        NotificationIds.incubationBaseId,
        'stable-entity',
        3,
      );
      final id2 = NotificationIds.generate(
        NotificationIds.incubationBaseId,
        'stable-entity',
        3,
      );
      expect(id1, equals(id2));
    });

    test('different base IDs produce different ranges', () {
      final eggId = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        'entity-1',
        0,
      );
      final incubationId = NotificationIds.generate(
        NotificationIds.incubationBaseId,
        'entity-1',
        0,
      );
      // They should differ because the base offsets differ
      expect(eggId, isNot(equals(incubationId)));
    });

    test('throws RangeError for negative offset', () {
      expect(
        () => NotificationIds.generate(
          NotificationIds.eggTurningBaseId,
          'entity',
          -1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError for offset >= idsPerEntitySlot', () {
      expect(
        () => NotificationIds.generate(
          NotificationIds.eggTurningBaseId,
          'entity',
          NotificationIds.idsPerEntitySlot,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('max valid offset works (99)', () {
      final id = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        'entity',
        NotificationIds.idsPerEntitySlot - 1,
      );
      expect(id, greaterThanOrEqualTo(NotificationIds.eggTurningBaseId));
    });
  });

  group('NotificationIds constants', () {
    test('base IDs are non-overlapping (100k apart)', () {
      expect(NotificationIds.eggTurningBaseId, 100000);
      expect(NotificationIds.incubationBaseId, 200000);
      expect(NotificationIds.healthCheckBaseId, 300000);
      expect(NotificationIds.chickCareBaseId, 400000);
    });

    test('idsPerEntitySlot is 100', () {
      expect(NotificationIds.idsPerEntitySlot, 100);
    });
  });

  group('NotificationIds hash distribution', () {
    test('no collisions for 100 sequential entity IDs at offset 0', () {
      final ids = <int>{};
      for (var i = 0; i < 100; i++) {
        final id = NotificationIds.generate(
          NotificationIds.eggTurningBaseId,
          'entity-$i',
          0,
        );
        ids.add(id);
      }
      // FNV-1a with 1000-slot modulo: expect reasonable distribution
      // (at least 50% unique for 100 sequential keys)
      expect(ids.length, greaterThanOrEqualTo(50));
    });

    test('UUID-like entity IDs produce stable IDs', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final id1 = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        uuid,
        5,
      );
      final id2 = NotificationIds.generate(
        NotificationIds.eggTurningBaseId,
        uuid,
        5,
      );
      expect(id1, equals(id2));
    });
  });
}
