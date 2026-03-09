import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';

void main() {
  group('AdminUsersLimitNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default limit is kAdminPageSize (50)', () {
      expect(container.read(adminUsersLimitProvider), kAdminPageSize);
    });

    test('can increment limit', () {
      container.read(adminUsersLimitProvider.notifier).state =
          kAdminPageSize + 50;
      expect(container.read(adminUsersLimitProvider), kAdminPageSize + 50);
    });
  });

  group('AdminAuditLimitNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default limit is 100', () {
      expect(container.read(adminAuditLimitProvider), 100);
    });

    test('can update limit', () {
      container.read(adminAuditLimitProvider.notifier).state = 200;
      expect(container.read(adminAuditLimitProvider), 200);
    });
  });

  group('AuditLogFilter', () {
    test('default hasFilter is false', () {
      const filter = AuditLogFilter();
      expect(filter.hasFilter, isFalse);
      expect(filter.searchQuery, '');
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
    });

    test('hasFilter is true with non-empty search query', () {
      const filter = AuditLogFilter(searchQuery: 'test');
      expect(filter.hasFilter, isTrue);
    });

    test('hasFilter is true when startDate is set', () {
      final filter = AuditLogFilter(startDate: DateTime(2024));
      expect(filter.hasFilter, isTrue);
    });

    test('hasFilter is true when endDate is set', () {
      final filter = AuditLogFilter(endDate: DateTime(2024));
      expect(filter.hasFilter, isTrue);
    });

    test('copyWith updates searchQuery', () {
      const original = AuditLogFilter(searchQuery: 'foo');
      final updated = original.copyWith(searchQuery: 'bar');
      expect(updated.searchQuery, 'bar');
    });

    test('copyWith can clear startDate', () {
      final original = AuditLogFilter(startDate: DateTime(2024));
      final updated = original.copyWith(clearStartDate: true);
      expect(updated.startDate, isNull);
    });

    test('copyWith can clear endDate', () {
      final original = AuditLogFilter(endDate: DateTime(2024));
      final updated = original.copyWith(clearEndDate: true);
      expect(updated.endDate, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      final original = AuditLogFilter(
        searchQuery: 'admin',
        startDate: DateTime(2024),
      );
      final updated = original.copyWith(searchQuery: 'user');
      expect(updated.searchQuery, 'user');
      expect(updated.startDate, DateTime(2024)); // preserved
    });
  });

  group('AuditLogFilterNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default state has no active filter', () {
      final filter = container.read(auditLogFilterProvider);
      expect(filter.hasFilter, isFalse);
    });

    test('can update filter state', () {
      container.read(auditLogFilterProvider.notifier).state =
          const AuditLogFilter(searchQuery: 'admin_action');
      final filter = container.read(auditLogFilterProvider);
      expect(filter.searchQuery, 'admin_action');
      expect(filter.hasFilter, isTrue);
    });
  });

  group('SecurityEventFilter', () {
    test('default severity is null (all)', () {
      const filter = SecurityEventFilter();
      expect(filter.severity, isNull);
    });

    test('default hasFilter is false', () {
      const filter = SecurityEventFilter();
      expect(filter.hasFilter, isFalse);
    });

    test('hasFilter is true when severity is set', () {
      const filter = SecurityEventFilter(severity: SecuritySeverityLevel.high);
      expect(filter.hasFilter, isTrue);
    });

    test('hasFilter is true with search query', () {
      const filter = SecurityEventFilter(searchQuery: 'failed');
      expect(filter.hasFilter, isTrue);
    });

    test('copyWith updates severity', () {
      const original = SecurityEventFilter();
      final updated = original.copyWith(severity: SecuritySeverityLevel.medium);
      expect(updated.severity, SecuritySeverityLevel.medium);
    });

    test('copyWith can clear severity', () {
      const original = SecurityEventFilter(
        severity: SecuritySeverityLevel.high,
      );
      final updated = original.copyWith(clearSeverity: true);
      expect(updated.severity, isNull);
    });
  });

  group('SecurityEventFilterNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('default state is empty filter', () {
      final filter = container.read(securityEventFilterProvider);
      expect(filter.severity, isNull);
      expect(filter.hasFilter, isFalse);
    });

    test('can update filter', () {
      container.read(securityEventFilterProvider.notifier).state =
          const SecurityEventFilter(severity: SecuritySeverityLevel.high);
      final filter = container.read(securityEventFilterProvider);
      expect(filter.severity, SecuritySeverityLevel.high);
    });
  });
}
