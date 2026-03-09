import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_scheduler.dart';

/// Provides a singleton [BackupService] with all repository dependencies
/// and optional encryption support via [EncryptionService].
final backupServiceProvider = Provider<BackupService>((ref) {
  final initialized = ref.watch(supabaseInitializedProvider);
  return BackupService(
    birdRepo: ref.watch(birdRepositoryProvider),
    breedingRepo: ref.watch(breedingPairRepositoryProvider),
    eggRepo: ref.watch(eggRepositoryProvider),
    chickRepo: ref.watch(chickRepositoryProvider),
    healthRepo: ref.watch(healthRecordRepositoryProvider),
    eventRepo: ref.watch(eventRepositoryProvider),
    incubationRepo: ref.watch(incubationRepositoryProvider),
    growthRepo: ref.watch(growthMeasurementRepositoryProvider),
    notificationRepo: ref.watch(notificationRepositoryProvider),
    clutchRepo: ref.watch(clutchRepositoryProvider),
    nestRepo: ref.watch(nestRepositoryProvider),
    photoRepo: ref.watch(photoRepositoryProvider),
    supabaseClient: initialized ? ref.watch(supabaseClientProvider) : null,
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provides a [BackupScheduler] that manages automatic backup scheduling.
final backupSchedulerProvider = Provider<BackupScheduler>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupScheduler(backupService);
});
