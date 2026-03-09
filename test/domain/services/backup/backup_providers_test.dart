import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/backup/backup_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';

class _MockBackupService extends Mock implements BackupService {}

void main() {
  test(
    'backupSchedulerProvider uses backupServiceProvider dependency',
    () async {
      SharedPreferences.setMockInitialValues({});

      final mockService = _MockBackupService();
      final container = ProviderContainer(
        overrides: [backupServiceProvider.overrideWithValue(mockService)],
      );
      addTearDown(container.dispose);

      final scheduler = container.read(backupSchedulerProvider);

      expect(scheduler, isA<BackupScheduler>());

      final result = await scheduler.runIfScheduled('user-1');
      expect(result, isNull);
      verifyNever(() => mockService.createBackup(any()));
    },
  );
}
