import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';

void main() {
  test(
    'v25 upgrade adds health record chick indexes after the column exists',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'budgie-health-record-migration-',
      );
      final file = File('${tempDir.path}/legacy.sqlite');

      final currentDb = AppDatabase.forTesting(NativeDatabase(file));
      await currentDb.customStatement('''
        INSERT INTO health_records (
          id, date, type, title, user_id, is_deleted
        ) VALUES (
          'legacy-health-1', '2026-07-18T00:00:00.000Z', 'checkup',
          'Legacy checkup', 'user-1', 0
        )
      ''');
      await currentDb.close();

      final legacyExecutor = NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('PRAGMA foreign_keys = OFF');
          raw.execute(
            'ALTER TABLE health_records RENAME TO health_records_current',
          );
          raw.execute('''
            CREATE TABLE health_records (
              id TEXT NOT NULL PRIMARY KEY,
              date TEXT NOT NULL,
              type TEXT NOT NULL,
              title TEXT NOT NULL,
              user_id TEXT NOT NULL,
              bird_id TEXT REFERENCES birds (id),
              description TEXT,
              treatment TEXT,
              veterinarian TEXT,
              notes TEXT,
              weight REAL,
              cost REAL,
              follow_up_date TEXT,
              created_at TEXT,
              updated_at TEXT,
              is_deleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
          raw.execute('''
            INSERT INTO health_records (
              id, date, type, title, user_id, bird_id, description, treatment,
              veterinarian, notes, weight, cost, follow_up_date, created_at,
              updated_at, is_deleted
            )
            SELECT
              id, date, type, title, user_id, bird_id, description, treatment,
              veterinarian, notes, weight, cost, follow_up_date, created_at,
              updated_at, is_deleted
            FROM health_records_current
          ''');
          raw.execute('DROP TABLE health_records_current');
          raw.execute('PRAGMA user_version = 25');
        },
      );
      final db = AppDatabase.forTesting(legacyExecutor);

      try {
        final record = await db.healthRecordsDao.getById('legacy-health-1');
        final columns = await db
            .customSelect('PRAGMA table_info(health_records)')
            .get();
        final columnNames = columns
            .map((row) => row.read<String>('name'))
            .toSet();
        final indexes = await db
            .customSelect(
              "SELECT name FROM sqlite_master "
              "WHERE type = 'index' AND tbl_name = 'health_records'",
            )
            .get();
        final indexNames = indexes
            .map((row) => row.read<String>('name'))
            .toSet();

        expect(db.schemaVersion, 29);
        expect(record, isNotNull);
        expect(record?.chickId, isNull);
        expect(columnNames, contains('chick_id'));
        expect(
          indexNames,
          containsAll({
            'idx_health_records_chick',
            'idx_health_records_chick_deleted',
          }),
        );
      } finally {
        await db.close();
        await tempDir.delete(recursive: true);
      }
    },
  );
}
