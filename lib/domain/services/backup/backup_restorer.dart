import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
import 'package:budgie_breeding_tracker/domain/services/backup/backup_preview.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_repositories.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_result.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/portable_backup_codec.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

part 'backup_restorer_helpers.dart';

/// Restores user data from a JSON backup file.
///
/// Supports both device-bound [EncryptionService] payloads and password-based
/// portable envelopes. [previewBackup] validates and summarizes without writes.
class BackupRestorer {
  final EncryptionService? _encryptionService;
  final PortableBackupCodec _portableCodec;
  final List<_RestoreStep> _restoreSteps;

  static const _tag = '[BackupRestorer]';
  static const _backupEntityKeys = [
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
  ];

  BackupRestorer({
    required BackupRepositories repos,
    EncryptionService? encryptionService,
    PortableBackupCodec portableCodec = const PortableBackupCodec(),
  }) : _encryptionService = encryptionService,
       _portableCodec = portableCodec,
       _restoreSteps = _buildRestoreSteps(repos);

  /// Reads, decrypts, and validates a backup without mutating repositories.
  Future<BackupPreview> previewBackup(
    String userId,
    String filePath, {
    String? password,
  }) async {
    try {
      final decoded = await _readValidatedBackup(
        userId,
        filePath,
        password: password,
      );
      return BackupPreview.ready(
        isEncrypted: decoded.isEncrypted,
        isPortable: decoded.isPortable,
        version: decoded.version,
        createdAt: decoded.createdAt,
        entityCounts: {
          for (final key in _backupEntityKeys)
            if (decoded.data[key] is List)
              key: (decoded.data[key] as List).length,
        },
      );
    } on _BackupReadException catch (e) {
      if (e.requiresPassword) {
        return BackupPreview.passwordRequired();
      }
      return BackupPreview.failure(
        e.message,
        isEncrypted: e.isEncrypted,
        isPortable: e.isPortable,
      );
    } catch (e, st) {
      AppLogger.error('$_tag Backup preview failed', e, st);
      return BackupPreview.failure('backup.error_invalid_format'.tr());
    }
  }

  /// Restore data from a backup JSON file.
  Future<BackupResult> restoreBackup(
    String userId,
    String filePath, {
    String? password,
  }) async {
    try {
      AppLogger.info('$_tag Restoring backup from: $filePath');

      final decoded = await _readValidatedBackup(
        userId,
        filePath,
        password: password,
      );
      final result = await _restoreAllEntities(decoded.data, userId);

      AppLogger.info(
        '$_tag Backup restored: ${result.total} records '
        '(${result.errors} entity types had errors)',
      );

      if (result.errors > 0) {
        return BackupResult(
          success: false,
          filePath: filePath,
          error:
              'Backup restored partially: ${result.errors} entity type(s) failed',
          recordCount: result.total,
          timestamp: DateTime.now(),
        );
      }

      return BackupResult.success(
        filePath: filePath,
        recordCount: result.total,
      );
    } on _BackupReadException catch (e) {
      AppLogger.warning('$_tag Backup validation failed: ${e.message}');
      return BackupResult.failure(e.message);
    } catch (e, st) {
      // Reaching here means a genuine corruption / DB / partial-restore
      // failure (the expected wrong-password decrypt case returned above),
      // so it warrants Sentry visibility on this destructive path.
      AppLogger.error('$_tag Backup restore failed', e, st);
      await Sentry.captureException(e, stackTrace: st);
      return BackupResult.failure(e.toString());
    }
  }

