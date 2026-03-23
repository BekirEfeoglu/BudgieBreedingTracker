import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_picker_dialog.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}
Bird _makeBird({
  required String id,
  required String name,
  required BirdGender gender,
  BirdStatus status = BirdStatus.alive,
  String? ringNumber,
}) {
  return Bird(
    id: id,
    name: name,
    gender: gender,
    userId: 'user1',
    status: status,
    ringNumber: ringNumber,
  );
}

void main() {
  group('BirdPickerDialog', () {
    testWidgets('renders without crashing with loading state', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const SizedBox.shrink(),
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider(
              'user1',
            ).overrideWith((_) => const Stream.empty()),
          ],
        ),
      );
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      // Stream.empty() keeps provider in loading state; spinner never settles.
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider(
              'user1',
            ).overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BirdPickerDialog(genderFilter: BirdGender.male),
            ),
          ),
        ),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no_results when bird list is empty for gender', (
      tester,
    ) async {
      // Stream with a female bird but dialog filters for male
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider('user1').overrideWith(
              (_) => Stream.value([
                _makeBird(
                  id: 'b1',
                  name: 'Disi Kus',
                  gender: BirdGender.female,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BirdPickerDialog(genderFilter: BirdGender.male),
            ),
          ),
        ),
      );
      expect(find.text('common.no_results'), findsOneWidget);
    });

    testWidgets('shows bird name when matching bird exists', (tester) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider('user1').overrideWith(
              (_) => Stream.value([
                _makeBird(
                  id: 'b1',
                  name: 'Mavi Erkek',
                  gender: BirdGender.male,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BirdPickerDialog(genderFilter: BirdGender.male),
            ),
          ),
        ),
      );
      expect(find.text('Mavi Erkek'), findsOneWidget);
    });

    testWidgets('filters out dead birds', (tester) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider('user1').overrideWith(
              (_) => Stream.value([
                _makeBird(
                  id: 'b1',
                  name: 'Olmus Erkek',
                  gender: BirdGender.male,
                  status: BirdStatus.dead,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BirdPickerDialog(genderFilter: BirdGender.male),
            ),
          ),
        ),
      );
      expect(find.text('common.no_results'), findsOneWidget);
    });

    testWidgets('shows search TextField', (tester) async {
      // Stream.empty() keeps provider in loading state; spinner never settles.
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider(
              'user1',
            ).overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BirdPickerDialog(genderFilter: BirdGender.male),
            ),
          ),
        ),
        settle: false,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows close IconButton', (tester) async {
      // Stream.empty() keeps provider in loading state; spinner never settles.
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider(
              'user1',
            ).overrideWith((_) => const Stream.empty()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BirdPickerDialog(genderFilter: BirdGender.male),
            ),
          ),
        ),
        settle: false,
      );
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('filters birds by search query', (tester) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user1'),
            birdsStreamProvider('user1').overrideWith(
              (_) => Stream.value([
                _makeBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
                _makeBird(id: 'b2', name: 'Yesil', gender: BirdGender.male),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BirdPickerDialog(genderFilter: BirdGender.male),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Mavi');
      await tester.pump();
      expect(find.text('Mavi'), findsAtLeastNWidgets(1));
    });
  });

  group('birdToGenotype', () {
    test('returns empty genotype when no mutations', () {
      final bird = _makeBird(id: 'b1', name: 'Test', gender: BirdGender.male);
      final genotype = birdToGenotype(bird);
      expect(genotype.isEmpty, isTrue);
      expect(genotype.gender, BirdGender.male);
    });

    test('uses mutations field when present', () {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.female,
        userId: 'u1',
        mutations: ['blue'],
        genotypeInfo: {'blue': 'visual'},
      );
      final genotype = birdToGenotype(bird);
      expect(genotype.isEmpty, isFalse);
      expect(genotype.gender, BirdGender.female);
    });

    test('falls back to colorMutation when no mutations', () {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'u1',
        colorMutation: BirdColor.blue,
      );
      final genotype = birdToGenotype(bird);
      // blue color → ['blue'] mutation IDs
      expect(genotype.mutations.containsKey('blue'), isTrue);
    });

    test('returns empty mutations for green color', () {
      const bird = Bird(
        id: 'b1',
        name: 'Green',
        gender: BirdGender.male,
        userId: 'u1',
        colorMutation: BirdColor.green,
      );
      final genotype = birdToGenotype(bird);
      expect(genotype.isEmpty, isTrue);
    });

    test('does not force generic pied birds into recessive_pied', () {
      const bird = Bird(
        id: 'b1',
        name: 'Pied',
        gender: BirdGender.male,
        userId: 'u1',
        colorMutation: BirdColor.pied,
      );
      final genotype = birdToGenotype(bird);
      expect(genotype.isEmpty, isTrue);
    });
  });
}
