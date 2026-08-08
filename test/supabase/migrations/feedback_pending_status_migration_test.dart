import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feedback status migration aligns pending with the admin RPC contract', () {
    final sql = File(
      'supabase/migrations/'
      '20260808173000_align_feedback_pending_status.sql',
    ).readAsStringSync();

    expect(sql, contains("SET status = 'pending'"));
    expect(sql, contains("WHERE status = 'in_progress'"));
    expect(sql, contains('DROP CONSTRAINT IF EXISTS feedback_status_check'));
    expect(
      sql,
      contains(
        "CHECK (status IN ('open', 'pending', 'resolved', 'closed', 'wont_fix'))",
      ),
    );
  });
}
