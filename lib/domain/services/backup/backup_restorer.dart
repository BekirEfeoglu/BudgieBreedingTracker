import 'dart:convert';
import 'dart:io';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
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
import 'package:budgie_breeding_tracker/domain/services/backup/backup_data_collector.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_result.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

/// Restores user data from a JSON backup file.
///
/// Automatically detects encrypted backups by checking the file extension
/// (`.enc.json`) and content format (non-JSON content). If encryption is
/// detected, the [EncryptionService] is used to decrypt before parsing.
class BackupRestorer {
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

  static const _tag = '[BackupRestorer]';

  BackupRestorer({
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

  /// Restore data from a backup JSON file.
  Future<BackupResult> restoreBackup(String userId, String filePath) async {
    try {
      AppLogger.info('$_tag Restoring backup from: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        return BackupResult.failure('Backup file not found');
      }

      var content = await file.readAsString();

      // Auto-detect encrypted backup
      if (filePath.endsWith('.enc.json') || _looksEncrypted(content)) {
        if (_encryptionService == null) {
          return BackupResult.failure(
            'Encryption service required to restore encrypted backup',
          );
        }
        content = await _encryptionService.decrypt(content);
        AppLogger.info('$_tag Backup content decrypted');
      }

      final backupData = json.decode(content) as Map<String, dynamic>;

      final version = backupData['version'] as int?;
      if (version == null ||
          version > BackupDataCollector.backupVersion) {
        return BackupResult.failure(
          'Unsupported backup version: $version '
          '(max: ${BackupDataCollector.backupVersion})',
        );
      }
      // v1 backups are compatible — new entity keys simply won't exist in data

      final data = backupData['data'] as Map<String, dynamic>;
      var totalRecords = 0;
      var errorCount = 0;

      // Restore birds
      totalRecords += await _restoreEntity<Bird>(
        data: data,
        key: 'birds',
        fromJson: (json) => Bird.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _birdRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore breeding pairs
      totalRecords += await _restoreEntity<BreedingPair>(
        data: data,
        key: 'breeding_pairs',
        fromJson: (json) =>
            BreedingPair.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _breedingRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore eggs
      totalRecords += await _restoreEntity<Egg>(
        data: data,
        key: 'eggs',
        fromJson: (json) => Egg.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _eggRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore chicks
      totalRecords += await _restoreEntity<Chick>(
        data: data,
        key: 'chicks',
        fromJson: (json) => Chick.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _chickRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore health records
      totalRecords += await _restoreEntity<HealthRecord>(
        data: data,
        key: 'health_records',
        fromJson: (json) =>
            HealthRecord.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _healthRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore events
      totalRecords += await _restoreEntity<Event>(
        data: data,
        key: 'events',
        fromJson: (json) => Event.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _eventRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore incubations
      totalRecords += await _restoreEntity<Incubation>(
        data: data,
        key: 'incubations',
        fromJson: (json) =>
            Incubation.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _incubationRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore growth measurements
      totalRecords += await _restoreEntity<GrowthMeasurement>(
        data: data,
        key: 'growth_measurements',
        fromJson: (json) =>
            GrowthMeasurement.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _growthRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore notifications
      totalRecords += await _restoreEntity<AppNotification>(
        data: data,
        key: 'notifications',
        fromJson: (json) =>
            AppNotification.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _notificationRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore clutches (added in backup v2)
      totalRecords += await _restoreEntity<Clutch>(
        data: data,
        key: 'clutches',
        fromJson: (json) => Clutch.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _clutchRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore nests (added in backup v2)
      totalRecords += await _restoreEntity<Nest>(
        data: data,
        key: 'nests',
        fromJson: (json) => Nest.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _nestRepo.saveAll(items),
        onError: () => errorCount++,
      );

      // Restore photos (added in backup v2)
      totalRecords += await _restoreEntity<Photo>(
        data: data,
        key: 'photos',
        fromJson: (json) => Photo.fromJson(json as Map<String, dynamic>),
        saveAll: (items) => _photoRepo.saveAll(items),
        onError: () => errorCount++,
      );

      AppLogger.info(
        '$_tag Backup restored: $totalRecords records '
        '($errorCount entity types had errors)',
      );

      return BackupResult.success(
        filePath: filePath,
        recordCount: totalRecords,
      );
    } catch (e, st) {
      AppLogger.error('$_tag Backup restore failed', e, st);
      return BackupResult.failure(e.toString());
    }
  }

  /// Checks whether [content] looks encrypted (i.e. not valid JSON).
  ///
  /// Valid JSON backup files always start with `{` (possibly after whitespace).
  /// Encrypted content is Base64-encoded and will not start with `{`.
  bool _looksEncrypted(String content) {
    return !content.trimLeft().startsWith('{');
  }

  /// Helper to restore a single entity type from backup data.
  ///
  /// Returns the number of successfully restored records.
  Future<int> _restoreEntity<T>({
    required Map<String, dynamic> data,
    required String key,
    required T Function(dynamic json) fromJson,
    required Future<void> Function(List<T> items) saveAll,
    required void Function() onError,
  }) async {
    if (!data.containsKey(key)) return 0;

    try {
      final jsonList = data[key] as List;
      if (jsonList.isEmpty) return 0;

      AppLogger.info('$_tag Restoring ${jsonList.length} $key');

      final items = <T>[];
      for (final jsonItem in jsonList) {
        try {
          items.add(fromJson(jsonItem));
        } catch (e) {
          AppLogger.warning('$_tag Failed to parse $key item: $e');
        }
      }

      if (items.isNotEmpty) {
        await saveAll(items);
      }

      AppLogger.info('$_tag Restored ${items.length}/${jsonList.length} $key');
      return items.length;
    } catch (e, st) {
      AppLogger.error('$_tag Failed to restore $key', e, st);
      onError();
      return 0;
    }
  }
}
