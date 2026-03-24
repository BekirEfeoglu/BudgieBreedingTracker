import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
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
import 'package:budgie_breeding_tracker/domain/services/backup/backup_repositories.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';
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

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

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
  late BackupService service;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(createTestBird());
    registerFallbackValue(<Bird>[]);
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

    service = _buildService(
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
    tempDir = await Directory.systemTemp.createTemp('backup_service_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
          if (methodCall.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupResult', () {
    test('success factory sets expected fields', () {
      final result = BackupResult.success(
        filePath: '/tmp/backup.json',
        recordCount: 42,
      );

      expect(result.success, isTrue);
      expect(result.filePath, '/tmp/backup.json');
      expect(result.recordCount, 42);
      expect(result.error, isNull);
      expect(result.timestamp, isA<DateTime>());
    });

    test('failure factory sets expected fields', () {
      final result = BackupResult.failure('boom');

      expect(result.success, isFalse);
      expect(result.error, 'boom');
      expect(result.filePath, isNull);
      expect(result.recordCount, 0);
      expect(result.timestamp, isA<DateTime>());
    });
  });

  group('BackupService.restoreBackup', () {
    test('returns failure when backup file does not exist', () async {
      final result = await service.restoreBackup(
        'user-1',
        '${tempDir.path}/missing.json',
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Backup file not found'));
    });

    test('requires encryption service for .enc.json files', () async {
      final file = await _writeTextFile(
        tempDir,
        'encrypted.enc.json',
        jsonEncode({'version': 2, 'data': <String, dynamic>{}}),
      );

      final result = await service.restoreBackup('user-1', file.path);

      expect(result.success, isFalse);
      expect(
        result.error,
        contains('Encryption service required to restore encrypted backup'),
      );
    });

    test('requires encryption service when content looks encrypted', () async {
      final file = await _writeTextFile(tempDir, 'backup.json', 'not-json');

      final result = await service.restoreBackup('user-1', file.path);

      expect(result.success, isFalse);
      expect(
        result.error,
        contains('Encryption service required to restore encrypted backup'),
      );
    });

    test('returns failure when backup version is unsupported', () async {
      final file = await _writeTextFile(
        tempDir,
        'unsupported.json',
        jsonEncode({'version': 99, 'data': <String, dynamic>{}}),
      );

      final result = await service.restoreBackup('user-1', file.path);

      expect(result.success, isFalse);
      expect(result.error, contains('Unsupported backup version: 99'));
    });

    test('restores valid birds and skips malformed bird rows', () async {
      when(() => birdRepo.saveAll(any<List<Bird>>())).thenAnswer((_) async {});

      final validBird = createTestBird(
        id: 'bird-1',
        userId: 'user-1',
        name: 'Mavi',
      );

      final file = await _writeTextFile(
        tempDir,
        'restore.json',
        jsonEncode({
          'version': 2,
          'data': {
            'birds': [
              validBird.toJson(),
              {'bad': 'row'},
            ],
          },
        }),
      );

      final result = await service.restoreBackup('user-1', file.path);

      expect(result.success, isTrue);
      expect(result.recordCount, 1);
      final captured = verify(() => birdRepo.saveAll(captureAny())).captured;
      expect(captured.single, isA<List<Bird>>());
      final savedBirds = captured.single as List<Bird>;
      expect(savedBirds.length, 1);
      expect(savedBirds.first.id, 'bird-1');
    });

    test('decrypts encrypted backups when encryption service exists', () async {
      final encryptionService = _MockEncryptionService();
      when(() => encryptionService.decrypt('ciphertext')).thenAnswer(
        (_) async => jsonEncode({'version': 2, 'data': <String, dynamic>{}}),
      );

      final encryptedService = _buildService(
        encryptionService: encryptionService,
      );
      final file = await _writeTextFile(
        tempDir,
        'restore.enc.json',
        'ciphertext',
      );

      final result = await encryptedService.restoreBackup('user-1', file.path);

      expect(result.success, isTrue);
      expect(result.recordCount, 0);
      verify(() => encryptionService.decrypt('ciphertext')).called(1);
    });

    test('returns failure for corrupted JSON backup content', () async {
      final file = await _writeTextFile(tempDir, 'corrupted.json', '{bad json');

      final result = await service.restoreBackup('user-1', file.path);

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('BackupService.createBackup', () {
    void stubEmptyRepositories() {
      when(() => birdRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => breedingRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => eggRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => chickRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => healthRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => eventRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => incubationRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => growthRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => notificationRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => clutchRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => nestRepo.getAll(any())).thenAnswer((_) async => []);
      when(() => photoRepo.getAll(any())).thenAnswer((_) async => []);
    }

    test('creates backup json file with aggregated record count', () async {
      stubEmptyRepositories();
      final bird = createTestBird(
        id: 'bird-1',
        userId: 'user-1',
        name: 'Mavis',
      );
      when(() => birdRepo.getAll('user-1')).thenAnswer((_) async => [bird]);

      final result = await service.createBackup('user-1');

      expect(result.success, isTrue);
      expect(result.filePath, isNotNull);
      expect(result.recordCount, 1);

      final file = File(result.filePath!);
      expect(await file.exists(), isTrue);
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(decoded['version'], 2);
      expect((decoded['data']['birds'] as List).length, 1);
    });

    test(
      'returns failure when encryption requested without encryption service',
      () async {
        stubEmptyRepositories();

        final result = await service.createBackup('user-1', encrypt: true);

        expect(result.success, isFalse);
        expect(result.error, contains('Encryption service not available'));
      },
    );

    test(
      'creates encrypted backup when encryption service is provided',
      () async {
        final encryptionService = _MockEncryptionService();
        when(
          () => encryptionService.encrypt(any()),
        ).thenAnswer((_) async => 'encrypted-content');

        final encryptedService = _buildService(
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

        when(() => birdRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => breedingRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => eggRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => chickRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => healthRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => eventRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => incubationRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => growthRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => notificationRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => clutchRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => nestRepo.getAll(any())).thenAnswer((_) async => []);
        when(() => photoRepo.getAll(any())).thenAnswer((_) async => []);

        final result = await encryptedService.createBackup(
          'user-1',
          encrypt: true,
        );

        expect(result.success, isTrue);
        expect(result.filePath, endsWith('.enc.json'));
        verify(() => encryptionService.encrypt(any())).called(1);
      },
    );
  });

  group('BackupService upload/list guards', () {
    test(
      'uploadBackup fails fast when Supabase client is unavailable',
      () async {
        final result = await service.uploadBackup('user-1', 'any.json');

        expect(result.success, isFalse);
        expect(result.error, 'Supabase client not available');
      },
    );

    test(
      'listBackups returns empty list when Supabase client is unavailable',
      () async {
        final result = await service.listBackups('user-1');
        expect(result, isEmpty);
      },
    );
  });
}

BackupService _buildService({
  BirdRepository? birdRepo,
  BreedingPairRepository? breedingRepo,
  EggRepository? eggRepo,
  ChickRepository? chickRepo,
  HealthRecordRepository? healthRepo,
  EventRepository? eventRepo,
  IncubationRepository? incubationRepo,
  GrowthMeasurementRepository? growthRepo,
  NotificationRepository? notificationRepo,
  ClutchRepository? clutchRepo,
  NestRepository? nestRepo,
  PhotoRepository? photoRepo,
  EncryptionService? encryptionService,
}) {
  return BackupService(
    repos: BackupRepositories(
      bird: birdRepo ?? _MockBirdRepository(),
      breedingPair: breedingRepo ?? _MockBreedingPairRepository(),
      egg: eggRepo ?? _MockEggRepository(),
      chick: chickRepo ?? _MockChickRepository(),
      healthRecord: healthRepo ?? _MockHealthRecordRepository(),
      event: eventRepo ?? _MockEventRepository(),
      incubation: incubationRepo ?? _MockIncubationRepository(),
      growthMeasurement: growthRepo ?? _MockGrowthMeasurementRepository(),
      notification: notificationRepo ?? _MockNotificationRepository(),
      clutch: clutchRepo ?? _MockClutchRepository(),
      nest: nestRepo ?? _MockNestRepository(),
      photo: photoRepo ?? _MockPhotoRepository(),
    ),
    encryptionService: encryptionService,
  );
}

Future<File> _writeTextFile(
  Directory directory,
  String fileName,
  String content,
) async {
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(content);
  return file;
}
