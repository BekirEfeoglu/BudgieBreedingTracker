import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';

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

    test('toJson produces correct keys', () {
      const stats = AdminStats(totalUsers: 42);
      final json = stats.toJson();
      expect(json['total_users'], 42);
    });
  });

  group('SystemAlert', () {
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

  group('AdminLog', () {
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

  group('AdminSystemSettingsProvider', () {
    // adminSystemSettingsProvider depends on requireAdmin + Supabase client,
    // so we only test the state container behavior here.
    test('adminSystemAlertsProvider exists', () {
      expect(adminSystemAlertsProvider, isNotNull);
    });

    test('recentAdminActionsProvider exists', () {
      expect(recentAdminActionsProvider, isNotNull);
    });

    test('adminSystemSettingsProvider exists', () {
      expect(adminSystemSettingsProvider, isNotNull);
    });
  });
}
