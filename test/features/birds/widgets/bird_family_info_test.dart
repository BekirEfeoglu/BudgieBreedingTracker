import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_family_info.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BirdFamilyInfo', () {
    testWidgets('shows nothing when no birds data', (tester) async {
      final bird = createTestBird(id: 'bird-1');

      await _pump(
        tester,
        BirdFamilyInfo(bird: bird),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => const Stream.empty(),
          ),
        ],
      );

      expect(find.text('birds.family_info'), findsNothing);
    });

    testWidgets('shows nothing when no offspring or siblings', (tester) async {
      final bird = createTestBird(id: 'bird-1', fatherId: null, motherId: null);
      final otherBird = createTestBird(
        id: 'bird-2',
        name: 'Other',
        fatherId: null,
        motherId: null,
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: bird),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([bird, otherBird]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('birds.family_info'), findsNothing);
    });

    testWidgets('shows offspring section when bird has children', (
      tester,
    ) async {
      final parent = createTestBird(id: 'parent-1', name: 'Ebeveyn');
      final child1 = createTestBird(
        id: 'child-1',
        name: 'Yavru1',
        fatherId: 'parent-1',
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: parent),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([parent, child1]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('birds.family_info'), findsOneWidget);
      expect(find.textContaining('birds.offspring'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows offspring chip with bird name', (tester) async {
      final parent = createTestBird(id: 'parent-1', name: 'Ebeveyn');
      final child = createTestBird(
        id: 'child-1',
        name: 'Yavru',
        fatherId: 'parent-1',
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: parent),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([parent, child]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Yavru'), findsOneWidget);
    });

    testWidgets('shows siblings section when birds share a parent', (
      tester,
    ) async {
      final father = createTestBird(id: 'father-1', name: 'Baba');
      final bird = createTestBird(
        id: 'bird-1',
        name: 'Kus1',
        fatherId: 'father-1',
      );
      final sibling = createTestBird(
        id: 'bird-2',
        name: 'Kardes',
        fatherId: 'father-1',
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: bird),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([father, bird, sibling]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('birds.siblings'), findsAtLeastNWidgets(1));
      expect(find.text('Kardes'), findsOneWidget);
    });

    testWidgets('shows ring number in chip when bird has ring', (tester) async {
      final parent = createTestBird(id: 'parent-1', name: 'Ebeveyn');
      final child = createTestBird(
        id: 'child-1',
        name: 'Yavru',
        fatherId: 'parent-1',
        ringNumber: 'TR-001',
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: parent),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([parent, child]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('TR-001'), findsOneWidget);
    });

    testWidgets('bird is excluded from its own sibling list', (tester) async {
      final father = createTestBird(id: 'father-1', name: 'Baba');
      final bird = createTestBird(
        id: 'bird-1',
        name: 'Kus1',
        fatherId: 'father-1',
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: bird),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([father, bird]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // No siblings except itself
      expect(find.text('birds.siblings'), findsNothing);
    });

    testWidgets('shows both offspring and siblings when applicable', (
      tester,
    ) async {
      final father = createTestBird(id: 'father-1', name: 'Baba');
      final bird = createTestBird(
        id: 'bird-1',
        name: 'Ana Kus',
        fatherId: 'father-1',
      );
      final sibling = createTestBird(
        id: 'sibling-1',
        name: 'Kardes',
        fatherId: 'father-1',
      );
      final offspring = createTestBird(
        id: 'off-1',
        name: 'Yavru',
        fatherId: 'bird-1',
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: bird),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([father, bird, sibling, offspring]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('birds.offspring'), findsAtLeastNWidgets(1));
      expect(find.textContaining('birds.siblings'), findsAtLeastNWidgets(1));
    });
  });

  group('BirdFamilyInfo._findSiblings', () {
    // Test the sibling logic via widget behavior (indirect)
    testWidgets('birds share only same mother are siblings', (tester) async {
      final mother = createTestBird(
        id: 'mother-1',
        name: 'Anne',
        gender: BirdGender.female,
      );
      final bird = createTestBird(
        id: 'bird-1',
        name: 'Kus1',
        motherId: 'mother-1',
      );
      final sibling = createTestBird(
        id: 'bird-2',
        name: 'Kardes',
        motherId: 'mother-1',
      );

      await _pump(
        tester,
        BirdFamilyInfo(bird: bird),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([mother, bird, sibling]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Kardes'), findsOneWidget);
    });
  });
}
