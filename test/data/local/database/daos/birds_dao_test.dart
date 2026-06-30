import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

const _encryptionKeyName = 'budgie_encryption_key';
final _testKeyBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));
final _testBase64Key = base64Encode(_testKeyBytes);

void main() {
  late AppDatabase db;
  late BirdsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  Bird makeBird({
    String id = 'bird-1',
    String name = 'Test Bird',
    String user = userId,
    BirdGender gender = BirdGender.male,
    BirdStatus status = BirdStatus.alive,
    Species species = Species.budgie,
    String? ringNumber,
    String? fatherId,
    String? motherId,
    DateTime? birthDate,
    DateTime? deathDate,
    DateTime? soldDate,
    String? notes,
    Map<String, String>? genotypeInfo,
    bool isDeleted = false,
    DateTime? createdAt,
  }) {
    return Bird(
      id: id,
      name: name,
      userId: user,
      gender: gender,
      status: status,
      species: species,
      ringNumber: ringNumber,
      fatherId: fatherId,
      motherId: motherId,
      birthDate: birthDate,
      deathDate: deathDate,
      soldDate: soldDate,
      notes: notes,
      genotypeInfo: genotypeInfo,
      isDeleted: isDeleted,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Insert a minimal parent bird row to satisfy self-referencing FK constraints.
  /// Uses a dedicated userId so these rows don't interfere with test counts.
  Future<void> insertParentBird(String id) async {
    await db.customStatement(
      'INSERT OR IGNORE INTO birds (id, name, gender, user_id, status, species, is_deleted) '
      "VALUES ('$id', 'Parent', 'male', 'fk-parent-user', 'alive', 'budgie', 0)",
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.birdsDao;
    // Pre-create parent birds for self-referencing FK (fatherId, motherId).
    // Use a separate userId so they don't affect count/getAll assertions.
    await insertParentBird('father-id');
    await insertParentBird('mother-id');
  });

  tearDown(() async {
    await db.close();
  });

  group('insertItem', () {
    test('inserts and retrieves a single bird', () async {
      final bird = makeBird(name: 'Mavi');
      await dao.insertItem(bird);

      final result = await dao.getById('bird-1');
      expect(result, isNotNull);
      expect(result!.id, equals('bird-1'));
      expect(result.name, equals('Mavi'));
      expect(result.gender, equals(BirdGender.male));
    });

    test('upserts on conflict — updates existing record', () async {
      await dao.insertItem(makeBird(status: BirdStatus.alive));
      await dao.insertItem(makeBird(status: BirdStatus.dead));

      final result = await dao.getById('bird-1');
      expect(result!.status, equals(BirdStatus.dead));
    });

    test('persists optional fields correctly', () async {
      // Use UTC DateTime explicitly — mappers normalize all DateTime fields to
      // UTC on read so that Supabase push serializes with a Z suffix and
      // TIMESTAMPTZ interprets the value as UTC (not the server's local TZ).
      final birthDate = DateTime.utc(2023, 6, 15);
      final bird = makeBird(
        ringNumber: 'A-123',
        fatherId: 'father-id',
        motherId: 'mother-id',
        birthDate: birthDate,
      );
      await dao.insertItem(bird);

      final result = await dao.getById('bird-1');
      expect(result!.ringNumber, equals('A-123'));
      expect(result.fatherId, equals('father-id'));
      expect(result.motherId, equals('mother-id'));
      expect(result.birthDate, equals(birthDate));
    });
  });

  group('insertAll', () {
    test('inserts multiple birds in batch', () async {
      final birds = List.generate(
        5,
        (i) => makeBird(id: 'bird-${i + 1}', name: 'Bird ${i + 1}'),
      );
      await dao.insertAll(birds);

      final all = await dao.getAll(userId);
      expect(all.length, equals(5));
    });

    test('empty list completes without error', () async {
      await dao.insertAll([]);

      final all = await dao.getAll(userId);
      expect(all, isEmpty);
    });
  });

  group('watchAll', () {
    test('returns non-deleted birds for user', () async {
      await dao.insertItem(makeBird(id: 'b1'));
      await dao.insertItem(makeBird(id: 'b2', isDeleted: true));
      await dao.insertItem(makeBird(id: 'b3', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('b1'));
    });

    test('emits empty list when no birds exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('orders results by createdAt descending', () async {
      await dao.insertItem(makeBird(id: 'b1', createdAt: DateTime(2024, 1, 1)));
      await dao.insertItem(makeBird(id: 'b2', createdAt: DateTime(2024, 1, 3)));
      await dao.insertItem(makeBird(id: 'b3', createdAt: DateTime(2024, 1, 2)));

      final results = await dao.watchAll(userId).first;
      expect(results.map((b) => b.id).toList(), equals(['b2', 'b3', 'b1']));
    });

    test('emits updated list after insertion', () async {
      final stream = dao.watchAll(userId);

      final first = await stream.first;
      expect(first, isEmpty);

      await dao.insertItem(makeBird(id: 'b1'));
      final second = await stream.first;
      expect(second.length, equals(1));
    });
  });

  group('watchById', () {
    test('emits the bird when found', () async {
      await dao.insertItem(makeBird(name: 'Sarı'));

      final result = await dao.watchById('bird-1').first;
      expect(result, isNotNull);
      expect(result!.name, equals('Sarı'));
    });

    test('emits null for non-existent id', () async {
      final result = await dao.watchById('nonexistent').first;
      expect(result, isNull);
    });

    test('filters out soft-deleted birds', () async {
      await dao.insertItem(makeBird(isDeleted: true));
      final result = await dao.watchById('bird-1').first;
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('excludes soft-deleted birds', () async {
      await dao.insertItem(makeBird(id: 'b1'));
      await dao.insertItem(makeBird(id: 'b2', isDeleted: true));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('b1'));
    });

    test('scoped by userId', () async {
      await dao.insertItem(makeBird(id: 'b1', user: userId));
      await dao.insertItem(makeBird(id: 'b2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no birds match', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns bird for existing id', () async {
      await dao.insertItem(makeBird());
      final result = await dao.getById('bird-1');
      expect(result, isNotNull);
      expect(result!.id, equals('bird-1'));
    });

    test('returns null for non-existent id', () async {
      final result = await dao.getById('nonexistent');
      expect(result, isNull);
    });
  });

  group('updateItem', () {
    test('updates existing bird fields', () async {
      await dao.insertItem(makeBird(name: 'Old Name'));
      final updated = makeBird(name: 'New Name', status: BirdStatus.sold);
      await dao.updateItem(updated);

      final result = await dao.getById('bird-1');
      expect(result!.name, equals('New Name'));
      expect(result.status, equals(BirdStatus.sold));
    });
  });

  group('softDelete', () {
    test('hides bird from watchAll and getAll', () async {
      await dao.insertItem(makeBird());
      await dao.softDelete('bird-1');

      final all = await dao.getAll(userId);
      expect(all, isEmpty);

      final watched = await dao.watchAll(userId).first;
      expect(watched, isEmpty);
    });

    test('soft-deleted bird is excluded from getById', () async {
      await dao.insertItem(makeBird());
      await dao.softDelete('bird-1');

      final result = await dao.getById('bird-1');
      expect(result, isNull);

      final deleted = await dao.getDeleted(userId);
      expect(
        deleted.any((b) => b.id == 'bird-1' && b.isDeleted == true),
        isTrue,
      );
    });
  });

  group('hardDelete', () {
    test('permanently removes the bird', () async {
      await dao.insertItem(makeBird());
      await dao.hardDelete('bird-1');

      final result = await dao.getById('bird-1');
      expect(result, isNull);
    });
  });

  group('getByGender', () {
    test('returns male birds', () async {
      await dao.insertItem(makeBird(id: 'b1', gender: BirdGender.male));
      await dao.insertItem(makeBird(id: 'b2', gender: BirdGender.female));
      await dao.insertItem(makeBird(id: 'b3', gender: BirdGender.unknown));

      final males = await dao.getByGender(userId, BirdGender.male);
      expect(males.length, equals(1));
      expect(males.first.id, equals('b1'));
    });

    test('returns female birds', () async {
      await dao.insertItem(makeBird(id: 'b1', gender: BirdGender.female));
      await dao.insertItem(makeBird(id: 'b2', gender: BirdGender.male));

      final females = await dao.getByGender(userId, BirdGender.female);
      expect(females.length, equals(1));
      expect(females.first.id, equals('b1'));
    });

    test('excludes soft-deleted birds', () async {
      await dao.insertItem(makeBird(id: 'b1', gender: BirdGender.male));
      await dao.insertItem(
        makeBird(id: 'b2', gender: BirdGender.male, isDeleted: true),
      );

      final males = await dao.getByGender(userId, BirdGender.male);
      expect(males.length, equals(1));
    });

    test('scoped by userId', () async {
      await dao.insertItem(
        makeBird(id: 'b1', user: userId, gender: BirdGender.male),
      );
      await dao.insertItem(
        makeBird(id: 'b2', user: otherId, gender: BirdGender.male),
      );

      final males = await dao.getByGender(userId, BirdGender.male);
      expect(males.length, equals(1));
    });

    test('returns empty list when no birds of that gender', () async {
      await dao.insertItem(makeBird(id: 'b1', gender: BirdGender.female));

      final males = await dao.getByGender(userId, BirdGender.male);
      expect(males, isEmpty);
    });
  });

  group('watchCount', () {
    test('returns correct count of non-deleted birds', () async {
      await dao.insertItem(makeBird(id: 'b1'));
      await dao.insertItem(makeBird(id: 'b2'));
      await dao.insertItem(makeBird(id: 'b3', isDeleted: true));

      final count = await dao.watchCount(userId).first;
      expect(count, equals(2));
    });

    test('scoped by userId', () async {
      await dao.insertItem(makeBird(id: 'b1', user: userId));
      await dao.insertItem(makeBird(id: 'b2', user: otherId));

      final count = await dao.watchCount(userId).first;
      expect(count, equals(1));
    });

    test('returns 0 when no birds exist', () async {
      final count = await dao.watchCount(userId).first;
      expect(count, equals(0));
    });

    test('updates reactively after insert', () async {
      final stream = dao.watchCount(userId);

      final first = await stream.first;
      expect(first, equals(0));

      await dao.insertItem(makeBird(id: 'b1'));
      final second = await stream.first;
      expect(second, equals(1));
    });
  });

  group('getDeleted', () {
    test('returns only soft-deleted birds', () async {
      await dao.insertItem(makeBird(id: 'b1'));
      await dao.insertItem(makeBird(id: 'b2', isDeleted: true));
      await dao.insertItem(makeBird(id: 'b3', isDeleted: true));

      final deleted = await dao.getDeleted(userId);
      expect(deleted.length, equals(2));
      expect(deleted.map((b) => b.id).toSet(), containsAll(['b2', 'b3']));
    });

    test('scoped by userId', () async {
      await dao.insertItem(makeBird(id: 'b1', user: userId, isDeleted: true));
      await dao.insertItem(makeBird(id: 'b2', user: otherId, isDeleted: true));

      final deleted = await dao.getDeleted(userId);
      expect(deleted.length, equals(1));
    });

    test('returns empty list when no deleted birds', () async {
      await dao.insertItem(makeBird(id: 'b1'));

      final deleted = await dao.getDeleted(userId);
      expect(deleted, isEmpty);
    });
  });

  group('sensitive field encryption', () {
    late MockFlutterSecureStorage mockStorage;
    late EncryptionService encryptionService;
    late ProviderContainer container;
    late BirdsDao encryptedDao;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      when(
        () => mockStorage.read(key: _encryptionKeyName),
      ).thenAnswer((_) async => _testBase64Key);
      when(
        () => mockStorage.read(key: 'budgie_encryption_key_version'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      encryptionService = EncryptionService(mockStorage);
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          encryptionServiceProvider.overrideWithValue(encryptionService),
        ],
      );
      encryptedDao = container.read(birdsDaoProvider);
    });

    tearDown(() {
      container.dispose();
      encryptionService.dispose();
    });

    test('stores sensitive bird fields encrypted at rest', () async {
      final bird = makeBird(
        id: 'bird-secret',
        ringNumber: 'TR-2026-001',
        notes: 'Private health note',
        genotypeInfo: const {'blue': 'visual'},
      );

      await encryptedDao.insertItem(bird);

      final raw = await db
          .customSelect(
            'SELECT ring_number, notes, genotype_info FROM birds WHERE id = ?',
            variables: [Variable.withString('bird-secret')],
          )
          .getSingle();
      final rawRingNumber = raw.read<String>('ring_number');
      final rawNotes = raw.read<String>('notes');
      final rawGenotypeInfo = raw.read<String>('genotype_info');

      expect(rawRingNumber, isNot('TR-2026-001'));
      expect(rawNotes, isNot('Private health note'));
      expect(rawGenotypeInfo, isNot(jsonEncode({'blue': 'visual'})));
      expect(looksLikeEncrypted(rawRingNumber), isTrue);
      expect(looksLikeEncrypted(rawNotes), isTrue);
      expect(looksLikeEncrypted(rawGenotypeInfo), isTrue);

      final result = await encryptedDao.getById('bird-secret');
      expect(result!.ringNumber, 'TR-2026-001');
      expect(result.notes, 'Private health note');
      expect(result.genotypeInfo, {'blue': 'visual'});
    });

    test(
      'blanks a field instead of returning corrupted ciphertext as '
      'plaintext when decryption fails',
      () async {
        await encryptedDao.insertItem(
          makeBird(id: 'bird-corrupt', ringNumber: 'TR-001'),
        );

        // Overwrite the encrypted column with garbage that still satisfies
        // looksLikeEncrypted's heuristic (valid base64, >=17 bytes) but
        // isn't real ciphertext — simulates corruption/tampering/wrong key.
        final garbage = base64Encode(List<int>.generate(32, (i) => i));
        await db.customUpdate(
          'UPDATE birds SET ring_number = ? WHERE id = ?',
          variables: [
            Variable.withString(garbage),
            Variable.withString('bird-corrupt'),
          ],
        );

        final result = await encryptedDao.getById('bird-corrupt');

        expect(result, isNotNull);
        // Must never surface the raw ciphertext as if it were the value —
        // see encryption.md: "asla bozuk plaintext döndürme".
        expect(result!.ringNumber, isNot(garbage));
        expect(result.ringNumber, isNull);
      },
    );

    test('matches ring number uniqueness against encrypted values', () async {
      await encryptedDao.insertItem(
        makeBird(id: 'bird-secret', ringNumber: 'TR-2026-002'),
      );

      expect(await encryptedDao.hasRingNumber(userId, 'TR-2026-002'), isTrue);
      expect(await encryptedDao.hasRingNumber(userId, 'TR-2026-999'), isFalse);
    });
  });

  group('updateRingNumber', () {
    test('updates only ringNumber and updatedAt', () async {
      await dao.insertItem(
        makeBird(id: 'b1', name: 'Original', ringNumber: 'OLD-001'),
      );

      await dao.updateRingNumber('b1', 'NEW-ENCRYPTED-VALUE');

      final bird = await dao.getById('b1');
      expect(bird, isNotNull);
      expect(bird!.ringNumber, 'NEW-ENCRYPTED-VALUE');
      expect(bird.name, 'Original'); // other fields untouched
    });

    test('sets ringNumber on bird that had none', () async {
      await dao.insertItem(makeBird(id: 'b2'));

      await dao.updateRingNumber('b2', 'ENCRYPTED-RING');

      final bird = await dao.getById('b2');
      expect(bird!.ringNumber, 'ENCRYPTED-RING');
    });
  });

  group('getWithRingNumber', () {
    test('returns only birds with non-null ring numbers', () async {
      await dao.insertItem(makeBird(id: 'b1', ringNumber: 'TR-001'));
      await dao.insertItem(makeBird(id: 'b2')); // no ring number
      await dao.insertItem(makeBird(id: 'b3', ringNumber: 'TR-002'));

      final results = await dao.getWithRingNumber(userId);
      expect(results.length, 2);
      expect(results.map((b) => b.id).toSet(), {'b1', 'b3'});
    });

    test('excludes soft-deleted birds', () async {
      await dao.insertItem(
        makeBird(id: 'b1', ringNumber: 'TR-001', isDeleted: true),
      );
      await dao.insertItem(makeBird(id: 'b2', ringNumber: 'TR-002'));

      final results = await dao.getWithRingNumber(userId);
      expect(results.length, 1);
      expect(results.first.id, 'b2');
    });

    test('scoped by userId', () async {
      await dao.insertItem(makeBird(id: 'b1', ringNumber: 'TR-001'));
      await dao.insertItem(
        makeBird(id: 'b2', user: otherId, ringNumber: 'TR-002'),
      );

      final results = await dao.getWithRingNumber(userId);
      expect(results.length, 1);
      expect(results.first.id, 'b1');
    });

    test('returns empty list when no birds have ring numbers', () async {
      await dao.insertItem(makeBird(id: 'b1'));
      await dao.insertItem(makeBird(id: 'b2'));

      final results = await dao.getWithRingNumber(userId);
      expect(results, isEmpty);
    });
  });
}
