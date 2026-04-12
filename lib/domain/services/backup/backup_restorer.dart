import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';

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
import 'package:budgie_breeding_tracker/domain/services/backup/backup_data_collector.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_repositories.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_result.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

part 'backup_restorer_helpers.dart';

/// Restores user data from a JSON backup file.
///
/// Automatically detects encrypted backups by checking the file extension
/// (`.enc.json`) and content format (non-JSON content). If encryption is
/// detected, the [EncryptionService] is used to decrypt before parsing.
class BackupRestorer {
  final EncryptionService? _encryptionService;
  final List<_RestoreStep> _restoreSteps;

  static const _tag = '[BackupRestorer]';

  BackupRestorer({
    required BackupRepositories repos,
    EncryptionService? encryptionService,
  }) : _encryptionService = encryptionService,
       _restoreSteps = _buildRestoreSteps(repos);

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
      if (version == null) {
        return BackupResult.failure(
          'backup.error_invalid_format'.tr(),
        );
      }
      if (version > BackupDataCollector.backupVersion) {
        return BackupResult.failure(
          'backup.error_unsupported_version'.tr(args: [
            version.toString(),
            BackupDataCollector.backupVersion.toString(),
          ]),
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

      final rawData = backupData['data'];
      if (rawData is! Map<String, dynamic>) {
        return BackupResult.failure(
          'backup.error_invalid_format'.tr(),
        );
      }
      final data = rawData;
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
  static List<_RestoreStep> _buildRestoreSteps(BackupRepositories r) => [
    _step('birds', Bird.fromJson, r.bird.saveAll),
    _step('nests', Nest.fromJson, r.nest.saveAll),
    _step('breeding_pairs', BreedingPair.fromJson, r.breedingPair.saveAll),
    _step('clutches', Clutch.fromJson, r.clutch.saveAll),
    _step('incubations', Incubation.fromJson, r.incubation.saveAll),
    _step('eggs', Egg.fromJson, r.egg.saveAll),
    _step('chicks', Chick.fromJson, r.chick.saveAll),
    _step('health_records', HealthRecord.fromJson, r.healthRecord.saveAll),
    _step('events', Event.fromJson, r.event.saveAll),
    _step('growth_measurements', GrowthMeasurement.fromJson, r.growthMeasurement.saveAll),
    _step('notifications', AppNotification.fromJson, r.notification.saveAll),
    _step('photos', Photo.fromJson, r.photo.saveAll),
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
