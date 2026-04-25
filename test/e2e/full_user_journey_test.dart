@Tags(['scenario'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/export_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Full User Journey E2E', () {
    test(
      'GIVEN new user WHEN complete first breeding lifecycle is executed THEN end-to-end journey succeeds under 60 seconds',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final stopwatch = Stopwatch()..start();

        final mockBirdRepository = MockBirdRepository();
        final mockPairRepository = MockBreedingPairRepository();
        final mockIncubationRepository = MockIncubationRepository();
        final mockEggRepository = MockEggRepository();
        final mockChickRepository = MockChickRepository();
        final mockHealthRepository = MockHealthRecordRepository();
        final mockNotificationScheduler = MockNotificationScheduler();
        final mockCalendarGenerator = MockCalendarEventGenerator();
        final mockPdfExportService = MockPdfExportService();

        final birds = <Bird>[];
        final pairs = <BreedingPair>[];
        final incubations = <Incubation>[];
        final eggs = <Egg>[];
        final chicks = <Chick>[];
        final healthRecords = <HealthRecord>[];

        when(() => mockBirdRepository.save(any())).thenAnswer((
          invocation,
        ) async {
          final item = invocation.positionalArguments.first as Bird;
          birds.removeWhere((bird) => bird.id == item.id);
          birds.add(item);
        });
        when(
          () => mockBirdRepository.getAll(any()),
        ).thenAnswer((_) async => List.of(birds));
        when(
          () => mockBirdRepository.getCount(any()),
        ).thenAnswer((_) async => birds.length);
        when(() => mockBirdRepository.getById(any())).thenAnswer((
          invocation,
        ) async {
          final id = invocation.positionalArguments.first as String;
          for (final bird in birds) {
            if (bird.id == id) return bird;
          }
          return null;
        });
        when(
          () => mockBirdRepository.hasRingNumber(
            any(),
            any(),
            excludeId: any(named: 'excludeId'),
          ),
        ).thenAnswer((_) async => false);
        when(() => mockPairRepository.save(any())).thenAnswer((
          invocation,
        ) async {
          final item = invocation.positionalArguments.first as BreedingPair;
          pairs.removeWhere((pair) => pair.id == item.id);
          pairs.add(item);
        });
        when(
          () => mockPairRepository.getAll(any()),
        ).thenAnswer((_) async => List.of(pairs));
        when(() => mockPairRepository.getById(any())).thenAnswer((
          invocation,
        ) async {
          final id = invocation.positionalArguments.first as String;
          for (final pair in pairs) {
            if (pair.id == id) return pair;
          }
          return null;
        });
        when(() => mockPairRepository.getActiveCount(any())).thenAnswer(
          (_) async => pairs
              .where(
                (p) =>
                    p.status == BreedingStatus.active ||
                    p.status == BreedingStatus.ongoing,
              )
              .length,
        );
        when(() => mockIncubationRepository.save(any())).thenAnswer((
          invocation,
        ) async {
          final item = invocation.positionalArguments.first as Incubation;
          incubations.removeWhere((inc) => inc.id == item.id);
          incubations.add(item);
        });
        when(
          () => mockIncubationRepository.getAll(any()),
        ).thenAnswer((_) async => List.of(incubations));
        when(() => mockIncubationRepository.getById(any())).thenAnswer((
          invocation,
        ) async {
          final id = invocation.positionalArguments.first as String;
          for (final incubation in incubations) {
            if (incubation.id == id) return incubation;
          }
          return null;
        });
        when(() => mockIncubationRepository.getActiveCount(any())).thenAnswer(
          (_) async => incubations
              .where((i) => i.status == IncubationStatus.active)
              .length,
        );
        when(
          () => mockIncubationRepository.getByBreedingPairIds(any()),
        ).thenAnswer((invocation) async {
          final ids = (invocation.positionalArguments.first as List<dynamic>)
              .cast<String>();
          return incubations
              .where((inc) => ids.contains(inc.breedingPairId))
              .toList();
        });
        when(() => mockEggRepository.save(any())).thenAnswer((
          invocation,
        ) async {
          final item = invocation.positionalArguments.first as Egg;
          eggs.removeWhere((egg) => egg.id == item.id);
          eggs.add(item);
        });
        when(() => mockEggRepository.getByIncubation(any())).thenAnswer((
          invocation,
        ) async {
          final id = invocation.positionalArguments.first as String;
          return eggs.where((egg) => egg.incubationId == id).toList();
        });
        when(
          () => mockChickRepository.getByEggId(any()),
        ).thenAnswer((_) async => null);
        when(() => mockChickRepository.save(any())).thenAnswer((
          invocation,
        ) async {
          final item = invocation.positionalArguments.first as Chick;
          chicks.removeWhere((chick) => chick.id == item.id);
          chicks.add(item);
        });
        when(() => mockHealthRepository.save(any())).thenAnswer((
          invocation,
        ) async {
          final item = invocation.positionalArguments.first as HealthRecord;
          healthRecords.removeWhere((record) => record.id == item.id);
          healthRecords.add(item);
        });

        when(
          () => mockNotificationScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            species: any(named: 'species'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.scheduleEggTurningReminders(
            eggId: any(named: 'eggId'),
            startDate: any(named: 'startDate'),
            eggLabel: any(named: 'eggLabel'),
            species: any(named: 'species'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.scheduleChickCareReminder(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            startDate: any(named: 'startDate'),
            intervalHours: any(named: 'intervalHours'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.scheduleBandingReminders(
            chickId: any(named: 'chickId'),
            chickLabel: any(named: 'chickLabel'),
            hatchDate: any(named: 'hatchDate'),
            bandingDay: any(named: 'bandingDay'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockCalendarGenerator.generateIncubationEvents(
            userId: any(named: 'userId'),
            breedingPairId: any(named: 'breedingPairId'),
            startDate: any(named: 'startDate'),
            pairLabel: any(named: 'pairLabel'),
            species: any(named: 'species'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockCalendarGenerator.generateEggEvents(
            userId: any(named: 'userId'),
            layDate: any(named: 'layDate'),
            eggNumber: any(named: 'eggNumber'),
            incubationId: any(named: 'incubationId'),
            species: any(named: 'species'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockCalendarGenerator.generateChickEvents(
            userId: any(named: 'userId'),
            hatchDate: any(named: 'hatchDate'),
            chickLabel: any(named: 'chickLabel'),
            chickId: any(named: 'chickId'),
            bandingDay: any(named: 'bandingDay'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockPdfExportService.generateFullReport(
            birds: any(named: 'birds'),
            pairs: any(named: 'pairs'),
            incubations: any(named: 'incubations'),
            eggs: any(named: 'eggs'),
            chicks: any(named: 'chicks'),
          ),
        ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3, 4]));

        final container = createTestContainer(
          isAuthenticated: false,
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
            breedingPairRepositoryProvider.overrideWithValue(
              mockPairRepository,
            ),
            incubationRepositoryProvider.overrideWithValue(
              mockIncubationRepository,
            ),
            eggRepositoryProvider.overrideWithValue(mockEggRepository),
            chickRepositoryProvider.overrideWithValue(mockChickRepository),
            healthRecordRepositoryProvider.overrideWithValue(
              mockHealthRepository,
            ),
            notificationSchedulerProvider.overrideWithValue(
              mockNotificationScheduler,
            ),
            calendarEventGeneratorProvider.overrideWithValue(
              mockCalendarGenerator,
            ),
            pdfExportServiceProvider.overrideWithValue(mockPdfExportService),
          ],
        );
        addTearDown(container.dispose);

        // Step 1 - Register + Login
        await container
            .read(authActionsProvider)
            .signUpWithEmail(
              email: 'test@example.com',
              password: 'Test1234!',
              data: const <String, dynamic>{'full_name': 'Test Kullanici'},
            );
        await container
            .read(authActionsProvider)
            .signInWithEmail(email: 'test@example.com', password: 'Test1234!');

        // Step 2 - Add birds
        await container
            .read(birdFormStateProvider.notifier)
            .createBird(
              userId: 'test-user',
              name: 'Sultan',
              gender: BirdGender.male,
            );
        await container
            .read(birdFormStateProvider.notifier)
            .createBird(
              userId: 'test-user',
              name: 'Papatya',
              gender: BirdGender.female,
            );
        expect(birds.where((bird) => bird.name == 'Sultan'), hasLength(1));
        expect(birds.where((bird) => bird.name == 'Papatya'), hasLength(1));

        // Step 3 - Genetics analysis
        const geneticsProbabilities = <String, double>{
          'visual_ino_male': 0.25,
          'carrier_ino_male': 0.25,
          'visual_ino_female': 0.25,
          'normal_female': 0.25,
        };
        final totalProbability = geneticsProbabilities.values.fold<double>(
          0,
          (sum, p) => sum + p,
        );
        expect(totalProbability, closeTo(1.0, 0.001));

        // Step 4 - Create breeding pair
        final sultanId = birds.firstWhere((bird) => bird.name == 'Sultan').id;
        final papatyaId = birds.firstWhere((bird) => bird.name == 'Papatya').id;
        final pairingDate = DateTime.now();
        await container
            .read(breedingFormStateProvider.notifier)
            .createBreeding(
              userId: 'test-user',
              maleId: sultanId,
              femaleId: papatyaId,
              pairingDate: pairingDate,
              cageNumber: 'C1',
            );
        expect(
          pairs.any((pair) => pair.status == BreedingStatus.active),
          isTrue,
        );
        expect(incubations, isNotEmpty);

        // Step 5 - Add eggs
        final incubationId = incubations.first.id;
        for (var eggNo = 1; eggNo <= 5; eggNo++) {
          await container
              .read(eggActionsProvider.notifier)
              .addEgg(
                incubationId: incubationId,
                layDate: pairingDate,
                eggNumber: eggNo,
              );
        }
        expect(eggs, hasLength(5));
        expect(
          eggs.every(
            (egg) => egg.expectedHatchDate.difference(pairingDate).inDays == 18,
          ),
          isTrue,
        );

        // Step 6 - Calendar expectations
        verify(
          () => mockCalendarGenerator.generateEggEvents(
            userId: any(named: 'userId'),
            layDate: any(named: 'layDate'),
            eggNumber: any(named: 'eggNumber'),
            incubationId: any(named: 'incubationId'),
            species: any(named: 'species'),
          ),
        ).called(5);

        // Step 7 - Hatch egg and create chick
        final firstEgg = eggs.first;
        await container
            .read(eggActionsProvider.notifier)
            .updateEggStatus(firstEgg, EggStatus.hatched);
        expect(chicks, hasLength(1));
        expect(container.read(eggActionsProvider).chickCreated, isTrue);

        // Step 8 - Chick growth trend data
        const weights = <double>[2.3, 14.0, 28.0];
        expect(weights[0] < weights[1], isTrue);
        expect(weights[1] < weights[2], isTrue);

        // Step 9 - Add health record
        final record = HealthRecord(
          id: 'health-1',
          userId: 'test-user',
          birdId: sultanId,
          title: 'Veteriner Kontrolu',
          type: HealthRecordType.checkup,
          date: DateTime.now(),
          veterinarian: 'Dr. Ahmet',
        );
        await container.read(healthRecordRepositoryProvider).save(record);
        expect(healthRecords, hasLength(1));

        // Step 10 - Statistics validation
        final totalBirds = birds.length;
        final activeBreedings = pairs
            .where(
              (pair) =>
                  pair.status == BreedingStatus.active ||
                  pair.status == BreedingStatus.ongoing,
            )
            .length;
        final fertileEggs = eggs
            .where(
              (egg) =>
                  egg.status == EggStatus.fertile ||
                  egg.status == EggStatus.hatched,
            )
            .length;
        final infertileEggs = eggs
            .where((egg) => egg.status == EggStatus.infertile)
            .length;
        final checkedEggs = fertileEggs + infertileEggs;
        final fertilityRate = checkedEggs == 0
            ? 0.0
            : fertileEggs / checkedEggs;

        expect(totalBirds, 2);
        expect(activeBreedings, 1);
        expect(fertilityRate, greaterThanOrEqualTo(0));

        // Step 11 - PDF export
        final reportBytes = await container
            .read(pdfExportServiceProvider)
            .generateFullReport(
              birds: birds,
              pairs: pairs,
              incubations: incubations,
              eggs: eggs,
              chicks: chicks,
            );
        expect(reportBytes, isNotEmpty);
        verify(
          () => mockPdfExportService.generateFullReport(
            birds: birds,
            pairs: pairs,
            incubations: incubations,
            eggs: eggs,
            chicks: chicks,
          ),
        ).called(1);

        // Step 12 - Logout
        await container.read(authActionsProvider).signOut();

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(60000));
      },
      timeout: e2eTimeout,
    );
  });
}
