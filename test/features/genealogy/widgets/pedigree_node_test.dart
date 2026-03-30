import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/pedigree_node.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => NoTransitionPage(
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
      GoRoute(
        path: '/birds/:id',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Bird Detail'))),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

final _testBird = Bird(
  id: 'bird-1',
  userId: 'user-1',
  name: 'Yesil',
  gender: BirdGender.male,
  status: BirdStatus.alive,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

void main() {
  group('PedigreeNode', () {
    testWidgets('renders empty node when bird is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const PedigreeNode(bird: null, placeholder: 'Unknown')),
      );
      await tester.pump();

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('renders bird name when bird is provided', (tester) async {
      await tester.pumpWidget(_wrap(PedigreeNode(bird: _testBird)));
      await tester.pump();

      expect(find.text('Yesil'), findsOneWidget);
    });

    testWidgets('shows generation depth badge when depth >= 2', (tester) async {
      await tester.pumpWidget(_wrap(PedigreeNode(bird: _testBird, depth: 2)));
      await tester.pump();

      // Generation badge shows 'G2'
      expect(find.text('G2'), findsOneWidget);
    });

    testWidgets('hides generation badge when depth < 2', (tester) async {
      await tester.pumpWidget(_wrap(PedigreeNode(bird: _testBird, depth: 1)));
      await tester.pump();

      expect(find.text('G1'), findsNothing);
    });

    testWidgets('shows ring number when set', (tester) async {
      final bird = _testBird.copyWith(ringNumber: 'TR-123');

      await tester.pumpWidget(_wrap(PedigreeNode(bird: bird)));
      await tester.pump();

      expect(find.text('TR-123'), findsOneWidget);
    });

    testWidgets('shows siblings count when > 0', (tester) async {
      await tester.pumpWidget(
        _wrap(PedigreeNode(bird: _testBird, siblingCount: 3)),
      );
      await tester.pump();

      // .tr(args:['3']) returns key in tests — assert on key presence
      expect(find.text(l10n('genealogy.siblings_count')), findsOneWidget);
    });

    testWidgets('calls custom onTap when provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _wrap(PedigreeNode(bird: _testBird, onTap: () => tapped = true)),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });

    testWidgets(
      'renders default placeholder when bird is null and no placeholder set',
      (tester) async {
        await tester.pumpWidget(_wrap(const PedigreeNode(bird: null)));
        await tester.pump();

        // Default placeholder is '?'
        expect(find.text('?'), findsOneWidget);
      },
    );
  });
}
