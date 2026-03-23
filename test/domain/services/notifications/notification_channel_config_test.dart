import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_channel_config.dart';

void main() {
  group('NotificationChannelConfig channel ID constants', () {
    test('eggTurningChannelId has expected value', () {
      expect(NotificationChannelConfig.eggTurningChannelId, 'egg_turning');
    });

    test('incubationChannelId has expected value', () {
      expect(NotificationChannelConfig.incubationChannelId, 'incubation');
    });

    test('chickCareChannelId has expected value', () {
      expect(NotificationChannelConfig.chickCareChannelId, 'chick_care');
    });

    test('healthCheckChannelId has expected value', () {
      expect(NotificationChannelConfig.healthCheckChannelId, 'health_check');
    });

    test('all channel IDs are unique', () {
      final ids = [
        NotificationChannelConfig.eggTurningChannelId,
        NotificationChannelConfig.incubationChannelId,
        NotificationChannelConfig.chickCareChannelId,
        NotificationChannelConfig.healthCheckChannelId,
      ];
      expect(ids.toSet().length, ids.length);
    });
  });

  group('NotificationChannelConfig.payloadToRoute', () {
    test('returns null for null payload', () {
      expect(NotificationChannelConfig.payloadToRoute(null), isNull);
    });

    test('returns null for payload without colon separator', () {
      expect(NotificationChannelConfig.payloadToRoute('no-colon'), isNull);
    });

    test('returns null for empty string', () {
      expect(NotificationChannelConfig.payloadToRoute(''), isNull);
    });

    test('returns null for payload with more than two parts', () {
      expect(NotificationChannelConfig.payloadToRoute('a:b:c'), isNull);
    });

    test('returns null for unknown type', () {
      expect(NotificationChannelConfig.payloadToRoute('unknown:id-1'), isNull);
    });

    test('maps breeding payload to breeding detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('breeding:pair-123'),
        '/breeding/pair-123',
      );
    });

    test('maps incubation payload to breeding detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('incubation:inc-456'),
        '/breeding/inc-456',
      );
    });

    test('maps bird payload to bird detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('bird:bird-789'),
        '/birds/bird-789',
      );
    });

    test('maps chick payload to chick detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('chick:chick-001'),
        '/chicks/chick-001',
      );
    });

    test('maps chick_care payload to chick detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('chick_care:cc-002'),
        '/chicks/cc-002',
      );
    });

    test('maps egg payload to breeding list route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('egg:egg-123'),
        '/breeding',
      );
    });

    test('maps egg_turning payload to breeding list route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('egg_turning:et-456'),
        '/breeding',
      );
    });

    test('maps health_check payload to health record detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('health_check:hc-789'),
        '/health-records/hc-789',
      );
    });

    test('maps event payload to calendar route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('event:ev-123'),
        '/calendar',
      );
    });

    test('maps event_reminder payload to calendar route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('event_reminder:er-456'),
        '/calendar',
      );
    });

    test('maps calendar payload to calendar route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('calendar:cal-789'),
        '/calendar',
      );
    });

    test('maps notification payload to notifications route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('notification:n-123'),
        '/notifications',
      );
    });

    test('preserves entity ID in routed path', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      expect(
        NotificationChannelConfig.payloadToRoute('bird:$uuid'),
        '/birds/$uuid',
      );
    });
  });
}
