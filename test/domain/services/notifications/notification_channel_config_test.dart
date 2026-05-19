import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_channel_config.dart';

const _validId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

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
      expect(
        NotificationChannelConfig.payloadToRoute('unknown:$_validId'),
        isNull,
      );
    });

    test('maps breeding payload to breeding detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('breeding:$_validId'),
        '/breeding/$_validId',
      );
    });

    test('maps incubation payload to breeding detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('incubation:$_validId'),
        '/breeding/$_validId',
      );
    });

    test('maps bird payload to bird detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('bird:$_validId'),
        '/birds/$_validId',
      );
    });

    test('maps chick payload to chick detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('chick:$_validId'),
        '/chicks/$_validId',
      );
    });

    test('maps chick_care payload to chick detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('chick_care:$_validId'),
        '/chicks/$_validId',
      );
    });

    test('maps egg payload to breeding list route (id ignored)', () {
      // Egg payloads carry egg IDs, which are not valid pair IDs; route to
      // the list view rather than a pair-detail path. ID is not validated.
      expect(
        NotificationChannelConfig.payloadToRoute('egg:any-malformed-id'),
        '/breeding',
      );
    });

    test('maps egg_turning payload to breeding list route (id ignored)', () {
      expect(
        NotificationChannelConfig.payloadToRoute('egg_turning:any-id'),
        '/breeding',
      );
    });

    test('maps health_check payload to health record detail route', () {
      expect(
        NotificationChannelConfig.payloadToRoute('health_check:$_validId'),
        '/health-records/$_validId',
      );
    });

    test('maps event payload to calendar route (id ignored)', () {
      expect(
        NotificationChannelConfig.payloadToRoute('event:any-id'),
        '/calendar',
      );
    });

    test('maps event_reminder payload to calendar route (id ignored)', () {
      expect(
        NotificationChannelConfig.payloadToRoute('event_reminder:any-id'),
        '/calendar',
      );
    });

    test('maps notification payload to notifications route (id ignored)', () {
      expect(
        NotificationChannelConfig.payloadToRoute('notification:any-id'),
        '/notifications',
      );
    });

    test('preserves entity ID in routed path', () {
      expect(
        NotificationChannelConfig.payloadToRoute('bird:$_validId'),
        '/birds/$_validId',
      );
    });

    group('id validation (security)', () {
      test('rejects bird payload with malformed (non-UUID) id', () {
        expect(NotificationChannelConfig.payloadToRoute('bird:not-a-uuid'),
            isNull);
      });

      test('rejects breeding payload with malformed id', () {
        expect(
          NotificationChannelConfig.payloadToRoute('breeding:pair-123'),
          isNull,
        );
      });

      test('rejects chick payload with malformed id', () {
        expect(
          NotificationChannelConfig.payloadToRoute('chick:foo'),
          isNull,
        );
      });

      test('rejects health_check payload with path-traversal in id', () {
        expect(
          NotificationChannelConfig.payloadToRoute('health_check:../etc/passwd'),
          isNull,
        );
      });

      test('rejects bird payload with empty id', () {
        expect(NotificationChannelConfig.payloadToRoute('bird:'), isNull);
      });

      test('rejects bird payload with script-injection attempt', () {
        expect(
          NotificationChannelConfig.payloadToRoute('bird:<script>x</script>'),
          isNull,
        );
      });
    });
  });
}
