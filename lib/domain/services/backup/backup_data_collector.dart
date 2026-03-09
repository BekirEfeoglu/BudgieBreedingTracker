import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_result.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

/// Collects all user data from repositories and assembles a JSON backup file.
///
/// Supports optional AES-256-CBC encryption via [EncryptionService].
/// Encrypted backups use `.enc.json` extension.
class BackupDataCollector {
  final BirdRepository _birdRepo;
  final BreedingPairRepository _breedingRepo;
  final EggRepository _eggRepo;
  final ChickRepository _chickRepo;
  final HealthRecordRepository _healthRepo;
  final EventRepository _eventRepo;
  final IncubationRepository _incubationRepo;
  final GrowthMeasurementRepository _growthRepo;
  final NotificationRepository _notificationRepo;
  final ClutchRepository _clutchRepo;
  final NestRepository _nestRepo;
  final PhotoRepository _photoRepo;
  final EncryptionService? _encryptionService;

  static const _tag = '[BackupDataCollector]';
  static const _backupVersion = 2;

  BackupDataCollector({
    required BirdRepository birdRepo,
    required BreedingPairRepository breedingRepo,
    required EggRepository eggRepo,
    required ChickRepository chickRepo,
    required HealthRecordRepository healthRepo,
    required EventRepository eventRepo,
    required IncubationRepository incubationRepo,
    required GrowthMeasurementRepository growthRepo,
    required NotificationRepository notificationRepo,
    required ClutchRepository clutchRepo,
    required NestRepository nestRepo,
    required PhotoRepository photoRepo,
    EncryptionService? encryptionService,
  })  : _birdRepo = birdRepo,
        _breedingRepo = breedingRepo,
        _eggRepo = eggRepo,
        _chickRepo = chickRepo,
        _healthRepo = healthRepo,
        _eventRepo = eventRepo,
        _incubationRepo = incubationRepo,
        _growthRepo = growthRepo,
        _notificationRepo = notificationRepo,
        _clutchRepo = clutchRepo,
        _nestRepo = nestRepo,
        _photoRepo = photoRepo,
        _encryptionService = encryptionService;

  /// The current backup format version.
  static int get backupVersion => _backupVersion;

  /// Create a full backup of user data as JSON file.
  ///
  /// When [encrypt] is `true` and an [EncryptionService] is available,
  /// the JSON content is encrypted with AES-256-CBC before writing.
  /// Encrypted files use `.enc.json` extension.
  Future<BackupResult> createBackup(
    String userId, {
    bool encrypt = false,
  }) async {
    try {
      AppLogger.info('$_tag Creating backup for user: $userId'
          '${encrypt ? ' (encrypted)' : ''}');

      if (encrypt && _encryptionService == null) {
        return BackupResult.failure(
          'Encryption service not available for encrypted backup',
        );
      }

      final results = await Future.wait([
        _birdRepo.getAll(userId),
        _breedingRepo.getAll(userId),
        _eggRepo.getAll(userId),
        _chickRepo.getAll(userId),
        _healthRepo.getAll(userId),
        _eventRepo.getAll(userId),
        _incubationRepo.getAll(userId),
        _growthRepo.getAll(userId),
        _notificationRepo.getAll(userId),
        _clutchRepo.getAll(userId),
        _nestRepo.getAll(userId),
        _photoRepo.getAll(userId),
      ]);

      final backupData = {
        'version': _backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': userId,
        'data': {
          'birds': results[0].map((b) => (b as dynamic).toJson()).toList(),
          'breeding_pairs':
              results[1].map((b) => (b as dynamic).toJson()).toList(),
          'eggs': results[2].map((e) => (e as dynamic).toJson()).toList(),
          'chicks': results[3].map((c) => (c as dynamic).toJson()).toList(),
          'health_records':
              results[4].map((h) => (h as dynamic).toJson()).toList(),
          'events': results[5].map((e) => (e as dynamic).toJson()).toList(),
          'incubations':
              results[6].map((i) => (i as dynamic).toJson()).toList(),
          'growth_measurements':
              results[7].map((g) => (g as dynamic).toJson()).toList(),
          'notifications':
              results[8].map((n) => (n as dynamic).toJson()).toList(),
          'clutches':
              results[9].map((c) => (c as dynamic).toJson()).toList(),
          'nests':
              results[10].map((n) => (n as dynamic).toJson()).toList(),
          'photos':
              results[11].map((p) => (p as dynamic).toJson()).toList(),
        },
      };

      final totalRecords =
          results.fold<int>(0, (sum, list) => sum + list.length);

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      String contentToWrite;
      if (encrypt && _encryptionService != null) {
        contentToWrite = await _encryptionService.encrypt(jsonString);
        AppLogger.info('$_tag Backup content encrypted');
      } else {
        contentToWrite = jsonString;
      }

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final extension = encrypt ? '.enc.json' : '.json';
      final fileName = 'budgie_backup_$timestamp$extension';
      final file = File('${dir.path}/$fileName');

      await file.writeAsString(contentToWrite);

      AppLogger.info(
          '$_tag Backup created: $fileName ($totalRecords records)');

      return BackupResult.success(
        filePath: file.path,
        recordCount: totalRecords,
      );
    } catch (e, st) {
      AppLogger.error('$_tag Backup creation failed', e, st);
      return BackupResult.failure(e.toString());
    }
  }
}
