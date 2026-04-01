import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';

import '../../../helpers/test_fixtures.dart';

void main() {
  group('maleBirdsProvider', () {
    test('returns only alive male birds', () {
      final birds = [
        createTestBird(
          id: 'b1',
          name: 'Alive Male',
          gender: BirdGender.male,
          status: BirdStatus.alive,
          userId: 'u1',
        ),
        createTestBird(
          id: 'b2',
          name: 'Dead Male',
          gender: BirdGender.male,
          status: BirdStatus.dead,
          userId: 'u1',
        ),
        createTestBird(
          id: 'b3',
          name: 'Sold Male',
          gender: BirdGender.male,
          status: BirdStatus.sold,
          userId: 'u1',
        ),
        createTestBird(
          id: 'b4',
          name: 'Alive Female',
          gender: BirdGender.female,
          status: BirdStatus.alive,
          userId: 'u1',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          birdsStreamProvider('u1').overrideWithValue(AsyncData(birds)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(maleBirdsProvider('u1'));
      expect(result.length, 1);
      expect(result.first.id, 'b1');
      expect(result.first.name, 'Alive Male');
    });

    test('returns empty list when no alive males exist', () {
      final birds = [
        createTestBird(
          id: 'b1',
          name: 'Dead Male',
          gender: BirdGender.male,
          status: BirdStatus.dead,
          userId: 'u1',
        ),
        createTestBird(
          id: 'b2',
          name: 'Alive Female',
          gender: BirdGender.female,
          status: BirdStatus.alive,
          userId: 'u1',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          birdsStreamProvider('u1').overrideWithValue(AsyncData(birds)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(maleBirdsProvider('u1'));
      expect(result, isEmpty);
    });

    test('returns empty list when stream is loading', () {
      final container = ProviderContainer(
        overrides: [
          birdsStreamProvider('u1')
              .overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(maleBirdsProvider('u1'));
      expect(result, isEmpty);
    });
  });

  group('femaleBirdsProvider', () {
    test('returns only alive female birds', () {
      final birds = [
        createTestBird(
          id: 'b1',
          name: 'Alive Female',
          gender: BirdGender.female,
          status: BirdStatus.alive,
          userId: 'u1',
        ),
        createTestBird(
          id: 'b2',
          name: 'Dead Female',
          gender: BirdGender.female,
          status: BirdStatus.dead,
          userId: 'u1',
        ),
        createTestBird(
          id: 'b3',
          name: 'Alive Male',
          gender: BirdGender.male,
          status: BirdStatus.alive,
          userId: 'u1',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          birdsStreamProvider('u1').overrideWithValue(AsyncData(birds)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(femaleBirdsProvider('u1'));
      expect(result.length, 1);
      expect(result.first.id, 'b1');
      expect(result.first.name, 'Alive Female');
    });

    test('returns empty list when no alive females exist', () {
      final birds = [
        createTestBird(
          id: 'b1',
          name: 'Dead Female',
          gender: BirdGender.female,
          status: BirdStatus.dead,
          userId: 'u1',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          birdsStreamProvider('u1').overrideWithValue(AsyncData(birds)),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(femaleBirdsProvider('u1'));
      expect(result, isEmpty);
    });

    test('returns empty list when stream is loading', () {
      final container = ProviderContainer(
        overrides: [
          birdsStreamProvider('u1')
              .overrideWithValue(const AsyncLoading()),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(femaleBirdsProvider('u1'));
      expect(result, isEmpty);
    });
  });
}
