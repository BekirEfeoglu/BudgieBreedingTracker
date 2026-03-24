import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

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
import 'package:budgie_breeding_tracker/domain/services/backup/backup_repositories.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_result.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

/// Collects all user data from repositories and assembles a JSON backup file.
///
/// Supports optional AES-256-CBC encryption via [EncryptionService].
/// Encrypted backups use `.enc.json` extension.
class BackupDataCollector {
  final EncryptionService? _encryptionService;
  final List<_ExportEntry> _exportEntries;

  static const _tag = '[BackupDataCollector]';
  static const _backupVersion = 2;

  BackupDataCollector({
    required BackupRepositories repos,
    EncryptionService? encryptionService,
  }) : _encryptionService = encryptionService,
       _exportEntries = _buildExportEntries(repos);

  /// The current backup format version.
  static int get backupVersion => _backupVersion;

  /// Create a full backup of user data as JSON file.
  Future<BackupResult> createBackup(
    String userId, {
    bool encrypt = false,
  }) async {
    try {
      AppLogger.info(
        '$_tag Creating backup for user: $userId'
        '${encrypt ? ' (encrypted)' : ''}',
      );

      if (encrypt && _encryptionService == null) {
        return BackupResult.failure(
          'Encryption service not available for encrypted backup',
        );
      }

      // Fetch all entities in parallel
      final results = await Future.wait(
        _exportEntries.map((e) => e.fetchAll(userId)),
      );

      // Assemble data map with typed toJson serialization
      final dataMap = <String, dynamic>{};
      var totalRecords = 0;
      for (var i = 0; i < _exportEntries.length; i++) {
        final entry = _exportEntries[i];
        final items = results[i];
        dataMap[entry.key] = items.map(entry.itemToJson).toList();
        totalRecords += items.length;
      }

      final backupData = {
        'version': _backupVersion,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': userId,
        'data': dataMap,
      };

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

      AppLogger.info('$_tag Backup created: $fileName ($totalRecords records)');

      return BackupResult.success(
        filePath: file.path,
        recordCount: totalRecords,
      );
    } catch (e, st) {
      AppLogger.error('$_tag Backup creation failed', e, st);
      return BackupResult.failure(e.toString());
    }
  }

  static List<_ExportEntry> _buildExportEntries(BackupRepositories r) => [
    _export('birds', r.bird.getAll, (Bird b) => b.toJson()),
    _export('breeding_pairs', r.breedingPair.getAll, (BreedingPair b) => b.toJson()),
    _export('eggs', r.egg.getAll, (Egg e) => e.toJson()),
    _export('chicks', r.chick.getAll, (Chick c) => c.toJson()),
    _export('health_records', r.healthRecord.getAll, (HealthRecord h) => h.toJson()),
    _export('events', r.event.getAll, (Event e) => e.toJson()),
    _export('incubations', r.incubation.getAll, (Incubation i) => i.toJson()),
    _export('growth_measurements', r.growthMeasurement.getAll, (GrowthMeasurement g) => g.toJson()),
    _export('notifications', r.notification.getAll, (AppNotification n) => n.toJson()),
    _export('clutches', r.clutch.getAll, (Clutch c) => c.toJson()),
    _export('nests', r.nest.getAll, (Nest n) => n.toJson()),
    _export('photos', r.photo.getAll, (Photo p) => p.toJson()),
  ];
}

/// Type-erased export entry that captures generics via [_export].
class _ExportEntry {
  final String key;
  final Future<List<dynamic>> Function(String userId) fetchAll;
  final Map<String, dynamic> Function(dynamic item) itemToJson;

  const _ExportEntry(this.key, this.fetchAll, this.itemToJson);
}

/// Creates a typed [_ExportEntry] capturing [T] via closure.
_ExportEntry _export<T>(
  String key,
  Future<List<T>> Function(String userId) getAll,
  Map<String, dynamic> Function(T item) toJson,
) {
  return _ExportEntry(
    key,
    (userId) async => await getAll(userId),
    (item) => toJson(item as T),
  );
}
