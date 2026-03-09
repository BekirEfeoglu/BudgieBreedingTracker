import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_filter_providers.dart';

void main() {
  group('AuditLogFilter', () {
    test('default values', () {
      const filter = AuditLogFilter();
      expect(filter.searchQuery, isEmpty);
      expect(filter.startDate, isNull);
      expect(filter.endDate, isNull);
    });

    test('hasFilter is false when all defaults', () {
      const filter = AuditLogFilter();
      expect(filter.hasFilter, isFalse);
    });

    test('hasFilter is true when searchQuery is not empty', () {
      const filter = AuditLogFilter(searchQuery: 'test');
      expect(filter.hasFilter, isTrue);
    });

    test('hasFilter is true when startDate is set', () {
      final filter = AuditLogFilter(startDate: DateTime(2024, 1, 1));
      expect(filter.hasFilter, isTrue);
    });

    test('hasFilter is true when endDate is set', () {
      final filter = AuditLogFilter(endDate: DateTime(2024, 12, 31));
      expect(filter.hasFilter, isTrue);
    });

    test('copyWith updates searchQuery', () {
      const filter = AuditLogFilter();
      final updated = filter.copyWith(searchQuery: 'login');
      expect(updated.searchQuery, 'login');
    });

    test('copyWith updates startDate', () {
      const filter = AuditLogFilter();
      final date = DateTime(2024, 3, 1);
      final updated = filter.copyWith(startDate: date);
      expect(updated.startDate, date);
    });

    test('copyWith clearStartDate removes startDate', () {
      final filter = AuditLogFilter(startDate: DateTime(2024, 3, 1));
      final updated = filter.copyWith(clearStartDate: true);
      expect(updated.startDate, isNull);
    });

    test('copyWith clearEndDate removes endDate', () {
      final filter = AuditLogFilter(endDate: DateTime(2024, 12, 31));
      final updated = filter.copyWith(clearEndDate: true);
      expect(updated.endDate, isNull);
    });
  });

  group('SecurityEventFilter', () {
    test('default values', () {
      const filter = SecurityEventFilter();
      expect(filter.searchQuery, isEmpty);
      expect(filter.severity, isNull);
    });

    test('hasFilter is false when all defaults', () {
      const filter = SecurityEventFilter();
      expect(filter.hasFilter, isFalse);
    });

    test('hasFilter is true when severity is set', () {
      const filter = SecurityEventFilter(severity: SecuritySeverityLevel.high);
      expect(filter.hasFilter, isTrue);
    });

    test('hasFilter is true when searchQuery is not empty', () {
      const filter = SecurityEventFilter(searchQuery: 'brute');
      expect(filter.hasFilter, isTrue);
    });

    test('copyWith updates severity', () {
      const filter = SecurityEventFilter();
      final updated = filter.copyWith(severity: SecuritySeverityLevel.medium);
      expect(updated.severity, SecuritySeverityLevel.medium);
    });

    test('copyWith clearSeverity removes severity', () {
      const filter = SecurityEventFilter(severity: SecuritySeverityLevel.high);
      final updated = filter.copyWith(clearSeverity: true);
      expect(updated.severity, isNull);
    });
  });

  group('AdminAuditLimitNotifier', () {
    test('initial state is 100', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(adminAuditLimitProvider), 100);
    });

    test('state can be increased', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminAuditLimitProvider.notifier).state = 200;
      expect(container.read(adminAuditLimitProvider), 200);
    });
  });

  group('AuditLogFilterNotifier', () {
    test('initial state has no filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(auditLogFilterProvider);
      expect(filter.hasFilter, isFalse);
    });

    test('filter can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(auditLogFilterProvider.notifier).state =
          const AuditLogFilter(searchQuery: 'delete');
      expect(container.read(auditLogFilterProvider).searchQuery, 'delete');
    });
  });

  group('SecurityEventFilterNotifier', () {
    test('initial state has no filter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(securityEventFilterProvider);
      expect(filter.hasFilter, isFalse);
    });

    test('filter can be updated with severity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(securityEventFilterProvider.notifier).state =
          const SecurityEventFilter(severity: SecuritySeverityLevel.high);
      expect(
        container.read(securityEventFilterProvider).severity,
        SecuritySeverityLevel.high,
      );
    });
  });
}
