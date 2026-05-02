import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase migration chain guards', () {
    test(
      'system settings policy uses an admin helper that exists at that point',
      () {
        final sql = File(
          'supabase/migrations/'
          '20260430130000_consolidate_system_select_policies.sql',
        ).readAsStringSync();

        expect(sql, isNot(contains('private.is_admin()')));
        expect(sql, contains('SELECT public.is_admin()'));
      },
    );

    test('admin_get_table_counts keeps the RPC return contract stable', () {
      final sql = File(
        'supabase/migrations/20260403140000_security_audit_fixes.sql',
      ).readAsStringSync();
      final functionBlock = _functionBlock(sql, 'admin_get_table_counts');

      expect(functionBlock, contains('RETURNS TABLE('));
      expect(functionBlock, contains('table_name text'));
      expect(functionBlock, contains('row_count bigint'));
      expect(functionBlock, isNot(contains('RETURNS json')));
    });

    test('pgaudit extension is moved out of public API exposure', () {
      final sql = File(
        'supabase/migrations/20260501180000_move_pgaudit_out_of_public.sql',
      ).readAsStringSync();

      expect(sql, contains('ALTER EXTENSION pgaudit SET SCHEMA extensions'));
      expect(sql, contains('REVOKE ALL ON FUNCTION'));
      expect(sql, contains('FROM PUBLIC, anon, authenticated'));
    });
  });
}

String _functionBlock(String sql, String name) {
  final start = sql.indexOf('CREATE OR REPLACE FUNCTION public.$name()');
  expect(start, isNonNegative);

  final nextFunction = sql.indexOf('\nCREATE OR REPLACE FUNCTION ', start + 1);
  if (nextFunction == -1) {
    return sql.substring(start);
  }
  return sql.substring(start, nextFunction);
}
