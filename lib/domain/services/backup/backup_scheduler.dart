import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';

/// Frequency of automatic backups.
enum BackupFrequency {
  daily,
  weekly,
  monthly,
  never;

  /// Duration between backups.
  Duration get interval => switch (this) {
    BackupFrequency.daily => const Duration(days: 1),
    BackupFrequency.weekly => const Duration(days: 7),
    BackupFrequency.monthly => const Duration(days: 30),
    BackupFrequency.never => Duration.zero,
  };

  /// Localization key for UI.
  String get labelKey => switch (this) {
    BackupFrequency.daily => 'settings.backup_daily',
    BackupFrequency.weekly => 'settings.backup_weekly',
    BackupFrequency.monthly => 'settings.backup_monthly',
    BackupFrequency.never => 'settings.backup_never',
  };
}

/// Manages automatic backup scheduling via SharedPreferences.
class BackupScheduler {
  final BackupService _backupService;
  static const _tag = '[BackupScheduler]';

  static const _keyFrequency = 'backup_frequency';
  static const _keyLastBackup = 'backup_last_timestamp';

  BackupScheduler(this._backupService);

  /// Set the auto-backup frequency.
  Future<void> setFrequency(BackupFrequency frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFrequency, frequency.name);
    AppLogger.info('$_tag Backup frequency set to: ${frequency.name}');
  }

  /// Get the current auto-backup frequency.
  Future<BackupFrequency> getFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyFrequency);
    if (value == null) return BackupFrequency.never;
    return BackupFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => BackupFrequency.never,
    );
  }

  /// Get the last backup timestamp.
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyLastBackup);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Record that a backup was performed now.
  Future<void> _recordBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastBackup, DateTime.now().toIso8601String());
  }

  /// Cancel auto backup (set frequency to never).
  Future<void> cancelAutoBackup() async {
    await setFrequency(BackupFrequency.never);
    AppLogger.info('$_tag Auto backup cancelled');
  }

  /// Check if a backup should run based on frequency and last backup time.
  Future<bool> shouldRunBackup() async {
    final frequency = await getFrequency();
    if (frequency == BackupFrequency.never) return false;

    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) return true;

    final elapsed = DateTime.now().difference(lastBackup);
    return elapsed >= frequency.interval;
  }

  /// Run a backup if the schedule requires it.
  Future<BackupResult?> runIfScheduled(String userId) async {
    final shouldRun = await shouldRunBackup();
    if (!shouldRun) {
      AppLogger.info('$_tag No scheduled backup needed');
      return null;
    }

    AppLogger.info('$_tag Running scheduled backup');
    final result = await _backupService.createBackup(userId);

    if (result.success) {
      await _recordBackup();
      AppLogger.info('$_tag Scheduled backup completed successfully');
    }

    return result;
  }
}
