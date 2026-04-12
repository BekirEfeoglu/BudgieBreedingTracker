import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';

/// Tests for admin capacity models and computed properties.
///
/// The [adminDatabaseInfoProvider] and [serverCapacityProvider] are
/// FutureProviders that require Supabase RPC calls and admin auth.
/// These tests focus on the model logic and computed properties.
void main() {
  group('ServerCapacity', () {
    test('connectionUsageRatio calculates correctly', () {
      const capacity = ServerCapacity(
        totalConnections: 30,
        maxConnections: 60,
      );
      expect(capacity.connectionUsageRatio, closeTo(0.5, 0.001));
    });

    test('connectionUsageRatio is 0 when maxConnections is 0', () {
      const capacity = ServerCapacity(
        totalConnections: 10,
        maxConnections: 0,
      );
      expect(capacity.connectionUsageRatio, 0);
    });

    test('connectionUsageRatio at full capacity', () {
      const capacity = ServerCapacity(
        totalConnections: 60,
        maxConnections: 60,
      );
      expect(capacity.connectionUsageRatio, closeTo(1.0, 0.001));
    });

    test('connectionUsageRatio over capacity', () {
      const capacity = ServerCapacity(
        totalConnections: 70,
        maxConnections: 60,
      );
      expect(capacity.connectionUsageRatio, greaterThan(1.0));
    });

    test('default values are sensible', () {
      const capacity = ServerCapacity();
      expect(capacity.databaseSizeBytes, 0);
      expect(capacity.activeConnections, 0);
      expect(capacity.totalConnections, 0);
      expect(capacity.maxConnections, 60);
      expect(capacity.cacheHitRatio, 0);
      expect(capacity.totalRows, 0);
      expect(capacity.indexHitRatio, 0);
      expect(capacity.tables, isEmpty);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'database_size_bytes': 1024000,
        'active_connections': 5,
        'total_connections': 15,
        'max_connections': 100,
        'cache_hit_ratio': 0.99,
        'total_rows': 5000,
        'index_hit_ratio': 0.95,
        'tables': <Map<String, dynamic>>[],
      };
      final capacity = ServerCapacity.fromJson(json);

      expect(capacity.databaseSizeBytes, 1024000);
      expect(capacity.activeConnections, 5);
      expect(capacity.totalConnections, 15);
      expect(capacity.maxConnections, 100);
      expect(capacity.cacheHitRatio, closeTo(0.99, 0.001));
      expect(capacity.totalRows, 5000);
    });
  });

  group('TableCapacity', () {
    test('default values', () {
      const table = TableCapacity();
      expect(table.name, '');
      expect(table.sizeBytes, 0);
      expect(table.rowCount, 0);
      expect(table.deadTupleCount, 0);
      expect(table.deadTupleRatio, 0);
      expect(table.lastVacuum, isNull);
      expect(table.lastAnalyze, isNull);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'name': 'birds',
        'size_bytes': 2048,
        'row_count': 150,
        'dead_tuple_count': 5,
        'dead_tuple_ratio': 0.03,
        'last_vacuum': '2025-06-01',
        'last_analyze': '2025-06-01',
      };
      final table = TableCapacity.fromJson(json);

      expect(table.name, 'birds');
      expect(table.sizeBytes, 2048);
      expect(table.rowCount, 150);
      expect(table.deadTupleCount, 5);
    });
  });

  group('TableInfo', () {
    test('default values', () {
      const info = TableInfo();
      expect(info.name, '');
      expect(info.rowCount, 0);
    });

    test('fromJson with table_name key mapping', () {
      final json = {'table_name': 'birds', 'row_count': 42};
      final info = TableInfo.fromJson(json);

      expect(info.name, 'birds');
      expect(info.rowCount, 42);
    });
  });

  group('ServerCapacity critical threshold detection', () {
    test('below 90% threshold is non-critical', () {
      const capacity = ServerCapacity(
        databaseSizeBytes: 400 * 1024 * 1024, // 400MB of 500MB
        totalConnections: 50,
        maxConnections: 60,
      );
      final dbRatio = capacity.databaseSizeBytes / (500 * 1024 * 1024);
      final connRatio = capacity.connectionUsageRatio;

      expect(dbRatio, lessThan(0.9));
      expect(connRatio, lessThan(0.9));
    });

    test('above 90% threshold is critical', () {
      const capacity = ServerCapacity(
        databaseSizeBytes: 460 * 1024 * 1024, // 460MB of 500MB
        totalConnections: 55,
        maxConnections: 60,
      );
      final dbRatio = capacity.databaseSizeBytes / (500 * 1024 * 1024);
      final connRatio = capacity.connectionUsageRatio;

      // At least one should exceed 0.9
      expect(dbRatio > 0.9 || connRatio > 0.9, isTrue);
    });
  });
}
