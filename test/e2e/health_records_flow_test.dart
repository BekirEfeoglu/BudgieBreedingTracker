@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Health Records Flow E2E', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'GIVEN bird detail health tab WHEN user saves a health record THEN repository.save is called',
      () async {
        final mockHealthRepository = MockHealthRecordRepository();
        final mockNotificationScheduler = MockNotificationScheduler();

        when(() => mockHealthRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.scheduleHealthCheckReminder(
            birdId: any(named: 'birdId'),
            birdName: any(named: 'birdName'),
            hour: any(named: 'hour'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            healthRecordRepositoryProvider.overrideWithValue(
              mockHealthRepository,
            ),
            notificationSchedulerProvider.overrideWithValue(
              mockNotificationScheduler,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'test-user',
              birdId: 'bird-1',
              title: 'Ust solunum yolu enfeksiyonu',
              type: HealthRecordType.illness,
              date: DateTime.now(),
              treatment: 'Antibiyotik kuru',
              veterinarian: 'Dr. Ahmet',
            );

        final savedRecord =
            verify(
                  () => mockHealthRepository.save(captureAny()),
                ).captured.single
                as HealthRecord;
        expect(savedRecord.type, HealthRecordType.illness);
        expect(savedRecord.veterinarian, 'Dr. Ahmet');
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN mixed health records WHEN illness filter is selected THEN only illness records are returned',
      () {
        final records = <HealthRecord>[
          HealthRecord(
            id: '1',
            userId: 'test-user',
            title: 'A',
            type: HealthRecordType.illness,
            date: DateTime(2025, 1, 1),
          ),
          HealthRecord(
            id: '2',
            userId: 'test-user',
            title: 'B',
            type: HealthRecordType.checkup,
            date: DateTime(2025, 1, 2),
          ),
        ];

        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(healthRecordFilterProvider.notifier).state =
            HealthRecordFilter.illness;

        final filtered = container.read(filteredHealthRecordsProvider(records));
        expect(filtered.length, 1);
        expect(filtered.single.type, HealthRecordType.illness);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN health detail WHEN record is updated then deleted THEN save and remove calls are performed',
      () async {
        final mockHealthRepository = MockHealthRecordRepository();
        when(() => mockHealthRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockHealthRepository.remove('rec-1'),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            healthRecordRepositoryProvider.overrideWithValue(
              mockHealthRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final record = HealthRecord(
          id: 'rec-1',
          userId: 'test-user',
          title: 'Kontrol',
          type: HealthRecordType.checkup,
          date: DateTime.now(),
          treatment: 'Eski ilac',
        );

        await container
            .read(healthRecordFormStateProvider.notifier)
            .updateRecord(record.copyWith(treatment: 'Yeni ilac'));
        await container
            .read(healthRecordFormStateProvider.notifier)
            .deleteRecord('rec-1');

        final updated =
            verify(
                  () => mockHealthRepository.save(captureAny()),
                ).captured.single
                as HealthRecord;
        expect(updated.treatment, 'Yeni ilac');
        verify(() => mockHealthRepository.remove('rec-1')).called(1);
      },
      timeout: e2eTimeout,
    );
  });
}
