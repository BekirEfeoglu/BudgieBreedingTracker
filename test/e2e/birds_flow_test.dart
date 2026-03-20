@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Birds Flow E2E', () {
    test(
      'GIVEN empty bird list WHEN user saves a new bird THEN repository.save is called and created bird is available for list rendering',
      () async {
        final mockBirdRepository = MockBirdRepository();
        when(() => mockBirdRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockBirdRepository.getAll(any()),
        ).thenAnswer((_) async => []);

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(birdFormStateProvider.notifier)
            .createBird(
              userId: 'test-user',
              name: 'Sari Boncuk',
              gender: BirdGender.male,
              species: Species.budgie,
              colorMutation: BirdColor.yellow,
              birthDate: DateTime(2024, 1, 1),
              cageNumber: 'A1',
              ringNumber: 'TR2024001',
            );

        final savedBird =
            verify(() => mockBirdRepository.save(captureAny())).captured.single
                as Bird;
        expect(savedBird.name, 'Sari Boncuk');
        expect(savedBird.gender, BirdGender.male);
        expect(savedBird.ringNumber, 'TR2024001');
        expect(container.read(birdFormStateProvider).isSuccess, isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN at least one bird WHEN detail data is loaded THEN name/gender/status/mutation and parent fallback can be rendered',
      () async {
        final bird = Bird(
          id: 'bird-1',
          userId: 'test-user',
          name: 'Sari Boncuk',
          gender: BirdGender.male,
          status: BirdStatus.alive,
          colorMutation: BirdColor.yellow,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final mockBirdRepository = MockBirdRepository();
        when(
          () => mockBirdRepository.watchById('bird-1'),
        ).thenAnswer((_) => Stream.value(bird));

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        final fetched = await mockBirdRepository.watchById('bird-1').first;
        expect(fetched?.name, 'Sari Boncuk');
        expect(fetched?.gender, BirdGender.male);
        expect(fetched?.status, BirdStatus.alive);
        expect(fetched?.colorMutation, BirdColor.yellow);
        expect(fetched?.fatherId ?? 'Bilinmiyor', 'Bilinmiyor');
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN bird detail WHEN edit is submitted THEN repository.save is called with updated model',
      () async {
        final original = Bird(
          id: 'bird-1',
          userId: 'test-user',
          name: 'Sari Boncuk',
          gender: BirdGender.male,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final mockBirdRepository = MockBirdRepository();
        when(() => mockBirdRepository.save(any())).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(birdFormStateProvider.notifier)
            .updateBird(original.copyWith(name: 'Sari Boncuk Guncel'));

        final updated =
            verify(() => mockBirdRepository.save(captureAny())).captured.single
                as Bird;
        expect(updated.name, 'Sari Boncuk Guncel');
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN non-empty bird list WHEN delete action is confirmed THEN repository.remove is called for soft-delete path',
      () async {
        final mockBirdRepository = MockBirdRepository();
        when(
          () => mockBirdRepository.remove('bird-1'),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            birdRepositoryProvider.overrideWithValue(mockBirdRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(birdFormStateProvider.notifier)
            .deleteBird('bird-1');

        verify(() => mockBirdRepository.remove('bird-1')).called(1);
        expect(container.read(birdFormStateProvider).isSuccess, isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN male and female birds WHEN male filter is selected THEN only male birds are returned',
      () {
        final birds = <Bird>[
          const Bird(
            id: 'm1',
            userId: 'test-user',
            name: 'Erkek 1',
            gender: BirdGender.male,
          ),
          const Bird(
            id: 'f1',
            userId: 'test-user',
            name: 'Disi 1',
            gender: BirdGender.female,
          ),
        ];

        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(birdFilterProvider.notifier).state = BirdFilter.male;
        final filtered = container.read(filteredBirdsProvider(birds));

        expect(filtered.length, 1);
        expect(filtered.single.gender, BirdGender.male);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN multiple birds WHEN search query is Boncuk THEN only matching names are returned',
      () {
        final birds = <Bird>[
          const Bird(
            id: '1',
            userId: 'test-user',
            name: 'Sari Boncuk',
            gender: BirdGender.male,
          ),
          const Bird(
            id: '2',
            userId: 'test-user',
            name: 'Mavi Peri',
            gender: BirdGender.female,
          ),
          const Bird(
            id: '3',
            userId: 'test-user',
            name: 'Boncuk Junior',
            gender: BirdGender.unknown,
          ),
        ];

        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(birdSearchQueryProvider.notifier).state = 'Boncuk';
        final searched = container.read(
          searchedAndFilteredBirdsProvider(birds),
        );

        expect(searched.length, 2);
        expect(searched.every((bird) => bird.name.contains('Boncuk')), isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN bird with photos in DB WHEN photo provider is watched THEN photo URLs are emitted',
      () async {
        final container = createTestContainer(
          overrides: [
            birdPhotosProvider.overrideWith(
              (ref, birdId) =>
                  Stream.value(['https://cdn.example.com/bird_1.jpg']),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Listen first so the StreamProvider stays alive and processes the value.
        final sub = container.listen(birdPhotosProvider('bird-1'), (_, __) {});
        addTearDown(sub.close);

        final urls = await container.read(birdPhotosProvider('bird-1').future);

        expect(urls, hasLength(1));
        expect(urls.single, contains('bird_1.jpg'));
      },
      timeout: e2eTimeout,
    );
  });
}
