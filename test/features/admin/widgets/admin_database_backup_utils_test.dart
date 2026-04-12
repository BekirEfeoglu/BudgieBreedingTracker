import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_database_backup_utils.dart';

void main() {
  group('protectedTables', () {
    test('contains expected protected table names', () {
      expect(protectedTables, contains('admin_users'));
      expect(protectedTables, contains('admin_logs'));
      expect(protectedTables, contains('system_settings'));
      expect(protectedTables, contains('system_status'));
      expect(protectedTables, contains('subscription_plans'));
      expect(protectedTables, contains('profiles'));
    });

    test('has exactly 6 entries', () {
      expect(protectedTables.length, 6);
    });

    test('does not contain regular entity tables', () {
      expect(protectedTables, isNot(contains('birds')));
      expect(protectedTables, isNot(contains('eggs')));
      expect(protectedTables, isNot(contains('chicks')));
    });
  });
}
