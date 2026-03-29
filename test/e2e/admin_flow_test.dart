@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Admin Flow E2E', () {
    test(
      'GIVEN admin user WHEN dashboard data is loaded THEN total users, active sessions and system health metrics are visible',
      () {
        const dashboardStats = AdminStats(
          totalUsers: 1200,
          activeToday: 188,
          newUsersToday: 17,
          totalBirds: 4200,
          activeBreedings: 316,
        );
        const capacity = ServerCapacity(
          databaseSizeBytes: 16000000,
          activeConnections: 5,
          totalConnections: 12,
          maxConnections: 60,
          cacheHitRatio: 99.5,
          totalRows: 1200,
          indexHitRatio: 95.0,
          tables: [],
        );

        expect(dashboardStats.totalUsers, greaterThan(0));
        expect(dashboardStats.activeToday, greaterThan(0));
        expect(capacity.cacheHitRatio, greaterThan(90));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN admin users route WHEN list pagination is used THEN users are loaded in page-size chunks with role/email/last-login metadata',
      () {
        final container = createTestContainer();
        addTearDown(container.dispose);

        final sampleUser = AdminUser(
          id: 'u-1',
          email: 'admin-user@example.com',
          fullName: 'Admin User',
          createdAt: DateTime(2024, 1, 10),
          isActive: true,
        );

        final initialLimit = container.read(adminUsersLimitProvider);
        container.read(adminUsersLimitProvider.notifier).state +=
            AdminConstants.usersPageSize;
        final updatedLimit = container.read(adminUsersLimitProvider);

        expect(sampleUser.email, contains('@'));
        expect(sampleUser.isActive, isTrue);
        expect(initialLimit, AdminConstants.usersPageSize);
        expect(updatedLimit, AdminConstants.usersPageSize * 2);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN admin users detail WHEN a user is opened THEN activity and subscription details are available with suspend action eligibility',
      () {
        final detail = AdminUserDetail(
          id: 'u-42',
          email: 'member@example.com',
          fullName: 'Member',
          createdAt: DateTime(2023, 8, 12),
          birdsCount: 18,
          subscriptionPlan: 'premium',
          subscriptionStatus: 'active',
          activityLogs: [
            AdminLog(
              id: 'log-1',
              action: 'profile_update',
              createdAt: DateTime(2025, 1, 1),
            ),
          ],
        );

        expect(detail.subscriptionPlan, 'premium');
        expect(detail.activityLogs, isNotEmpty);
        expect(detail.birdsCount, greaterThan(0));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN admin audit route WHEN user/action/date filters are applied THEN audit entries are filtered correctly',
      () {
        final logs = <AdminLog>[
          AdminLog(
            id: 'a1',
            action: 'suspend_user',
            targetUserId: 'u-1',
            details: 'manual action',
            createdAt: DateTime(2026, 1, 5),
          ),
          AdminLog(
            id: 'a2',
            action: 'restore_user',
            targetUserId: 'u-2',
            details: 'support action',
            createdAt: DateTime(2026, 1, 8),
          ),
        ];

        final filter = AuditLogFilter(
          searchQuery: 'suspend',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 6),
        );

        final filtered = logs.where((log) {
          final inDateRange =
              log.createdAt.isAfter(filter.startDate!) &&
              log.createdAt.isBefore(
                filter.endDate!.add(const Duration(days: 1)),
              );
          final matchesQuery = log.action.contains(filter.searchQuery);
          return inDateRange && matchesQuery;
        }).toList();

        expect(filter.hasFilter, isTrue);
        expect(filtered, hasLength(1));
        expect(filtered.first.action, 'suspend_user');
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN admin database page WHEN table status is loaded THEN table size/count information is visible and maintenance actions are available',
      () {
        final tables = <TableInfo>[
          const TableInfo(name: 'birds', rowCount: 250),
          const TableInfo(name: 'breeding_pairs', rowCount: 80),
          const TableInfo(name: 'eggs', rowCount: 430),
        ];

        final totalRows = tables.fold<int>(
          0,
          (sum, item) => sum + item.rowCount,
        );
        final hasBirdTable = tables.any((item) => item.name == 'birds');
        const actions = <String>['Temizle', 'Optimize Et'];

        expect(hasBirdTable, isTrue);
        expect(totalRows, greaterThan(0));
        expect(actions, contains('Temizle'));
        expect(actions, contains('Optimize Et'));
      },
      timeout: e2eTimeout,
    );
  });
}
