import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';

void main() {
  group('AdminStats', () {
    test('default values', () {
      const stats = AdminStats();
      expect(stats.totalUsers, 0);
      expect(stats.activeToday, 0);
      expect(stats.newUsersToday, 0);
      expect(stats.totalBirds, 0);
      expect(stats.activeBreedings, 0);
    });

    test('copyWith updates fields', () {
      const stats = AdminStats();
      final updated = stats.copyWith(totalUsers: 100, totalBirds: 500);
      expect(updated.totalUsers, 100);
      expect(updated.totalBirds, 500);
      expect(updated.activeToday, 0);
    });

    test('fromJson creates instance', () {
      final json = {
        'total_users': 50,
        'active_today': 10,
        'new_users_today': 3,
        'total_birds': 200,
        'active_breedings': 15,
      };
      final stats = AdminStats.fromJson(json);
      expect(stats.totalUsers, 50);
      expect(stats.activeToday, 10);
      expect(stats.newUsersToday, 3);
      expect(stats.totalBirds, 200);
      expect(stats.activeBreedings, 15);
    });

    test('toJson produces correct snake_case keys', () {
      const stats = AdminStats(totalUsers: 42, activeBreedings: 7);
      final json = stats.toJson();
      expect(json['total_users'], 42);
      expect(json['active_breedings'], 7);
    });
  });

  group('SystemAlert construction', () {
    test('construction with defaults', () {
      final alert = SystemAlert(id: 'a1', createdAt: DateTime(2024, 6, 1));
      expect(alert.title, '');
      expect(alert.message, '');
      expect(alert.severity, AlertSeverity.info);
      expect(alert.alertType, 'system');
      expect(alert.isActive, isTrue);
      expect(alert.isAcknowledged, isFalse);
    });

    test('construction with custom values', () {
      final alert = SystemAlert(
        id: 'a2',
        title: 'High CPU',
        message: 'CPU usage above 90%',
        severity: AlertSeverity.critical,
        isAcknowledged: true,
        createdAt: DateTime(2024, 6, 1),
      );
      expect(alert.title, 'High CPU');
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.isAcknowledged, isTrue);
    });
  });

  group('AdminLog construction', () {
    test('construction with defaults', () {
      final log = AdminLog(id: 'l1', createdAt: DateTime(2024, 6, 1));
      expect(log.action, '');
      expect(log.adminUserId, isNull);
      expect(log.targetUserId, isNull);
      expect(log.details, isNull);
    });

    test('construction with full data', () {
      final log = AdminLog(
        id: 'l2',
        action: 'ban_user',
        adminUserId: 'admin1',
        targetUserId: 'user1',
        createdAt: DateTime(2024, 6, 1),
      );
      expect(log.action, 'ban_user');
      expect(log.adminUserId, 'admin1');
      expect(log.targetUserId, 'user1');
    });
  });

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
      expect(event.eventType, SecurityEventType.unknown);
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

  group('AdminUsersQuery', () {
    test('defaults are correct', () {
      const query = AdminUsersQuery();
      expect(query.searchTerm, '');
      expect(query.isActiveFilter, isNull);
      expect(query.sortField, 'created_at');
      expect(query.sortAscending, isFalse);
      expect(query.limit, 50);
    });

    test('copyWith works', () {
      const query = AdminUsersQuery();
      final updated = query.copyWith(searchTerm: 'test', isActiveFilter: true);
      expect(updated.searchTerm, 'test');
      expect(updated.isActiveFilter, isTrue);
    });

    test('toJson/fromJson round-trip', () {
      const query = AdminUsersQuery(searchTerm: 'hello', limit: 100);
      final json = query.toJson();
      final restored = AdminUsersQuery.fromJson(json);
      expect(restored.searchTerm, 'hello');
      expect(restored.limit, 100);
    });
  });

  group('FeedbackQuery', () {
    test('defaults are correct', () {
      const query = FeedbackQuery();
      expect(query.statusFilter, isNull);
      expect(query.searchQuery, '');
      expect(query.limit, 50);
    });

    test('toJson/fromJson round-trip', () {
      const query = FeedbackQuery(
        statusFilter: FeedbackStatus.open,
        searchQuery: 'bug',
        limit: 25,
      );
      final json = query.toJson();
      final restored = FeedbackQuery.fromJson(json);
      expect(restored.statusFilter, FeedbackStatus.open);
      expect(restored.searchQuery, 'bug');
    });
  });

  group('AdminSystemSettings', () {
    test('defaults are correct', () {
      const settings = AdminSystemSettings();
      expect(settings.maintenanceMode, isFalse);
      expect(settings.registrationOpen, isTrue);
      expect(settings.premiumEnabled, isTrue);
      expect(settings.autoBackupEnabled, isFalse);
      expect(settings.lastUpdated, isNull);
    });

    test('fromSettingsMap parses correctly', () {
      final map = <String, Map<String, dynamic>>{
        'maintenance_mode': {'value': true, 'updated_at': '2026-01-15T10:00:00Z'},
        'registration_open': {'value': false, 'updated_at': '2026-01-14T10:00:00Z'},
        'auto_backup_enabled': {'value': 'true', 'updated_at': null},
      };
      final settings = AdminSystemSettings.fromSettingsMap(map);
      expect(settings.maintenanceMode, isTrue);
      expect(settings.registrationOpen, isFalse);
      expect(settings.autoBackupEnabled, isTrue);
      expect(settings.lastUpdated, DateTime.utc(2026, 1, 15, 10));
    });
  });

  group('SecurityEvent with enum', () {
    test('severity is derived from eventType', () {
      final event = SecurityEvent(
        id: 'e1',
        eventType: SecurityEventType.bruteForce,
        createdAt: DateTime(2024),
      );
      expect(event.severity, SecuritySeverityLevel.high);
    });

    test('fromJson handles string eventType', () {
      final json = {
        'id': 'e1',
        'event_type': 'suspiciousActivity',
        'created_at': '2024-01-15T10:00:00.000Z',
      };
      final event = SecurityEvent.fromJson(json);
      expect(event.eventType, SecurityEventType.suspiciousActivity);
      expect(event.severity, SecuritySeverityLevel.medium);
    });

    test('fromJson defaults unknown eventType', () {
      final json = {
        'id': 'e2',
        'event_type': 'never_seen_before',
        'created_at': '2024-01-15T10:00:00.000Z',
      };
      final event = SecurityEvent.fromJson(json);
      expect(event.eventType, SecurityEventType.unknown);
    });
  });
}
