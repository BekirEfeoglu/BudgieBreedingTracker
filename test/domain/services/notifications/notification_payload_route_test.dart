import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

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
        NotificationService.payloadToRoute('breeding:abc-123'),
        '/breeding/abc-123',
      );
    });

    test('maps incubation payload to breeding route', () {
      expect(
        NotificationService.payloadToRoute('incubation:inc-456'),
        '/breeding/inc-456',
      );
    });

    test('maps bird payload', () {
      expect(
        NotificationService.payloadToRoute('bird:bird-789'),
        '/birds/bird-789',
      );
    });

    test('maps chick payload', () {
      expect(
        NotificationService.payloadToRoute('chick:chick-001'),
        '/chicks/chick-001',
      );
    });

    test('maps chick_care payload to chick route', () {
      expect(
        NotificationService.payloadToRoute('chick_care:cc-002'),
        '/chicks/cc-002',
      );
    });

    test('maps banding payload to chick route', () {
      expect(
        NotificationService.payloadToRoute('banding:chick-band-1'),
        '/chicks/chick-band-1',
      );
    });

    test('maps egg payload to breeding list', () {
      expect(
        NotificationService.payloadToRoute('egg:egg-123'),
        '/breeding',
      );
    });

    test('maps egg_turning payload to breeding list', () {
      expect(
        NotificationService.payloadToRoute('egg_turning:et-123'),
        '/breeding',
      );
    });

    test('maps health_check payload', () {
      expect(
        NotificationService.payloadToRoute('health_check:hc-123'),
        '/health-records/hc-123',
      );
    });

    test('maps event payload to calendar', () {
      expect(
        NotificationService.payloadToRoute('event:ev-123'),
        '/calendar',
      );
    });

    test('maps event_reminder payload to calendar', () {
      expect(
        NotificationService.payloadToRoute('event_reminder:er-123'),
        '/calendar',
      );
    });

    test('maps calendar payload to calendar', () {
      expect(
        NotificationService.payloadToRoute('calendar:cal-123'),
        '/calendar',
      );
    });

    test('maps notification payload to notifications', () {
      expect(
        NotificationService.payloadToRoute('notification:n-123'),
        '/notifications',
      );
    });

    test('returns null for unknown type', () {
      expect(
        NotificationService.payloadToRoute('unknown:id-123'),
        isNull,
      );
    });
  });
}
