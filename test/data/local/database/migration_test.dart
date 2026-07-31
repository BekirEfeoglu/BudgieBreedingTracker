import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';

/// Drift schema-consistency harness (schemaVersion 30).
///
/// The generated `drift_dev schema` verifier cannot be used for this schema:
/// its snapshot generator dartifies the `table_name` column (in `sync_metadata`
/// and `conflict_history`) to a field named `tableName`, which collides with
/// drift's inherited `Table.tableName` getter and fails to compile. So instead
/// of the generated cross-version verifier this suite asserts the invariants
/// that matter directly against a freshly-created database via `sqlite_master`
/// and `PRAGMA`.
///
/// It guards schema-definition drift at HEAD — most importantly the
/// `sync_metadata` uniqueness index behind the `saveAll` metadata-collision fix.
/// Historical per-version snapshots were never captured and cannot be
/// reconstructed, so cross-version data-migration tests are out of scope here.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> objectNames(String type) async {
    // Force the lazy open (onCreate) before reading the schema catalog.
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master WHERE type = ?1',
          variables: [Variable<String>(type)],
        )
        .get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  group('Drift schema at HEAD (v30)', () {
    test('schemaVersion is 30', () {
      expect(db.schemaVersion, 30);
    });

    test('onCreate materializes every registered table', () async {
      final physical = await objectNames('table');
      final registered = db.allTables
          .map((table) => table.actualTableName)
          .toSet();

      expect(registered, hasLength(20));
      for (final table in registered) {
        expect(
          physical,
          contains(table),
          reason: 'registered table "$table" was not created by onCreate',
        );
      }
      // Anchor a couple of names explicitly so a rename is caught, not just a
      // count change.
      expect(registered, containsAll(<String>['sync_metadata', 'birds']));
    });

    test(
      'sync_metadata carries the UNIQUE(table_name, record_id) index',
      () async {
        // This index is the invariant behind the saveAll metadata-collision
        // fix: SyncMetadataDao.insertAll dedups on the logical record because a
        // fresh primary key for an existing (table_name, record_id) would
        // otherwise violate it. Guard it so a schema edit cannot silently drop
        // the uniqueness and reintroduce the offline breeding/genealogy crash.
        final indexes = await objectNames('index');
        expect(indexes, contains('idx_sync_metadata_table_record_unique'));
      },
    );

    test('calendar range query has its compound index', () async {
      final indexes = await objectNames('index');
      expect(indexes, contains('idx_events_user_deleted_date'));
    });

    test('allows at most one active chick for an egg', () async {
      await db
          .into(db.eggsTable)
          .insert(
            EggsTableCompanion.insert(
              id: 'egg-1',
              layDate: DateTime.utc(2026, 7, 1),
              userId: 'user-1',
              status: EggStatus.hatched,
            ),
          );

      ChicksTableCompanion chick(String id, {bool isDeleted = false}) =>
          ChicksTableCompanion.insert(
            id: id,
            userId: 'user-1',
            gender: BirdGender.unknown,
            healthStatus: ChickHealthStatus.healthy,
            eggId: const Value('egg-1'),
            isDeleted: Value(isDeleted),
          );

      await db.into(db.chicksTable).insert(chick('chick-1'));

      await expectLater(
        db.into(db.chicksTable).insert(chick('chick-2')),
        throwsA(anything),
      );

      // Soft-deleted history is excluded from the partial unique index.
      await db
          .into(db.chicksTable)
          .insert(chick('chick-deleted', isDeleted: true));
    });

    test('beforeOpen enables foreign-key enforcement', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(row.data.values.first, 1);
    });
  });
}
