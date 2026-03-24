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

part 'backup_restorer_helpers.dart';

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
  }) : _birdRepo = birdRepo,
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
      if (version == null || version > BackupDataCollector.backupVersion) {
        return BackupResult.failure(
          'Unsupported backup version: $version '
          '(max: ${BackupDataCollector.backupVersion})',
        );
      }

      final backupUserId = (backupData['user_id'] as String?)?.trim();
      if (backupUserId != null &&
          backupUserId.isNotEmpty &&
          backupUserId != userId) {
        return BackupResult.failure(
          'Backup belongs to another user: $backupUserId',
        );
      }

      final data = backupData['data'] as Map<String, dynamic>;
      final result = await _restoreAllEntities(data, userId);

      AppLogger.info(
        '$_tag Backup restored: ${result.total} records '
        '(${result.errors} entity types had errors)',
      );

      if (result.errors > 0) {
        return BackupResult(
          success: false,
          filePath: filePath,
          error: 'Backup restored partially: ${result.errors} entity type(s) failed',
          recordCount: result.total,
          timestamp: DateTime.now(),
        );
      }

      return BackupResult.success(
        filePath: filePath,
        recordCount: result.total,
      );
    } catch (e, st) {
      AppLogger.error('$_tag Backup restore failed', e, st);
      return BackupResult.failure(e.toString());
    }
  }

  /// Entity registry: FK-safe restore order (parents before children).
  ///
  /// Each [_RestoreStep] captures its generic type via [_step], so the
  /// loop below stays type-safe without repeating boilerplate per entity.
  late final _restoreSteps = <_RestoreStep>[
    _step('birds', Bird.fromJson, _birdRepo.saveAll),
    _step('nests', Nest.fromJson, _nestRepo.saveAll),
    _step('breeding_pairs', BreedingPair.fromJson, _breedingRepo.saveAll),
    _step('clutches', Clutch.fromJson, _clutchRepo.saveAll),
    _step('incubations', Incubation.fromJson, _incubationRepo.saveAll),
    _step('eggs', Egg.fromJson, _eggRepo.saveAll),
    _step('chicks', Chick.fromJson, _chickRepo.saveAll),
    _step('health_records', HealthRecord.fromJson, _healthRepo.saveAll),
    _step('events', Event.fromJson, _eventRepo.saveAll),
    _step('growth_measurements', GrowthMeasurement.fromJson, _growthRepo.saveAll),
    _step('notifications', AppNotification.fromJson, _notificationRepo.saveAll),
    _step('photos', Photo.fromJson, _photoRepo.saveAll),
  ];

  Future<({int total, int errors})> _restoreAllEntities(
    Map<String, dynamic> data,
    String userId,
  ) async {
    var totalRecords = 0;
    var errorCount = 0;

    for (final step in _restoreSteps) {
      totalRecords += await step(data, userId, () => errorCount++);
    }

    return (total: totalRecords, errors: errorCount);
  }
}
