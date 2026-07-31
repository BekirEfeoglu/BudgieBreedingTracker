import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';

void main() {
  test('v29 upgrade reconciles chick links and creates v30 indexes', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'budgie-v30-migration-',
    );
    final file = File('${tempDir.path}/legacy.sqlite');

    final currentDb = AppDatabase.forTesting(NativeDatabase(file));
    await currentDb.customStatement('''
      INSERT INTO eggs (
        id, lay_date, user_id, status, is_deleted
      ) VALUES (
        'egg-1', 0, 'user-1', 'hatched', 0
      )
    ''');
    await currentDb.close();

    final legacyExecutor = NativeDatabase(
      file,
      setup: (raw) {
        raw.execute('DROP INDEX idx_chicks_active_egg_unique');
        raw.execute('DROP INDEX idx_events_user_deleted_date');
        raw.execute('''
          INSERT INTO chicks (
            id, user_id, gender, health_status, egg_id, is_deleted
          ) VALUES
            ('chick-1', 'user-1', 'unknown', 'healthy', 'egg-1', 0),
            ('chick-2', 'user-1', 'unknown', 'healthy', 'egg-1', 0),
            ('chick-deleted', 'user-1', 'unknown', 'healthy', 'egg-1', 1)
        ''');
        raw.execute('PRAGMA user_version = 29');
      },
    );
    final db = AppDatabase.forTesting(legacyExecutor);

    try {
      final rows = await db
          .customSelect(
            'SELECT id, egg_id, is_deleted FROM chicks ORDER BY rowid',
          )
          .get();
      final indexes = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final indexNames = indexes.map((row) => row.read<String>('name')).toSet();

      expect(db.schemaVersion, 30);
      expect(rows, hasLength(3));
      expect(rows[0].readNullable<String>('egg_id'), 'egg-1');
      expect(rows[1].readNullable<String>('egg_id'), isNull);
      expect(rows[2].readNullable<String>('egg_id'), 'egg-1');
      expect(
        indexNames,
        containsAll({
          'idx_chicks_active_egg_unique',
          'idx_events_user_deleted_date',
        }),
      );

      await expectLater(
        db.customStatement('''
          INSERT INTO chicks (
            id, user_id, gender, health_status, egg_id, is_deleted
          ) VALUES (
            'chick-3', 'user-1', 'unknown', 'healthy', 'egg-1', 0
          )
        '''),
        throwsA(anything),
      );
    } finally {
      await db.close();
      await tempDir.delete(recursive: true);
    }
  });
}
