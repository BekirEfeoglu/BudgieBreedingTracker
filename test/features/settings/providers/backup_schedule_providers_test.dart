import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/backup/backup_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/backup_schedule_providers.dart';

/// Implements the scheduler interface without its BackupService-dependent
/// constructor, so the controller can be tested in isolation.
class _FakeBackupScheduler implements BackupScheduler {
  _FakeBackupScheduler(this._frequency, {this.lastBackup});
  BackupFrequency _frequency;
  DateTime? lastBackup;
  final List<BackupFrequency> setCalls = [];

  @override
  Future<BackupFrequency> getFrequency() async => _frequency;

  @override
  Future<DateTime?> getLastBackupTime() async => lastBackup;

  @override
  Future<void> setFrequency(BackupFrequency frequency) async {
    setCalls.add(frequency);
    _frequency = frequency;
  }

  @override
  Future<void> cancelAutoBackup() async => setFrequency(BackupFrequency.never);

  @override
  Future<bool> shouldRunBackup() async => false;

  @override
  Future<BackupResult?> runIfScheduled(String userId) async => null;
}

void main() {
  group('BackupScheduleController', () {
    test('build exposes the persisted frequency and last-backup time', () async {
      final last = DateTime.utc(2026, 7, 1, 8);
      final scheduler = _FakeBackupScheduler(
        BackupFrequency.weekly,
        lastBackup: last,
      );
      final container = ProviderContainer(
        overrides: [backupSchedulerProvider.overrideWithValue(scheduler)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        backupScheduleControllerProvider.future,
      );

      expect(state.frequency, BackupFrequency.weekly);
      expect(state.lastBackup, last);
    });

    test('setFrequency persists and updates the exposed state', () async {
      final scheduler = _FakeBackupScheduler(BackupFrequency.never);
      final container = ProviderContainer(
        overrides: [backupSchedulerProvider.overrideWithValue(scheduler)],
      );
      addTearDown(container.dispose);

      await container.read(backupScheduleControllerProvider.future);
      await container
          .read(backupScheduleControllerProvider.notifier)
          .setFrequency(BackupFrequency.daily);

      expect(scheduler.setCalls, contains(BackupFrequency.daily));
      expect(
        container.read(backupScheduleControllerProvider).value?.frequency,
        BackupFrequency.daily,
      );
    });
  });
}
