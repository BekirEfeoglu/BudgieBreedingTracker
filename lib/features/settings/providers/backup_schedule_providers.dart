import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/supabase_client_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/backup/backup_repositories.dart';
import '../../../domain/services/backup/backup_scheduler.dart';
import '../../../domain/services/backup/backup_service.dart';
import '../../../domain/services/encryption/encryption_providers.dart';

/// Fully-wired [BackupService]. Previously there was no provider for it, so the
/// JSON+AES backup path (and the [BackupScheduler] on top of it) was orphaned.
final backupServiceProvider = Provider<BackupService>((ref) {
  final repos = BackupRepositories(
    bird: ref.watch(birdRepositoryProvider),
    breedingPair: ref.watch(breedingPairRepositoryProvider),
    egg: ref.watch(eggRepositoryProvider),
    chick: ref.watch(chickRepositoryProvider),
    healthRecord: ref.watch(healthRecordRepositoryProvider),
    event: ref.watch(eventRepositoryProvider),
    incubation: ref.watch(incubationRepositoryProvider),
    growthMeasurement: ref.watch(growthMeasurementRepositoryProvider),
    notification: ref.watch(notificationRepositoryProvider),
    clutch: ref.watch(clutchRepositoryProvider),
    nest: ref.watch(nestRepositoryProvider),
    photo: ref.watch(photoRepositoryProvider),
  );
  return BackupService(
    repos: repos,
    supabaseClient: ref.watch(supabaseClientProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Manages the auto-backup schedule (SharedPreferences-backed).
final backupSchedulerProvider = Provider<BackupScheduler>((ref) {
  return BackupScheduler(ref.watch(backupServiceProvider));
});

/// Immutable snapshot of the auto-backup schedule for the UI.
class BackupScheduleState {
  final BackupFrequency frequency;
  final DateTime? lastBackup;

  const BackupScheduleState({required this.frequency, this.lastBackup});
}

/// Exposes + mutates the auto-backup frequency for the backup screen.
class BackupScheduleController extends AsyncNotifier<BackupScheduleState> {
  @override
  Future<BackupScheduleState> build() async {
    final scheduler = ref.read(backupSchedulerProvider);
    final frequency = await scheduler.getFrequency();
    final lastBackup = await scheduler.getLastBackupTime();
    return BackupScheduleState(frequency: frequency, lastBackup: lastBackup);
  }

  /// Persists a new frequency and refreshes the exposed state.
  Future<void> setFrequency(BackupFrequency frequency) async {
    final scheduler = ref.read(backupSchedulerProvider);
    await scheduler.setFrequency(frequency);
    final lastBackup = await scheduler.getLastBackupTime();
    state = AsyncData(
      BackupScheduleState(frequency: frequency, lastBackup: lastBackup),
    );
  }
}

final backupScheduleControllerProvider =
    AsyncNotifierProvider<BackupScheduleController, BackupScheduleState>(
      BackupScheduleController.new,
    );
