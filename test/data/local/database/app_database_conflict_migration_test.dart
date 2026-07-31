import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';

void main() {
  test(
    'v28 to v29 adds nullable payload columns without fake backfill',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'budgie-conflict-migration-',
      );
      final file = File('${tempDir.path}/legacy.sqlite');
      final executor = NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('''
          CREATE TABLE conflict_history (
            id TEXT NOT NULL PRIMARY KEY,
            user_id TEXT NOT NULL,
            table_name TEXT NOT NULL,
            record_id TEXT NOT NULL,
            description TEXT NOT NULL,
            conflict_type TEXT NOT NULL,
            resolved_at TEXT,
            created_at TEXT
          )
        ''');
          raw.execute('''
          INSERT INTO conflict_history (
            id, user_id, table_name, record_id, description, conflict_type
          ) VALUES (
            'legacy-1', 'user-1', 'birds', 'bird-1', 'Legacy', 'serverWins'
          )
        ''');
          raw.execute('PRAGMA user_version = 28');
        },
      );
      final db = AppDatabase.forTesting(executor);

      try {
        final legacy = await db.conflictHistoryDao.getById('legacy-1');
        final columns = await db
            .customSelect('PRAGMA table_info(conflict_history)')
            .get();
        final names = columns.map((row) => row.read<String>('name')).toSet();

        expect(db.schemaVersion, 30);
        expect(
          names,
          containsAll(['local_payload', 'server_payload', 'payload_version']),
        );
        expect(legacy, isNotNull);
        expect(legacy?.localPayload, isNull);
        expect(legacy?.serverPayload, isNull);
        expect(legacy?.payloadVersion, isNull);
      } finally {
        await db.close();
        await tempDir.delete(recursive: true);
      }
    },
  );
}
