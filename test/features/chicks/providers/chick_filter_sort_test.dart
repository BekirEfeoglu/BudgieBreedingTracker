import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // ChickFilter enum
  // ---------------------------------------------------------------------------
  group('ChickFilter', () {
    test('has 9 values', () {
      expect(ChickFilter.values, hasLength(9));
    });

    test('contains expected values', () {
      expect(
        ChickFilter.values,
        containsAll([
          ChickFilter.all,
          ChickFilter.healthy,
          ChickFilter.sick,
          ChickFilter.deceased,
          ChickFilter.unweaned,
          ChickFilter.newborn,
          ChickFilter.nestling,
          ChickFilter.fledgling,
          ChickFilter.juvenile,
        ]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ChickSort enum
  // ---------------------------------------------------------------------------
  group('ChickSort', () {
    test('has 6 values', () {
      expect(ChickSort.values, hasLength(6));
    });

    test('contains expected values', () {
      expect(
        ChickSort.values,
        containsAll([
          ChickSort.newest,
          ChickSort.oldest,
          ChickSort.nameAsc,
          ChickSort.nameDesc,
          ChickSort.ageYoungest,
          ChickSort.ageOldest,
        ]),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // ChickFilterNotifier
  // ---------------------------------------------------------------------------
  group('ChickFilterNotifier', () {
    test('initial state is ChickFilter.all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(chickFilterProvider), ChickFilter.all);
    });

    test('state can be changed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(chickFilterProvider.notifier).state = ChickFilter.sick;
      expect(container.read(chickFilterProvider), ChickFilter.sick);

      container.read(chickFilterProvider.notifier).state =
          ChickFilter.deceased;
      expect(container.read(chickFilterProvider), ChickFilter.deceased);
    });
  });

  // ---------------------------------------------------------------------------
  // ChickSearchQueryNotifier
  // ---------------------------------------------------------------------------
  group('ChickSearchQueryNotifier', () {
    test('initial state is empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(chickSearchQueryProvider), isEmpty);
    });

    test('state can be changed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(chickSearchQueryProvider.notifier).state = 'tweety';
      expect(container.read(chickSearchQueryProvider), 'tweety');
    });
  });

  // ---------------------------------------------------------------------------
  // ChickSortNotifier
  // ---------------------------------------------------------------------------
  group('ChickSortNotifier', () {
    test('initial state is ChickSort.newest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(chickSortProvider), ChickSort.newest);
    });

    test('setSort updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(chickSortProvider.notifier)
          .setSort(ChickSort.nameAsc);

      expect(container.read(chickSortProvider), ChickSort.nameAsc);
    });

    test('setSort persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(chickSortProvider.notifier)
          .setSort(ChickSort.oldest);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppPreferences.keyChickSort), 'oldest');
    });

    test('restores persisted sort from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyChickSort: 'nameDesc',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Synchronous build returns newest; async _loadFromPrefs updates later
      expect(container.read(chickSortProvider), ChickSort.newest);

      // Allow the async _loadFromPrefs to complete
      await Future<void>.delayed(Duration.zero);

      expect(container.read(chickSortProvider), ChickSort.nameDesc);
    });
  });
}
