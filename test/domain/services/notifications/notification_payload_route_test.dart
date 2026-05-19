import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

const _id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

void main() {
  group('NotificationService.payloadToRoute', () {
    test('returns null for null payload', () {
      expect(NotificationService.payloadToRoute(null), isNull);
    });

    test('returns null for payload without colon', () {
      expect(NotificationService.payloadToRoute('no-colon'), isNull);
    });

    test('returns null for payload with multiple colons', () {
      expect(NotificationService.payloadToRoute('a:b:c'), isNull);
    });

    test('maps breeding payload', () {
      expect(
        NotificationService.payloadToRoute('breeding:$_id'),
        '/breeding/$_id',
      );
    });

    test('maps incubation payload to breeding route', () {
      expect(
        NotificationService.payloadToRoute('incubation:$_id'),
        '/breeding/$_id',
      );
    });

    test('maps bird payload', () {
      expect(
        NotificationService.payloadToRoute('bird:$_id'),
        '/birds/$_id',
      );
    });

    test('maps chick payload', () {
      expect(
        NotificationService.payloadToRoute('chick:$_id'),
        '/chicks/$_id',
      );
    });

    test('maps chick_care payload to chick route', () {
      expect(
        NotificationService.payloadToRoute('chick_care:$_id'),
        '/chicks/$_id',
      );
    });

    test('maps banding payload to chick route', () {
      expect(
        NotificationService.payloadToRoute('banding:$_id'),
        '/chicks/$_id',
      );
    });

    test('maps egg payload to breeding list (id not validated)', () {
      expect(
        NotificationService.payloadToRoute('egg:any-id'),
        '/breeding',
      );
    });

    test('maps egg_turning payload to breeding list (id not validated)', () {
      expect(
        NotificationService.payloadToRoute('egg_turning:any-id'),
        '/breeding',
      );
    });

    test('maps health_check payload', () {
      expect(
        NotificationService.payloadToRoute('health_check:$_id'),
        '/health-records/$_id',
      );
    });

    test('maps event payload to calendar (id not validated)', () {
      expect(
        NotificationService.payloadToRoute('event:any-id'),
        '/calendar',
      );
    });

    test('maps event_reminder payload to calendar (id not validated)', () {
      expect(
        NotificationService.payloadToRoute('event_reminder:any-id'),
        '/calendar',
      );
    });

    test('maps notification payload to notifications (id not validated)', () {
      expect(
        NotificationService.payloadToRoute('notification:any-id'),
        '/notifications',
      );
    });

    test('returns null for unknown type', () {
      expect(
        NotificationService.payloadToRoute('unknown:$_id'),
        isNull,
      );
    });

    group('security: rejects malformed ids', () {
      test('rejects bird payload with non-UUID id', () {
        expect(
          NotificationService.payloadToRoute('bird:not-a-uuid'),
          isNull,
        );
      });

      test('rejects breeding payload with path traversal', () {
        expect(
          NotificationService.payloadToRoute('breeding:../../etc/passwd'),
          isNull,
        );
      });

      test('rejects health_check payload with empty id', () {
        expect(
          NotificationService.payloadToRoute('health_check:'),
          isNull,
        );
      });
    });
  });
}
