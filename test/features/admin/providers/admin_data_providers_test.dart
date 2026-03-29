import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';

void main() {
  group('AdminUsersLimitNotifier', () {
    test('initial state is kAdminPageSize (50)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(adminUsersLimitProvider), kAdminPageSize);
      expect(container.read(adminUsersLimitProvider), 50);
    });

    test('state can be increased', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminUsersLimitProvider.notifier).state = 100;
      expect(container.read(adminUsersLimitProvider), 100);
    });

    test('state can be increased multiple times', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminUsersLimitProvider.notifier).state = 100;
      container.read(adminUsersLimitProvider.notifier).state = 150;
      expect(container.read(adminUsersLimitProvider), 150);
    });
  });

  group('kAdminPageSize', () {
    test('is 50', () {
      expect(kAdminPageSize, 50);
    });
  });

  group('AdminUser model', () {
    test('construction with required fields', () {
      final user = AdminUser(id: 'u1', createdAt: DateTime(2024, 1, 1));
      expect(user.id, 'u1');
      expect(user.email, '');
      expect(user.fullName, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.isActive, isTrue);
    });

    test('construction with all fields', () {
      final user = AdminUser(
        id: 'u2',
        email: 'test@example.com',
        fullName: 'Test User',
        avatarUrl: 'https://example.com/avatar.png',
        createdAt: DateTime(2024, 3, 15),
        isActive: false,
      );
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.isActive, isFalse);
    });

    test('fromJson creates instance', () {
      final json = {
        'id': 'u3',
        'email': 'admin@test.com',
        'full_name': 'Admin',
        'avatar_url': null,
        'created_at': '2024-06-01T00:00:00.000',
        'is_active': true,
      };
      final user = AdminUser.fromJson(json);
      expect(user.id, 'u3');
      expect(user.email, 'admin@test.com');
      expect(user.fullName, 'Admin');
    });
  });

  group('AdminUserDetail model', () {
    test('default values', () {
      final detail = AdminUserDetail(id: 'u1', createdAt: DateTime(2024, 1, 1));
      expect(detail.email, '');
      expect(detail.isActive, isTrue);
      expect(detail.subscriptionPlan, isNull);
      expect(detail.birdsCount, 0);
      expect(detail.activityLogs, isEmpty);
    });

    test('construction with all fields', () {
      final detail = AdminUserDetail(
        id: 'u1',
        email: 'user@test.com',
        fullName: 'Full Name',
        createdAt: DateTime(2024, 1, 1),
        subscriptionPlan: 'premium',
        subscriptionStatus: 'active',
        birdsCount: 25,
      );
      expect(detail.subscriptionPlan, 'premium');
      expect(detail.birdsCount, 25);
    });
  });

  group('SecurityEvent model', () {
    test('construction with defaults', () {
      final event = SecurityEvent(id: 's1', createdAt: DateTime(2024, 6, 1));
      expect(event.eventType, SecurityEventType.unknown);
      expect(event.userId, isNull);
      expect(event.ipAddress, isNull);
      expect(event.details, isNull);
    });

    test('construction with full data', () {
      final event = SecurityEvent(
        id: 's2',
        eventType: SecurityEventType.bruteForce,
        userId: 'u1',
        ipAddress: '192.168.1.1',
        createdAt: DateTime(2024, 6, 1),
      );
      expect(event.eventType, SecurityEventType.bruteForce);
      expect(event.ipAddress, '192.168.1.1');
    });
  });

  group('TableInfo model', () {
    test('default values', () {
      const info = TableInfo();
      expect(info.name, '');
      expect(info.rowCount, 0);
    });

    test('construction with values', () {
      const info = TableInfo(name: 'birds', rowCount: 150);
      expect(info.name, 'birds');
      expect(info.rowCount, 150);
    });

    test('fromJson handles table_name key', () {
      final json = {'table_name': 'eggs', 'row_count': 500};
      final info = TableInfo.fromJson(json);
      expect(info.name, 'eggs');
      expect(info.rowCount, 500);
    });
  });

  group('ServerCapacity model', () {
    test('default values', () {
      const cap = ServerCapacity();
      expect(cap.databaseSizeBytes, 0);
      expect(cap.activeConnections, 0);
      expect(cap.maxConnections, 60);
      expect(cap.totalRows, 0);
    });

    test('connectionUsageRatio calculation', () {
      const cap = ServerCapacity(totalConnections: 30, maxConnections: 60);
      expect(cap.connectionUsageRatio, 0.5);
    });

    test('connectionUsageRatio is 0 when maxConnections is 0', () {
      const cap = ServerCapacity(totalConnections: 5, maxConnections: 0);
      expect(cap.connectionUsageRatio, 0.0);
    });

    test('connectionUsageRatio at full capacity', () {
      const cap = ServerCapacity(totalConnections: 60, maxConnections: 60);
      expect(cap.connectionUsageRatio, 1.0);
    });
  });

  group('TableCapacity model', () {
    test('default values', () {
      const cap = TableCapacity();
      expect(cap.name, '');
      expect(cap.sizeBytes, 0);
      expect(cap.rowCount, 0);
      expect(cap.deadTupleCount, 0);
      expect(cap.deadTupleRatio, 0.0);
      expect(cap.lastVacuum, isNull);
      expect(cap.lastAnalyze, isNull);
    });
  });
}
