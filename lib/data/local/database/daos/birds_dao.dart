import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/birds_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/bird_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

part 'birds_dao.g.dart';

@DriftAccessor(tables: [BirdsTable])
class BirdsDao extends DatabaseAccessor<AppDatabase> with _$BirdsDaoMixin {
  BirdsDao(super.db, [this._encryptionService]);

  final EncryptionService? _encryptionService;

  Stream<List<Bird>> watchAll(String userId) {
    return (select(birdsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .asyncMap(_rowsToModels);
  }

  Stream<Bird?> watchById(String id) {
    return (select(birdsTable)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .watchSingleOrNull()
        .asyncMap((row) => row == null ? null : _rowToModel(row));
  }

  Future<List<Bird>> getAll(String userId) async {
    final rows = await (select(
      birdsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return _rowsToModels(rows);
  }

  Future<Bird?> getById(String id) async {
    final row =
        await (select(birdsTable)
              ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
            .getSingleOrNull();
    return row == null ? null : _rowToModel(row);
  }

  Future<void> insertItem(Bird model) async {
    await into(
      birdsTable,
    ).insertOnConflictUpdate(await _encryptedCompanion(model));
  }

  Future<void> insertAll(List<Bird> models) async {
    final companions = <BirdsTableCompanion>[];
    for (final model in models) {
      companions.add(await _encryptedCompanion(model));
    }
    return batch((b) {
      b.insertAllOnConflictUpdate(birdsTable, companions);
    });
  }

  Future<void> updateItem(Bird model) async {
    await update(birdsTable).replace(await _encryptedCompanion(model));
  }

  Future<void> softDelete(String id) {
    return (update(birdsTable)..where((t) => t.id.equals(id))).write(
      BirdsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(birdsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Bird>> getByGender(String userId, BirdGender gender) async {
    final rows =
        await (select(birdsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.gender.equalsValue(gender) &
                  t.isDeleted.equals(false),
            ))
            .get();
    return _rowsToModels(rows);
  }

  /// Reactive count of all non-deleted birds for a user (lightweight).
  Stream<int> watchCount(String userId) {
    final count = birdsTable.id.count();
    return (selectOnly(birdsTable)
          ..addColumns([count])
          ..where(
            birdsTable.userId.equals(userId) &
                birdsTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Returns the count of non-deleted birds for a user (lightweight — no row mapping).
  Future<int> getCount(String userId) async {
    final count = birdsTable.id.count();
    final row =
        await (selectOnly(birdsTable)
              ..addColumns([count])
              ..where(
                birdsTable.userId.equals(userId) &
                    birdsTable.isDeleted.equals(false),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<Bird>> getDeleted(String userId) async {
    final rows = await (select(
      birdsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(true))).get();
    return _rowsToModels(rows);
  }

  /// Returns only birds that have a non-null ring number (lightweight).
  ///
  /// Used by the encryption migration pipeline to avoid fetching all
  /// birds when only those with encrypted ring numbers are needed.
  Future<List<Bird>> getWithRingNumber(String userId) async {
    final rows =
        await (select(birdsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.isDeleted.equals(false) &
                  t.ringNumber.isNotNull(),
            ))
            .get();
    return _rowsToModels(rows);
  }

  /// Returns raw encrypted ring-number payloads for migration/audit code.
  Future<Map<String, String>> getRawEncryptedRingNumbers(String userId) async {
    final rows =
        await (select(birdsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.isDeleted.equals(false) &
                  t.ringNumber.isNotNull(),
            ))
            .get();

    final result = <String, String>{};
    for (final row in rows) {
      final value = row.ringNumber;
      if (value != null && looksLikeEncrypted(value)) {
        result[row.id] = value;
      }
    }
    return result;
  }

  /// Encrypts existing plaintext sensitive bird fields in place.
  Future<int> migratePlaintextSensitiveFields(String userId) async {
    if (_encryptionService == null) return 0;

    final rows = await (select(
      birdsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();

    var migrated = 0;
    for (final row in rows) {
      final ringNumber = await _encryptPlaintextOnly(row.ringNumber);
      final notes = await _encryptPlaintextOnly(row.notes);
      final genotypeInfo = await _encryptPlaintextOnly(row.genotypeInfo);

      if (ringNumber == row.ringNumber &&
          notes == row.notes &&
          genotypeInfo == row.genotypeInfo) {
        continue;
      }

      await (update(birdsTable)..where((t) => t.id.equals(row.id))).write(
        BirdsTableCompanion(
          ringNumber: Value(ringNumber),
          notes: Value(notes),
          genotypeInfo: Value(genotypeInfo),
          updatedAt: Value(DateTime.now()),
        ),
      );
      migrated++;
    }
    return migrated;
  }

  /// Updates the encrypted ring number for a single bird.
  ///
  /// Used by the encryption migration pipeline to upgrade legacy
  /// payloads to the current authenticated format without touching
  /// other fields or triggering a full model save.
  Future<void> updateRingNumber(String id, String ringNumber) {
    return (update(birdsTable)..where((t) => t.id.equals(id))).write(
      BirdsTableCompanion(
        ringNumber: Value(ringNumber),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Watches gender distribution for statistics (SQL aggregate — no row mapping).
  Stream<Map<BirdGender, int>> watchGenderDistribution(String userId) {
    final query = customSelect(
      'SELECT gender, COUNT(*) AS cnt '
      'FROM birds WHERE user_id = ? AND is_deleted = 0 '
      'GROUP BY gender',
      variables: [Variable.withString(userId)],
      readsFrom: {birdsTable},
    );
    return query.watch().map((rows) {
      final result = <BirdGender, int>{};
      for (final row in rows) {
        final g = BirdGender.fromJson(row.read<String>('gender'));
        final c = row.read<int>('cnt');
        result[g] = c;
      }
      return result;
    });
  }

  /// Watches status distribution for statistics (SQL aggregate — no row mapping).
  Stream<Map<BirdStatus, int>> watchStatusDistribution(String userId) {
    final query = customSelect(
      'SELECT status, COUNT(*) AS cnt '
      'FROM birds WHERE user_id = ? AND is_deleted = 0 '
      'GROUP BY status',
      variables: [Variable.withString(userId)],
      readsFrom: {birdsTable},
    );
    return query.watch().map((rows) {
      final result = <BirdStatus, int>{};
      for (final row in rows) {
        final s = BirdStatus.fromJson(row.read<String>('status'));
        final c = row.read<int>('cnt');
        result[s] = c;
      }
      return result;
    });
  }

  /// Checks if a ring number already exists for a given user.
  ///
  /// When [excludeId] is provided the bird with that id is skipped
  /// (useful for update-form uniqueness validation).
  Future<bool> hasRingNumber(
    String userId,
    String ringNumber, {
    String? excludeId,
  }) async {
    if (_encryptionService != null) {
      final rows =
          await (select(birdsTable)..where((t) {
                var condition =
                    t.userId.equals(userId) &
                    t.ringNumber.isNotNull() &
                    t.isDeleted.equals(false);
                if (excludeId != null) {
                  condition = condition & t.id.equals(excludeId).not();
                }
                return condition;
              }))
              .get();

      for (final row in rows) {
        if (await _decryptSensitive(row.ringNumber) == ringNumber) {
          return true;
        }
      }
      return false;
    }

    final rows =
        await (select(birdsTable)
              ..where((t) {
                var condition =
                    t.userId.equals(userId) &
                    t.ringNumber.equals(ringNumber) &
                    t.isDeleted.equals(false);
                if (excludeId != null) {
                  condition = condition & t.id.equals(excludeId).not();
                }
                return condition;
              })
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  Future<List<Bird>> _rowsToModels(List<BirdRow> rows) async {
    final models = <Bird>[];
    for (final row in rows) {
      models.add(await _rowToModel(row));
    }
    return models;
  }

  Future<Bird> _rowToModel(BirdRow row) async {
    if (_encryptionService == null) return row.toModel();

    return row
        .copyWith(
          ringNumber: Value(await _decryptSensitive(row.ringNumber)),
          notes: Value(await _decryptSensitive(row.notes)),
          genotypeInfo: Value(await _decryptSensitive(row.genotypeInfo)),
        )
        .toModel();
  }

  Future<BirdsTableCompanion> _encryptedCompanion(Bird model) async {
    final companion = model.toCompanion();
    if (_encryptionService == null) return companion;

    return companion.copyWith(
      ringNumber: Value(await _encryptSensitive(companion.ringNumber.value)),
      notes: Value(await _encryptSensitive(companion.notes.value)),
      genotypeInfo: Value(
        await _encryptSensitive(companion.genotypeInfo.value),
      ),
    );
  }

  Future<String?> _encryptSensitive(String? value) async {
    if (value == null || value.isEmpty) {
      return value;
    }
    if (looksLikeEncrypted(value)) {
      try {
        await _encryptionService!.decrypt(value);
        return value;
      } catch (_) {
        // Base64-looking plaintext should still be encrypted at rest.
      }
    }
    return _encryptionService!.encrypt(value);
  }

  Future<String?> _encryptPlaintextOnly(String? value) async {
    if (value == null || value.isEmpty || looksLikeEncrypted(value)) {
      return value;
    }
    return _encryptionService!.encrypt(value);
  }

  Future<String?> _decryptSensitive(String? value) async {
    if (value == null || value.isEmpty || !looksLikeEncrypted(value)) {
      return value;
    }
    try {
      return await _encryptionService!.decrypt(value);
    } catch (_) {
      return value;
    }
  }
}
