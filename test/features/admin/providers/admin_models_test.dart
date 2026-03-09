import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';

void main() {
  group('Admin model factories', () {
    test('AdminLog.fromJson parses required and optional fields', () {
      final log = AdminLog.fromJson({
        'id': 'log-1',
        'action': 'user.updated',
        'admin_user_id': 'admin-1',
        'target_user_id': 'user-1',
        'details': 'changed role',
        'created_at': '2026-02-17T10:00:00.000Z',
      });

      expect(log.id, 'log-1');
      expect(log.action, 'user.updated');
      expect(log.adminUserId, 'admin-1');
      expect(log.targetUserId, 'user-1');
      expect(log.details, 'changed role');
      expect(log.createdAt, DateTime.parse('2026-02-17T10:00:00.000Z'));
    });

    test('SecurityEvent.fromJson parses defaults safely', () {
      final event = SecurityEvent.fromJson({
        'id': 'sec-1',
        'created_at': '2026-02-17T10:00:00.000Z',
      });

      expect(event.id, 'sec-1');
      expect(event.eventType, '');
      expect(event.userId, isNull);
      expect(event.ipAddress, isNull);
    });

    test('SystemAlert.fromJson parses default severity and resolved flag', () {
      final alert = SystemAlert.fromJson({
        'id': 'alert-1',
        'alert_type': 'db',
        'title': '',
        'message': 'degraded',
        'created_at': '2026-02-17T10:00:00.000Z',
      });

      expect(alert.id, 'alert-1');
      expect(alert.alertType, 'db');
      expect(alert.message, 'degraded');
      expect(alert.severity, AlertSeverity.info);
      expect(alert.isAcknowledged, isFalse);
    });
  });
}
