import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';

void main() {
  test('schema creates hot-path composite indexes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // schemaVersion bumps with most migration commits; assert the
    // floor instead of a literal so this test doesn't break on every
    // schema change unrelated to the indexes themselves.
    expect(db.schemaVersion, greaterThanOrEqualTo(23));

    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final indexNames = rows.map((row) => row.data['name'] as String).toSet();

    expect(
      indexNames,
      containsAll({
        'idx_eggs_incubation_status_deleted',
        'idx_chicks_egg_deleted',
        'idx_health_records_bird_deleted',
        'idx_events_bird_deleted',
        'idx_clutches_breeding_deleted',
        'idx_incubations_breeding_pair_status',
        'idx_notifications_user_read',
        'idx_photos_entity_user',
        'idx_growth_measurements_chick_date',
      }),
    );
  });

  test('hot-path egg query stays within performance budget', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    const query = '''
SELECT id
FROM eggs
WHERE incubation_id = ?
  AND status = ?
  AND is_deleted = 0
''';
    final variables = [
      Variable.withString('incubation-1'),
      Variable.withString('incubating'),
    ];

    await db.customSelect(query, variables: variables).get();
    final stopwatch = Stopwatch()..start();
    final rows = await db.customSelect(query, variables: variables).get();
    stopwatch.stop();

    expect(rows, isEmpty);
    expect(stopwatch.elapsedMilliseconds, lessThan(20));

    final planRows = await db
        .customSelect('EXPLAIN QUERY PLAN $query', variables: variables)
        .get();
    final plan = planRows
        .map((row) => row.data.values.map((value) => '$value').join(' '))
        .join('\n');

    expect(plan, contains('idx_eggs_incubation_status_deleted'));
  });
}
