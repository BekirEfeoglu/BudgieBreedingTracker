import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export 'backup_result.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_data_collector.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_repositories.dart';
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
    required BackupRepositories repos,
    SupabaseClient? supabaseClient,
    EncryptionService? encryptionService,
  }) : _collector = BackupDataCollector(
         repos: repos,
         encryptionService: encryptionService,
       ),
       _restorer = BackupRestorer(
         repos: repos,
         encryptionService: encryptionService,
       ),
       _supabaseClient = supabaseClient,
       _encryptionService = encryptionService;

  /// Create a full backup of user data as JSON file.
  Future<BackupResult> createBackup(String userId, {bool encrypt = false}) {
    return _collector.createBackup(userId, encrypt: encrypt);
  }

  /// Restore data from a backup JSON file.
  Future<BackupResult> restoreBackup(String userId, String filePath) {
    return _restorer.restoreBackup(userId, filePath);
  }

  /// Upload a backup file to Supabase Storage.
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
