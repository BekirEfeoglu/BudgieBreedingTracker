import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'backup_result.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
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
import 'package:budgie_breeding_tracker/domain/services/backup/backup_data_collector.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_restorer.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_result.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

/// Creates and restores JSON backups of user data.
///
/// Supports optional AES-256-CBC encryption via [EncryptionService].
/// Encrypted backups use `.enc.json` extension and are auto-detected
/// during restore.
///
/// Delegates data collection to [BackupDataCollector] and restore logic
/// to [BackupRestorer]. Handles cloud upload/listing via Supabase Storage.
class BackupService {
  final BackupDataCollector _collector;
  final BackupRestorer _restorer;
  final SupabaseClient? _supabaseClient;
  final EncryptionService? _encryptionService;

  static const _tag = '[BackupService]';
  static const _backupBucket = SupabaseConstants.backupsBucket;

  BackupService({
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
    SupabaseClient? supabaseClient,
    EncryptionService? encryptionService,
  }) : _collector = BackupDataCollector(
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
       ),
       _restorer = BackupRestorer(
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
       ),
       _supabaseClient = supabaseClient,
       _encryptionService = encryptionService;

  /// Create a full backup of user data as JSON file.
  ///
  /// When [encrypt] is `true` and an [EncryptionService] is available,
  /// the JSON content is encrypted with AES-256-CBC before writing.
  /// Encrypted files use `.enc.json` extension.
  Future<BackupResult> createBackup(String userId, {bool encrypt = false}) {
    return _collector.createBackup(userId, encrypt: encrypt);
  }

  /// Restore data from a backup JSON file.
  ///
  /// Automatically detects encrypted backups by checking the file extension
  /// (`.enc.json`) and content format (non-JSON content). If encryption is
  /// detected, the [EncryptionService] is used to decrypt before parsing.
  Future<BackupResult> restoreBackup(String userId, String filePath) {
    return _restorer.restoreBackup(userId, filePath);
  }

  /// Upload a backup file to Supabase Storage.
  ///
  /// When [encrypt] is `true` and an [EncryptionService] is available,
  /// the file content is encrypted before uploading. The remote file
  /// uses `.enc.json` extension to indicate encryption.
  Future<BackupResult> uploadBackup(
    String userId,
    String filePath, {
    bool encrypt = false,
  }) async {
    if (_supabaseClient == null) {
      return BackupResult.failure('Supabase client not available');
    }

    File? tempEncryptedFile;
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return BackupResult.failure('Backup file not found');
      }

      if (encrypt && _encryptionService == null) {
        return BackupResult.failure(
          'Encryption service not available for encrypted upload',
        );
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final isAlreadyEncrypted = filePath.endsWith('.enc.json');
      final shouldEncrypt = encrypt && !isAlreadyEncrypted;

      File fileToUpload;
      if (shouldEncrypt && _encryptionService != null) {
        final content = await file.readAsString();
        final encryptedContent = await _encryptionService.encrypt(content);

        final dir = await getTemporaryDirectory();
        final encFile = File(
          '${dir.path}/upload_encrypted_$timestamp.enc.json',
        );
        await encFile.writeAsString(encryptedContent);
        tempEncryptedFile = encFile;
        fileToUpload = encFile;
        AppLogger.info('$_tag Backup content encrypted for upload');
      } else {
        fileToUpload = file;
      }

      final extension = (shouldEncrypt || isAlreadyEncrypted)
          ? '.enc.json'
          : '.json';
      final remotePath = '$userId/backup_$timestamp$extension';

      await _supabaseClient.storage
          .from(_backupBucket)
          .upload(remotePath, fileToUpload);

      AppLogger.info('$_tag Backup uploaded: $remotePath');

      return BackupResult.success(filePath: remotePath, recordCount: 0);
    } catch (e, st) {
      AppLogger.error('$_tag Backup upload failed', e, st);
      return BackupResult.failure(e.toString());
    } finally {
      if (tempEncryptedFile != null) {
        try {
          if (await tempEncryptedFile.exists()) {
            await tempEncryptedFile.delete();
          }
        } catch (e) {
          AppLogger.warning(
            '$_tag Failed to clean temporary encrypted upload file: $e',
          );
        }
      }
    }
  }

  /// List available remote backups for a user.
  Future<List<FileObject>> listBackups(String userId) async {
    if (_supabaseClient == null) return [];

    try {
      final files = await _supabaseClient.storage
          .from(_backupBucket)
          .list(path: userId);
      return files
        ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    } catch (e, st) {
      AppLogger.error('$_tag List backups failed', e, st);
      return [];
    }
  }
}
