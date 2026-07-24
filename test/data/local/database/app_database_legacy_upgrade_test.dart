import 'dart:io';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Upgrade regressions for install bases that skipped many releases.
///
/// A failing statement anywhere in `onUpgrade` aborts the whole transaction,
/// which means the database never opens and the app is unusable on that device
/// with no in-app recovery. Both cases below are therefore "does it open at
/// all" tests first and schema assertions second.
///
///  * **v8** — `_createPerformanceIndexes` runs from the v8->v9 step but also
///    indexes `conflict_history`, which is only created in v15->v16.
///    `CREATE INDEX IF NOT EXISTS` guards the index NAME, not a missing table,
///    so this threw `no such table: conflict_history` and bricked the upgrade.
///    Regression for the `_tableExists` guard.
///  * **v21** — `_migrateV21ToV22` rebuilds tables via `Migrator.alterTable`,
///    which copies from the old table. This case was audited as a suspected
///    second instance of the same trap (columns added in v24/v27/v28 being read
///    from a v21-era table) and did NOT reproduce — it is kept as a guard so a
///    future change to that step cannot silently introduce it.
///
/// A faithful legacy fixture is built by materializing the current schema and
/// removing exactly what was introduced after the simulated version, then
/// stamping `PRAGMA user_version`. `assertAbsentColumns` guards the fixture
/// itself so an ineffective downgrade cannot make these tests vacuous.
void main() {
  Future<T> withLegacyDatabase<T>(
    String label,
    int userVersion,
    List<String> downgradeStatements,
    Future<T> Function(AppDatabase db) body, {
    Map<String, List<String>> assertAbsentColumns = const {},
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('budgie-$label-');
    final file = File('${tempDir.path}/legacy.sqlite');

    // Materialize the current schema first, then strip it back down.
    final seed = AppDatabase.forTesting(NativeDatabase(file));
    await seed.customSelect('SELECT 1').get();
    for (final statement in downgradeStatements) {
      await seed.customStatement(statement);
    }
    // Guard the fixture itself: a silently-ineffective downgrade would make
    // this test pass without ever exercising the legacy upgrade path.
    for (final entry in assertAbsentColumns.entries) {
      final rows = await seed
          .customSelect('PRAGMA table_info(${entry.key})')
          .get();
      final present = rows.map((row) => row.read<String>('name')).toSet();
      for (final column in entry.value) {
        expect(
          present,
          isNot(contains(column)),
          reason:
              'fixture for $label did not remove ${entry.key}.$column, so the '
              'upgrade path under test was never exercised',
        );
      }
    }
    await seed.customStatement('PRAGMA user_version = $userVersion');
    await seed.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      return await body(db);
    } finally {
      await db.close();
      await tempDir.delete(recursive: true);
    }
  }

  Future<Set<String>> indexNames(AppDatabase db) async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  Future<Set<String>> columnNames(AppDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  test('upgrade from schema v8 completes without conflict_history', () async {
    // conflict_history is created in v15->v16, so a v8 database has no such
    // table when _createPerformanceIndexes runs in the v8->v9 step.
    await withLegacyDatabase(
      'v8-upgrade',
      8,
      const [
        'DROP TABLE IF EXISTS conflict_history',
        // Everything the v9..v17 steps add *without* a _tableHasColumn guard: a
        // v8 fixture must not already carry these or the upgrade re-adds them.
        'ALTER TABLE notification_settings DROP COLUMN cleanup_days_old', // v13
        'ALTER TABLE notification_settings DROP COLUMN banding_enabled', // v17
        'ALTER TABLE chicks DROP COLUMN banding_day', // v15
        'ALTER TABLE chicks DROP COLUMN banding_date', // v15
        'ALTER TABLE events DROP COLUMN chick_id', // v15
      ],
      assertAbsentColumns: const {
        'chicks': ['banding_day', 'banding_date'],
        'events': ['chick_id'],
      },
      (db) async {
        expect(db.schemaVersion, 29);

        // Opening at all is the assertion: an unguarded CREATE INDEX against the
        // missing table aborts onUpgrade and this query never runs.
        final tables = await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get();
        expect(
          tables.map((row) => row.read<String>('name')),
          contains('conflict_history'),
        );

        // The composite index must still be present afterwards: the shared helper
        // skips it while the table is missing, so the v15->v16 step is what
        // installs it for this upgrade path.
        expect(
          await indexNames(db),
          contains('idx_conflict_history_user_table_record'),
        );
      },
    );
  });

  test(
    'upgrade from schema v21 rebuilds tables without later columns',
    () async {
      // Columns introduced after v21 must not be read from the v21-era tables
      // that _migrateV21ToV22 copies from.
      await withLegacyDatabase(
        'v21-upgrade',
        21,
        const [
          'DROP INDEX IF EXISTS idx_health_records_chick',
          'DROP INDEX IF EXISTS idx_health_records_chick_deleted',
          'DROP INDEX IF EXISTS idx_events_egg_id',
          'DROP INDEX IF EXISTS idx_events_incubation_id',
          // v26->v27
          'ALTER TABLE health_records DROP COLUMN chick_id',
          // v23->v24
          'ALTER TABLE events DROP COLUMN egg_id',
          'ALTER TABLE events DROP COLUMN incubation_id',
          // v27->v28
          'ALTER TABLE genetics_history DROP COLUMN father_phase_overrides',
          // v28->v29
          'ALTER TABLE conflict_history DROP COLUMN local_payload',
          'ALTER TABLE conflict_history DROP COLUMN server_payload',
          'ALTER TABLE conflict_history DROP COLUMN payload_version',
        ],
        assertAbsentColumns: const {
          'health_records': ['chick_id'],
          'events': ['egg_id', 'incubation_id'],
          'genetics_history': ['father_phase_overrides'],
          'conflict_history': [
            'local_payload',
            'server_payload',
            'payload_version',
          ],
        },
        (db) async {
          expect(db.schemaVersion, 29);

          // Every post-v21 column must be back after the upgrade chain.
          expect(await columnNames(db, 'health_records'), contains('chick_id'));
          expect(
            await columnNames(db, 'events'),
            containsAll(['egg_id', 'incubation_id']),
          );
          expect(
            await columnNames(db, 'genetics_history'),
            contains('father_phase_overrides'),
          );
          expect(
            await columnNames(db, 'conflict_history'),
            containsAll(['local_payload', 'server_payload', 'payload_version']),
          );
        },
      );
    },
  );
}
