import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_data_collector.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_restorer.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

import '../../../helpers/test_helpers.dart';

class _MockBirdRepository extends Mock implements BirdRepository {}

class _MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class _MockEggRepository extends Mock implements EggRepository {}

class _MockChickRepository extends Mock implements ChickRepository {}

class _MockHealthRecordRepository extends Mock
    implements HealthRecordRepository {}

class _MockEventRepository extends Mock implements EventRepository {}

class _MockIncubationRepository extends Mock implements IncubationRepository {}

class _MockGrowthMeasurementRepository extends Mock
    implements GrowthMeasurementRepository {}

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

class _MockClutchRepository extends Mock implements ClutchRepository {}

class _MockNestRepository extends Mock implements NestRepository {}

class _MockPhotoRepository extends Mock implements PhotoRepository {}

class _MockEncryptionService extends Mock implements EncryptionService {}

void main() {
  late _MockBirdRepository birdRepo;
  late _MockBreedingPairRepository breedingRepo;
  late _MockEggRepository eggRepo;
  late _MockChickRepository chickRepo;
  late _MockHealthRecordRepository healthRepo;
  late _MockEventRepository eventRepo;
  late _MockIncubationRepository incubationRepo;
  late _MockGrowthMeasurementRepository growthRepo;
  late _MockNotificationRepository notificationRepo;
  late _MockClutchRepository clutchRepo;
  late _MockNestRepository nestRepo;
  late _MockPhotoRepository photoRepo;
  late BackupRestorer restorer;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(<Bird>[]);
    registerFallbackValue(<BreedingPair>[]);
    registerFallbackValue(<Egg>[]);
    registerFallbackValue(<Chick>[]);
    registerFallbackValue(<HealthRecord>[]);
    registerFallbackValue(<Event>[]);
    registerFallbackValue(<Incubation>[]);
    registerFallbackValue(<GrowthMeasurement>[]);
    registerFallbackValue(<AppNotification>[]);
    registerFallbackValue(<Clutch>[]);
    registerFallbackValue(<Nest>[]);
    registerFallbackValue(<Photo>[]);
  });

  setUp(() async {
    birdRepo = _MockBirdRepository();
    breedingRepo = _MockBreedingPairRepository();
    eggRepo = _MockEggRepository();
    chickRepo = _MockChickRepository();
    healthRepo = _MockHealthRecordRepository();
    eventRepo = _MockEventRepository();
    incubationRepo = _MockIncubationRepository();
    growthRepo = _MockGrowthMeasurementRepository();
    notificationRepo = _MockNotificationRepository();
    clutchRepo = _MockClutchRepository();
    nestRepo = _MockNestRepository();
    photoRepo = _MockPhotoRepository();

    restorer = BackupRestorer(
      birdRepo: birdRepo,
      breedingRepo: breedingRepo,
      eggRepo: eggRepo,
      chickRepo: chickRepo,
      healthRepo: healthRepo,
      eventRepo: eventRepo,
      incubationRepo: incubationRepo,
      growthRepo: growthRepo,
      notificationRepo: notificationRepo,
      clutchRepo: clutchRepo,
      nestRepo: nestRepo,
      photoRepo: photoRepo,
    );

    tempDir = await Directory.systemTemp.createTemp('backup_restorer_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  void stubAllSaveAll() {
    when(() => birdRepo.saveAll(any<List<Bird>>())).thenAnswer((_) async {});
    when(
      () => breedingRepo.saveAll(any<List<BreedingPair>>()),
    ).thenAnswer((_) async {});
    when(() => eggRepo.saveAll(any<List<Egg>>())).thenAnswer((_) async {});
    when(() => chickRepo.saveAll(any<List<Chick>>())).thenAnswer((_) async {});
    when(
      () => healthRepo.saveAll(any<List<HealthRecord>>()),
    ).thenAnswer((_) async {});
    when(() => eventRepo.saveAll(any<List<Event>>())).thenAnswer((_) async {});
    when(
      () => incubationRepo.saveAll(any<List<Incubation>>()),
    ).thenAnswer((_) async {});
    when(
      () => growthRepo.saveAll(any<List<GrowthMeasurement>>()),
    ).thenAnswer((_) async {});
    when(
      () => notificationRepo.saveAll(any<List<AppNotification>>()),
    ).thenAnswer((_) async {});
    when(
      () => clutchRepo.saveAll(any<List<Clutch>>()),
    ).thenAnswer((_) async {});
    when(() => nestRepo.saveAll(any<List<Nest>>())).thenAnswer((_) async {});
    when(() => photoRepo.saveAll(any<List<Photo>>())).thenAnswer((_) async {});
  }

  Future<File> writeBackupFile(
    String fileName,
    Map<String, dynamic> content,
  ) async {
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonEncode(content));
    return file;
  }

  Future<File> writeRawFile(String fileName, String content) async {
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  group('BackupRestorer', () {
    group('restoreBackup', () {
      test('returns failure when backup file does not exist', () async {
        final result = await restorer.restoreBackup(
          'user-1',
          '${tempDir.path}/nonexistent.json',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Backup file not found'));
      });

      test('returns failure for unsupported backup version', () async {
        final file = await writeBackupFile('future.json', {
          'version': 99,
          'data': <String, dynamic>{},
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isFalse);
        expect(result.error, contains('Unsupported backup version: 99'));
      });

      test('returns failure when backup belongs to another user', () async {
        final file = await writeBackupFile('wrong_user.json', {
          'version': 2,
          'user_id': 'another-user',
          'data': <String, dynamic>{},
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isFalse);
        expect(result.error, contains('Backup belongs to another user'));
      });

      test('returns failure when version is null', () async {
        final file = await writeBackupFile('no_version.json', {
          'data': <String, dynamic>{},
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isFalse);
        expect(result.error, contains('Unsupported backup version: null'));
      });

      test('handles empty backup data gracefully', () async {
        final file = await writeBackupFile('empty.json', {
          'version': 2,
          'data': <String, dynamic>{},
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        expect(result.recordCount, 0);
        verifyNever(() => birdRepo.saveAll(any()));
        verifyNever(() => eggRepo.saveAll(any()));
      });

      test('handles empty entity lists without calling saveAll', () async {
        final file = await writeBackupFile('empty_lists.json', {
          'version': 2,
          'data': {'birds': <dynamic>[], 'eggs': <dynamic>[]},
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        expect(result.recordCount, 0);
        verifyNever(() => birdRepo.saveAll(any()));
        verifyNever(() => eggRepo.saveAll(any()));
      });

      test('restores birds and calls saveAll on bird repository', () async {
        stubAllSaveAll();
        final bird = createTestBird(
          id: 'bird-1',
          userId: 'user-1',
          name: 'Mavis',
        );

        final file = await writeBackupFile('birds.json', {
          'version': 2,
          'data': {
            'birds': [bird.toJson()],
          },
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        expect(result.recordCount, 1);
        final captured = verify(() => birdRepo.saveAll(captureAny())).captured;
        expect(captured.single, isA<List<Bird>>());
        final savedBirds = captured.single as List<Bird>;
        expect(savedBirds.length, 1);
        expect(savedBirds.first.id, 'bird-1');
        expect(savedBirds.first.name, 'Mavis');
      });

      test('normalizes entity user_id to active restore user', () async {
        stubAllSaveAll();
        final bird = createTestBird(
          id: 'bird-1',
          userId: 'legacy-user',
          name: 'Mavis',
        );

        final json = bird.toJson();
        json['user_id'] = 'legacy-user';

        final file = await writeBackupFile('normalize_user_scope.json', {
          'version': 2,
          'user_id': 'user-1',
          'data': {
            'birds': [json],
          },
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        final captured = verify(() => birdRepo.saveAll(captureAny())).captured;
        final savedBirds = captured.single as List<Bird>;
        expect(savedBirds.single.userId, 'user-1');
      });

      test('restores multiple entity types to correct repositories', () async {
        stubAllSaveAll();
        final bird = createTestBird(
          id: 'bird-1',
          userId: 'user-1',
          name: 'Mavis',
        );
        final bird2 = createTestBird(
          id: 'bird-2',
          userId: 'user-1',
          name: 'Sari',
        );

        final file = await writeBackupFile('multi.json', {
          'version': 2,
          'data': {
            'birds': [bird.toJson(), bird2.toJson()],
          },
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        expect(result.recordCount, 2);
        final captured = verify(() => birdRepo.saveAll(captureAny())).captured;
        final savedBirds = captured.single as List<Bird>;
        expect(savedBirds.length, 2);
      });

      test('skips malformed items and restores valid ones', () async {
        stubAllSaveAll();
        final validBird = createTestBird(
          id: 'bird-valid',
          userId: 'user-1',
          name: 'Valid',
        );

        final file = await writeBackupFile('mixed.json', {
          'version': 2,
          'data': {
            'birds': [
              validBird.toJson(),
              {'bad': 'data', 'missing': 'required_fields'},
            ],
          },
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        expect(result.recordCount, 1);
        final captured = verify(() => birdRepo.saveAll(captureAny())).captured;
        final savedBirds = captured.single as List<Bird>;
        expect(savedBirds.length, 1);
        expect(savedBirds.first.id, 'bird-valid');
      });

      test('handles corrupted JSON content gracefully', () async {
        final file = await writeRawFile('corrupted.json', '{not valid json');

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test(
        'does not call saveAll when all items in a key are malformed',
        () async {
          final file = await writeBackupFile('all_bad.json', {
            'version': 2,
            'data': {
              'birds': [
                {'garbage': true},
                {'also': 'garbage'},
              ],
            },
          });

          final result = await restorer.restoreBackup('user-1', file.path);

          expect(result.success, isTrue);
          expect(result.recordCount, 0);
          verifyNever(() => birdRepo.saveAll(any()));
        },
      );

      test('handles v1 backup without v2 entity keys', () async {
        stubAllSaveAll();
        final bird = createTestBird(
          id: 'bird-v1',
          userId: 'user-1',
          name: 'OldBird',
        );

        final file = await writeBackupFile('v1.json', {
          'version': 1,
          'data': {
            'birds': [bird.toJson()],
            // No clutches, nests, photos keys (added in v2)
          },
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        expect(result.recordCount, 1);
        verify(() => birdRepo.saveAll(any())).called(1);
        verifyNever(() => clutchRepo.saveAll(any()));
        verifyNever(() => nestRepo.saveAll(any()));
        verifyNever(() => photoRepo.saveAll(any()));
      });

      test('requires encryption service for .enc.json files', () async {
        final file = await writeRawFile(
          'encrypted.enc.json',
          'encrypted-content',
        );

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isFalse);
        expect(
          result.error,
          contains('Encryption service required to restore encrypted backup'),
        );
      });

      test(
        'requires encryption service when content looks encrypted',
        () async {
          final file = await writeRawFile(
            'sneaky.json',
            'base64-encoded-not-json',
          );

          final result = await restorer.restoreBackup('user-1', file.path);

          expect(result.success, isFalse);
          expect(
            result.error,
            contains('Encryption service required to restore encrypted backup'),
          );
        },
      );

      test(
        'decrypts encrypted backup when encryption service is provided',
        () async {
          final encryptionService = _MockEncryptionService();
          when(() => encryptionService.decrypt('ciphertext')).thenAnswer(
            (_) async =>
                jsonEncode({'version': 2, 'data': <String, dynamic>{}}),
          );

          final encryptedRestorer = BackupRestorer(
            birdRepo: birdRepo,
            breedingRepo: breedingRepo,
            eggRepo: eggRepo,
            chickRepo: chickRepo,
            healthRepo: healthRepo,
            eventRepo: eventRepo,
            incubationRepo: incubationRepo,
            growthRepo: growthRepo,
            notificationRepo: notificationRepo,
            clutchRepo: clutchRepo,
            nestRepo: nestRepo,
            photoRepo: photoRepo,
            encryptionService: encryptionService,
          );

          final file = await writeRawFile('restore.enc.json', 'ciphertext');

          final result = await encryptedRestorer.restoreBackup(
            'user-1',
            file.path,
          );

          expect(result.success, isTrue);
          expect(result.recordCount, 0);
          verify(() => encryptionService.decrypt('ciphertext')).called(1);
        },
      );

      test('returns success with correct filePath', () async {
        final file = await writeBackupFile('path_check.json', {
          'version': 2,
          'data': <String, dynamic>{},
        });

        final result = await restorer.restoreBackup('user-1', file.path);

        expect(result.success, isTrue);
        expect(result.filePath, file.path);
      });

      test(
        'continues restoring other entities when one entity type fails',
        () async {
        stubAllSaveAll();
          when(
            () => birdRepo.saveAll(any<List<Bird>>()),
          ).thenThrow(Exception('DB error'));

          final bird = createTestBird(
            id: 'bird-1',
            userId: 'user-1',
            name: 'Fail',
          );

          final file = await writeBackupFile('partial_fail.json', {
            'version': 2,
            'data': {
              'birds': [bird.toJson()],
            },
          });

        final result = await restorer.restoreBackup('user-1', file.path);

        // Entity-level failure now returns partial-failure result.
        expect(result.success, isFalse);
        expect(result.error, contains('partially'));
        verify(() => birdRepo.saveAll(any())).called(1);
      },
    );

      test(
        'returns total record count across all restored entity types',
        () async {
          stubAllSaveAll();
          final bird = createTestBird(
            id: 'bird-1',
            userId: 'user-1',
            name: 'A',
          );
          final bird2 = createTestBird(
            id: 'bird-2',
            userId: 'user-1',
            name: 'B',
          );

          final file = await writeBackupFile('count.json', {
            'version': BackupDataCollector.backupVersion,
            'data': {
              'birds': [bird.toJson(), bird2.toJson()],
            },
          });

          final result = await restorer.restoreBackup('user-1', file.path);

          expect(result.success, isTrue);
          expect(result.recordCount, 2);
        },
      );
    });
  });
}
