import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/backup/backup_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockBackupService mockBackupService;
  late BackupScheduler scheduler;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockBackupService = MockBackupService();
    scheduler = BackupScheduler(mockBackupService);
  });

  group('BackupScheduler', () {
    test('setFrequency and getFrequency persist preference', () async {
      await scheduler.setFrequency(BackupFrequency.weekly);
      expect(await scheduler.getFrequency(), BackupFrequency.weekly);
    });

    test('getFrequency falls back to never on invalid value', () async {
      SharedPreferences.setMockInitialValues({'backup_frequency': 'invalid'});
      scheduler = BackupScheduler(mockBackupService);
      expect(await scheduler.getFrequency(), BackupFrequency.never);
    });

    test('cancelAutoBackup sets frequency to never', () async {
      await scheduler.setFrequency(BackupFrequency.daily);
      await scheduler.cancelAutoBackup();
      expect(await scheduler.getFrequency(), BackupFrequency.never);
    });

    test('shouldRunBackup is false when frequency is never', () async {
      await scheduler.setFrequency(BackupFrequency.never);
      expect(await scheduler.shouldRunBackup(), isFalse);
    });

    test('shouldRunBackup is true when never backed up before', () async {
      await scheduler.setFrequency(BackupFrequency.daily);
      expect(await scheduler.shouldRunBackup(), isTrue);
    });

    test('shouldRunBackup is false when interval has not elapsed', () async {
      final nowIso = DateTime.now().toIso8601String();
      SharedPreferences.setMockInitialValues({
        'backup_frequency': BackupFrequency.daily.name,
        'backup_last_timestamp': nowIso,
      });
      scheduler = BackupScheduler(mockBackupService);

      expect(await scheduler.shouldRunBackup(), isFalse);
    });

    test('runIfScheduled returns null when backup is not due', () async {
      await scheduler.setFrequency(BackupFrequency.never);
      final result = await scheduler.runIfScheduled('user-1');

      expect(result, isNull);
      verifyNever(() => mockBackupService.createBackup(any()));
    });

    test(
      'runIfScheduled triggers backup and records timestamp on success',
      () async {
        when(() => mockBackupService.createBackup('user-1')).thenAnswer(
          (_) async => BackupResult.success(
            filePath: '/tmp/backup.json',
            recordCount: 10,
          ),
        );
        await scheduler.setFrequency(BackupFrequency.daily);

        final result = await scheduler.runIfScheduled('user-1');

        expect(result, isNotNull);
        expect(result!.success, isTrue);
        expect(await scheduler.getLastBackupTime(), isNotNull);
        verify(() => mockBackupService.createBackup('user-1')).called(1);
      },
    );

    test('runIfScheduled does not record timestamp on failed backup', () async {
      when(
        () => mockBackupService.createBackup('user-1'),
      ).thenAnswer((_) async => BackupResult.failure('failed'));
      await scheduler.setFrequency(BackupFrequency.daily);

      final result = await scheduler.runIfScheduled('user-1');

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(await scheduler.getLastBackupTime(), isNull);
    });
  });

  group('BackupFrequency', () {
    test('has all expected values', () {
      expect(BackupFrequency.values, hasLength(4));
      expect(BackupFrequency.values, containsAll([
        BackupFrequency.daily,
        BackupFrequency.weekly,
        BackupFrequency.monthly,
        BackupFrequency.never,
      ]));
    });

    test('interval returns correct durations', () {
      expect(BackupFrequency.daily.interval, const Duration(days: 1));
      expect(BackupFrequency.weekly.interval, const Duration(days: 7));
      expect(BackupFrequency.monthly.interval, const Duration(days: 30));
      expect(BackupFrequency.never.interval, Duration.zero);
    });

    test('labelKey returns localization keys', () {
      expect(BackupFrequency.daily.labelKey, 'settings.backup_daily');
      expect(BackupFrequency.weekly.labelKey, 'settings.backup_weekly');
      expect(BackupFrequency.monthly.labelKey, 'settings.backup_monthly');
      expect(BackupFrequency.never.labelKey, 'settings.backup_never');
    });

    test('all labelKeys start with settings.backup_', () {
      for (final freq in BackupFrequency.values) {
        expect(freq.labelKey, startsWith('settings.backup_'));
      }
    });
  });
}
