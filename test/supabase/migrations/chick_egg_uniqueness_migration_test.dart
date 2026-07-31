import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chick uniqueness migration preserves rows and adds partial index', () {
    final sql = File(
      'supabase/migrations/'
      '20260731120000_enforce_one_active_chick_per_egg.sql',
    ).readAsStringSync();

    expect(sql, contains('row_number() OVER'));
    expect(sql, contains('SET egg_id = NULL'));
    expect(sql, isNot(contains('DELETE FROM public.chicks')));
    expect(
      sql,
      contains(
        'CREATE UNIQUE INDEX IF NOT EXISTS '
        'idx_chicks_active_egg_unique',
      ),
    );
    expect(sql, contains('WHERE egg_id IS NOT NULL'));
    expect(sql, contains('AND is_deleted = false'));
  });
}