  Future<_DecodedBackup> _readValidatedBackup(
    String userId,
    String filePath, {
    String? password,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw _BackupReadException('backup.error_file_not_found'.tr());
    }

    var content = await file.readAsString();
    final isPortable = PortableBackupCodec.looksPortable(content);
    var isEncrypted = isPortable;

    if (isPortable) {
      if (password == null || password.isEmpty) {
        throw _BackupReadException(
          'backup.password_required'.tr(),
          requiresPassword: true,
          isEncrypted: true,
          isPortable: true,
        );
      }
      try {
        content = await _portableCodec.decrypt(content, password);
      } on FormatException catch (e) {
        AppLogger.warning('$_tag Portable backup decrypt failed: $e');
        throw _BackupReadException(
          'backup.error_decrypt_failed'.tr(),
          isEncrypted: true,
          isPortable: true,
        );
      }
    } else if (filePath.endsWith('.enc.json') || _looksEncrypted(content)) {
      isEncrypted = true;
      if (_encryptionService == null) {
        throw _BackupReadException(
          'backup.error_device_key_required'.tr(),
          isEncrypted: true,
        );
      }
      try {
        content = await _encryptionService.decrypt(content);
      } on FormatException catch (e) {
        AppLogger.warning('$_tag Device backup decrypt failed: $e');
        throw _BackupReadException(
          'backup.error_decrypt_failed'.tr(),
          isEncrypted: true,
        );
      }
    }

    final Map<String, dynamic> backupData;
    try {
      final decoded = json.decode(content);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Backup root is not an object');
      }
      backupData = decoded;
    } catch (_) {
      throw _BackupReadException(
        'backup.error_invalid_format'.tr(),
        isEncrypted: isEncrypted,
        isPortable: isPortable,
      );
    }

    final version = backupData['version'];
    if (version is! int) {
      throw _BackupReadException(
        'backup.error_invalid_format'.tr(),
        isEncrypted: isEncrypted,
        isPortable: isPortable,
      );
    }
    if (version > BackupDataCollector.backupVersion) {
      throw _BackupReadException(
        'backup.error_unsupported_version'.tr(
          args: [
            version.toString(),
            BackupDataCollector.backupVersion.toString(),
          ],
        ),
        isEncrypted: isEncrypted,
        isPortable: isPortable,
      );
    }

    final rawBackupUserId = backupData['user_id'];
    if (rawBackupUserId != null && rawBackupUserId is! String) {
      throw _BackupReadException(
        'backup.error_invalid_format'.tr(),
        isEncrypted: isEncrypted,
        isPortable: isPortable,
      );
    }
    final backupUserId = (rawBackupUserId as String?)?.trim();
    if (backupUserId != null &&
        backupUserId.isNotEmpty &&
        backupUserId != userId) {
      throw _BackupReadException(
        'backup.error_wrong_user'.tr(),
        isEncrypted: isEncrypted,
        isPortable: isPortable,
      );
    }

    final rawData = backupData['data'];
    if (rawData is! Map<String, dynamic>) {
      throw _BackupReadException(
        'backup.error_invalid_format'.tr(),
        isEncrypted: isEncrypted,
        isPortable: isPortable,
      );
    }

    final rawCreatedAt = backupData['created_at'];
    if (rawCreatedAt != null && rawCreatedAt is! String) {
      throw _BackupReadException(
        'backup.error_invalid_format'.tr(),
        isEncrypted: isEncrypted,
        isPortable: isPortable,
      );
    }

    return _DecodedBackup(
      version: version,
      createdAt: DateTime.tryParse((rawCreatedAt as String?) ?? ''),
      data: rawData,
      isEncrypted: isEncrypted,
      isPortable: isPortable,
    );
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
    _step(
      'growth_measurements',
      GrowthMeasurement.fromJson,
      r.growthMeasurement.saveAll,
    ),
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

class _DecodedBackup {
  const _DecodedBackup({
    required this.version,
    required this.createdAt,
    required this.data,
    required this.isEncrypted,
    required this.isPortable,
  });

  final int version;
  final DateTime? createdAt;
  final Map<String, dynamic> data;
  final bool isEncrypted;
  final bool isPortable;
}

class _BackupReadException implements Exception {
  const _BackupReadException(
    this.message, {
    this.requiresPassword = false,
    this.isEncrypted = false,
    this.isPortable = false,
  });

  final String message;
  final bool requiresPassword;
  final bool isEncrypted;
  final bool isPortable;
}
