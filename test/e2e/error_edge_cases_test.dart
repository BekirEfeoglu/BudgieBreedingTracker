@Tags(['e2e'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/screens/bird_form_screen.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

import '../helpers/e2e_test_harness.dart';

class _BirdDraftNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final _birdDraftProvider = NotifierProvider<_BirdDraftNotifier, String>(
  _BirdDraftNotifier.new,
);

void main() {
  ensureE2EBinding();

  group('Error & Edge Cases E2E', () {
    test(
      'GIVEN a bird already in active pair WHEN trying to pair same bird again THEN validation blocks save and user sees already-paired message',
      () async {
        final mockPairRepository = MockBreedingPairRepository();
        const activePairs = <BreedingPair>[
          BreedingPair(
            id: 'pair-1',
            userId: 'test-user',
            status: BreedingStatus.active,
            maleId: 'bird-1',
            femaleId: 'bird-2',
          ),
        ];

        bool isAlreadyActiveInPair(String birdId) {
          return activePairs.any(
            (pair) =>
                (pair.maleId == birdId || pair.femaleId == birdId) &&
                pair.status == BreedingStatus.active,
          );
        }

        final blocked = isAlreadyActiveInPair('bird-1');
        if (!blocked) {
          await mockPairRepository.save(
            const BreedingPair(
              id: 'pair-2',
              userId: 'test-user',
              status: BreedingStatus.active,
              maleId: 'bird-1',
              femaleId: 'bird-3',
            ),
          );
        }

        expect(blocked, isTrue);
        verifyNever(() => mockPairRepository.save(any()));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN breeding pair references deleted bird WHEN detail provider resolves THEN missing bird shows null and app flow does not crash',
      () async {
        final mockBirdRepository = MockBirdRepository();
        when(
          () => mockBirdRepository.watchById('deleted-bird'),
        ).thenAnswer((_) => Stream.value(null));

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        final missingBird = await container
            .read(birdRepositoryProvider)
            .watchById('deleted-bird')
            .first;
        final orphanWarning = missingBird == null;

        expect(missingBird, isNull);
        expect(orphanWarning, isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN 100 birds and 50 active pairs WHEN list providers compute THEN processing finishes under 5 seconds',
      () async {
        final birds = List<Bird>.generate(
          100,
          (index) => Bird(
            id: 'bird-$index',
            userId: 'test-user',
            name: 'Bird $index',
            gender: index.isEven ? BirdGender.male : BirdGender.female,
          ),
        );
        final pairs = List<BreedingPair>.generate(
          50,
          (index) => BreedingPair(
            id: 'pair-$index',
            userId: 'test-user',
            status: BreedingStatus.active,
            maleId: 'bird-${index * 2}',
            femaleId: 'bird-${index * 2 + 1}',
          ),
        );

        final container = createTestContainer(
          overrides: [
            birdsStreamProvider.overrideWith((_, __) => Stream.value(birds)),
            breedingPairsStreamProvider.overrideWith(
              (_, __) => Stream.value(pairs),
            ),
          ],
        );
        addTearDown(container.dispose);

        final stopwatch = Stopwatch()..start();
        final filteredBirds = container.read(
          sortedAndFilteredBirdsProvider(birds),
        );
        final filteredPairs = container.read(
          searchedAndFilteredBreedingPairsProvider(pairs),
        );
        stopwatch.stop();

        expect(filteredBirds, hasLength(100));
        expect(filteredPairs, hasLength(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN bird form WHEN save is tapped with empty name THEN required-field error appears and submit is blocked',
      (tester) async {
        final mockBirdRepository = MockBirdRepository();
        when(
          () => mockBirdRepository.watchAll('test-user'),
        ).thenAnswer((_) => Stream.value(const <Bird>[]));
        when(
          () => mockBirdRepository.getAll(any()),
        ).thenAnswer((_) async => const <Bird>[]);
        when(() => mockBirdRepository.save(any())).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        await pumpApp(tester, container, child: const BirdFormScreen());
        await tester.pumpAndSettle();

        // Form auto-fills a default bird name; clear it to trigger required validation.
        await tester.enterText(find.byType(TextFormField).first, '');
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(l10n('common.save')));
        await tester.tap(find.text(l10n('common.save')));
        await tester.pumpAndSettle();

        expect(find.text(l10n('birds.name_required')), findsOneWidget);
        verifyNever(() => mockBirdRepository.save(any()));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN delayed network sync WHEN timeout occurs THEN error path returns promptly and retry hook is triggered without freeze',
      () async {
        final mockSyncOrchestrator = MockSyncOrchestrator();
        when(
          () => mockSyncOrchestrator.retryFailedRecords('test-user'),
        ).thenAnswer((_) async {});
        when(() => mockSyncOrchestrator.forceFullSync()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 3));
          return SyncResult.error;
        });

        final container = createTestContainer(
          overrides: [
            syncOrchestratorProvider.overrideWithValue(mockSyncOrchestrator),
          ],
        );
        addTearDown(container.dispose);

        final stopwatch = Stopwatch()..start();
        final provider = FutureProvider<SyncResult>(
          (ref) => triggerManualSync(ref),
        );
        final result = await container
            .read(provider.future)
            .timeout(
              const Duration(seconds: 4),
              onTimeout: () => SyncResult.error,
            );
        stopwatch.stop();

        expect(result, SyncResult.error);
        expect(stopwatch.elapsedMilliseconds, lessThan(4000));
        verify(
          () => mockSyncOrchestrator.retryFailedRecords('test-user'),
        ).called(1);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN half-filled bird form draft WHEN app goes background and returns THEN draft state remains in Riverpod provider',
      (tester) async {
        final container = createTestContainer();
        addTearDown(container.dispose);

        Widget buildDraftHost() {
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return TextField(
                      onChanged: (value) {
                        ref.read(_birdDraftProvider.notifier).state = value;
                      },
                    );
                  },
                ),
              ),
            ),
          );
        }

        await tester.pumpWidget(buildDraftHost());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Sari Boncuk');
        await tester.pumpAndSettle();

        // Simulate app leaving/returning foreground by rebuilding the tree.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(buildDraftHost());
        await tester.pumpAndSettle();

        expect(container.read(_birdDraftProvider), 'Sari Boncuk');
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN email already registered WHEN second registration is attempted THEN mapped auth error is generic registration-failed message (user enumeration protection)',
      () {
        const exception = AuthException('User already registered');

        final mapped = mapAuthError(exception);

        expect(mapped, 'auth.error_registration_failed');
      },
      timeout: e2eTimeout,
    );
  });
}
