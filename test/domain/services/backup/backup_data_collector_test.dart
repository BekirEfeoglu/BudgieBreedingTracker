import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
  late BackupDataCollector collector;
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
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

    collector = BackupDataCollector(
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

    tempDir = await Directory.systemTemp.createTemp('backup_collector_test_');
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

  void stubAllRepositoriesEmpty() {
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

  group('BackupDataCollector', () {
    group('createBackup', () {
      test('collects data from all repositories for given userId', () async {
        final bird = createTestBird(
          id: 'bird-1',
          userId: 'user-1',
          name: 'Mavis',
        );
        stubAllRepositoriesEmpty();
        when(() => birdRepo.getAll('user-1')).thenAnswer((_) async => [bird]);

        final result = await collector.createBackup('user-1');

        expect(result.success, isTrue);
        verify(() => birdRepo.getAll('user-1')).called(1);
        verify(() => breedingRepo.getAll('user-1')).called(1);
        verify(() => eggRepo.getAll('user-1')).called(1);
        verify(() => chickRepo.getAll('user-1')).called(1);
        verify(() => healthRepo.getAll('user-1')).called(1);
        verify(() => eventRepo.getAll('user-1')).called(1);
        verify(() => incubationRepo.getAll('user-1')).called(1);
        verify(() => growthRepo.getAll('user-1')).called(1);
        verify(() => notificationRepo.getAll('user-1')).called(1);
        verify(() => clutchRepo.getAll('user-1')).called(1);
        verify(() => nestRepo.getAll('user-1')).called(1);
        verify(() => photoRepo.getAll('user-1')).called(1);
      });

      test('handles empty repositories gracefully', () async {
        stubAllRepositoriesEmpty();

        final result = await collector.createBackup('user-1');

        expect(result.success, isTrue);
        expect(result.recordCount, 0);
        expect(result.filePath, isNotNull);

        final file = File(result.filePath!);
        expect(await file.exists(), isTrue);

        final decoded =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>;
        for (final key in [
          'birds',
          'breeding_pairs',
          'eggs',
          'chicks',
          'health_records',
          'events',
          'incubations',
          'growth_measurements',
          'notifications',
          'clutches',
          'nests',
          'photos',
        ]) {
          expect((data[key] as List), isEmpty, reason: '$key should be empty');
        }
      });

      test('produces correct JSON structure with version and userId', () async {
        stubAllRepositoriesEmpty();

        final result = await collector.createBackup('user-42');

        expect(result.success, isTrue);

        final file = File(result.filePath!);
        final decoded =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;

        expect(decoded['version'], BackupDataCollector.backupVersion);
        expect(decoded['user_id'], 'user-42');
        expect(decoded['created_at'], isNotNull);
        expect(decoded['data'], isA<Map<String, dynamic>>());
      });

      test('includes all 12 entity keys in data section', () async {
        stubAllRepositoriesEmpty();

        final result = await collector.createBackup('user-1');

        final file = File(result.filePath!);
        final decoded =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>;

        expect(data.keys.toSet(), {
          'birds',
          'breeding_pairs',
          'eggs',
          'chicks',
          'health_records',
          'events',
          'incubations',
          'growth_measurements',
          'notifications',
          'clutches',
          'nests',
          'photos',
        });
      });

      test('aggregates total record count across all repositories', () async {
        final bird1 = createTestBird(id: 'b1', userId: 'user-1', name: 'A');
        final bird2 = createTestBird(id: 'b2', userId: 'user-1', name: 'B');

        stubAllRepositoriesEmpty();
        when(
          () => birdRepo.getAll('user-1'),
        ).thenAnswer((_) async => [bird1, bird2]);

        final result = await collector.createBackup('user-1');

        expect(result.success, isTrue);
        expect(result.recordCount, 2);
      });

      test('uses userId for scoped data collection', () async {
        stubAllRepositoriesEmpty();

        await collector.createBackup('specific-user');

        verify(() => birdRepo.getAll('specific-user')).called(1);
        verify(() => eggRepo.getAll('specific-user')).called(1);
        verify(() => chickRepo.getAll('specific-user')).called(1);
        verifyNever(() => birdRepo.getAll('other-user'));
      });

      test('writes backup file with .json extension', () async {
        stubAllRepositoriesEmpty();

        final result = await collector.createBackup('user-1');

        expect(result.success, isTrue);
        expect(result.filePath, endsWith('.json'));
        expect(result.filePath, isNot(endsWith('.enc.json')));
      });

      test(
        'returns failure when encryption requested without encryption service',
        () async {
          stubAllRepositoriesEmpty();

          final result = await collector.createBackup('user-1', encrypt: true);

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

          final encryptedCollector = BackupDataCollector(
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

          stubAllRepositoriesEmpty();

          final result = await encryptedCollector.createBackup(
            'user-1',
            encrypt: true,
          );

          expect(result.success, isTrue);
          expect(result.filePath, endsWith('.enc.json'));
          verify(() => encryptionService.encrypt(any())).called(1);

          final file = File(result.filePath!);
          final content = await file.readAsString();
          expect(content, 'encrypted-content');
        },
      );

      test('returns failure when repository throws exception', () async {
        stubAllRepositoriesEmpty();
        when(
          () => birdRepo.getAll(any()),
        ).thenThrow(Exception('DB connection lost'));

        final result = await collector.createBackup('user-1');

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('serializes bird data correctly into JSON', () async {
        final bird = createTestBird(
          id: 'bird-99',
          userId: 'user-1',
          name: 'Sari',
        );
        stubAllRepositoriesEmpty();
        when(() => birdRepo.getAll('user-1')).thenAnswer((_) async => [bird]);

        final result = await collector.createBackup('user-1');

        final file = File(result.filePath!);
        final decoded =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final birds = decoded['data']['birds'] as List;
        expect(birds.length, 1);
        expect(birds.first['id'], 'bird-99');
        expect(birds.first['name'], 'Sari');
      });
    });

    group('backupVersion', () {
      test('returns current backup format version', () {
        expect(BackupDataCollector.backupVersion, isPositive);
      });
    });
  });
}
