import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/family_tree_view.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/pedigree_node.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/tree_connectors.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => NoTransitionPage(child: Scaffold(body: child)),
      ),
      GoRoute(
        path: '/birds/:id',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Bird Detail'))),
      ),
      GoRoute(
        path: '/chicks/:id',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Chick Detail'))),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

const _rootBird = Bird(
  id: 'root-1',
  userId: 'user-1',
  name: 'Kök Kuş',
  gender: BirdGender.male,
  status: BirdStatus.alive,
  fatherId: 'father-1',
  motherId: 'mother-1',
);

const _fatherBird = Bird(
  id: 'father-1',
  userId: 'user-1',
  name: 'Baba Kuş',
  gender: BirdGender.male,
  status: BirdStatus.alive,
);

const _motherBird = Bird(
  id: 'mother-1',
  userId: 'user-1',
  name: 'Anne Kuş',
  gender: BirdGender.female,
  status: BirdStatus.alive,
);

const _depthLimitedFather = Bird(
  id: 'father-depth-1',
  userId: 'user-1',
  name: 'Derin Baba',
  gender: BirdGender.male,
  status: BirdStatus.alive,
  fatherId: 'missing-grandfather',
);

void main() {
  group('FamilyTreeView', () {
    testWidgets('renders without crashing with minimal data', (tester) async {
      const rootOnly = Bird(
        id: 'solo-1',
        userId: 'user-1',
        name: 'Yalnız Kuş',
        gender: BirdGender.unknown,
        status: BirdStatus.alive,
      );

      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: rootOnly,
            ancestors: {'solo-1': rootOnly},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FamilyTreeView), findsOneWidget);
    });

    testWidgets('renders InteractiveViewer for pan and zoom', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {
              'root-1': _rootBird,
              'father-1': _fatherBird,
              'mother-1': _motherBird,
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('renders at least one PedigreeNode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {
              'root-1': _rootBird,
              'father-1': _fatherBird,
              'mother-1': _motherBird,
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PedigreeNode), findsAtLeastNWidgets(1));
    });

    testWidgets('renders FloatingActionButton for zoom reset', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {'root-1': _rootBird},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('zoom reset button meets 48dp minimum touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {'root-1': _rootBird},
          ),
        ),
      );
      await tester.pump();

      final size = tester.getSize(find.byType(FloatingActionButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets(
      'renders AncestorConnectorPainter CustomPaint when ancestors exist',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const FamilyTreeView(
              rootBird: _rootBird,
              ancestors: {
                'root-1': _rootBird,
                'father-1': _fatherBird,
                'mother-1': _motherBird,
              },
            ),
          ),
        );
        await tester.pump();

        // Tree'de bağlantı çizgileri CustomPaint olarak render edilmeli
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('renders OffspringConnectorPainter when offspring provided', (
      tester,
    ) async {
      const offspringBird = Bird(
        id: 'child-1',
        userId: 'user-1',
        name: 'Yavru',
        gender: BirdGender.male,
        status: BirdStatus.alive,
        fatherId: 'root-1',
      );

      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {'root-1': _rootBird},
            offspringBirds: [offspringBird],
          ),
        ),
      );
      await tester.pump();

      // Offspring connector CustomPaint render edilmeli
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('handles isRootChick flag without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {'root-1': _rootBird},
            isRootChick: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FamilyTreeView), findsOneWidget);
    });

    testWidgets('GenerationLabel renders inside tree when parents exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {
              'root-1': _rootBird,
              'father-1': _fatherBird,
              'mother-1': _motherBird,
            },
          ),
        ),
      );
      await tester.pump();

      // Father/mother line labels (depth==0) → GenerationLabel widget'ı
      expect(find.byType(GenerationLabel), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping zoom reset button does not crash', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: _rootBird,
            ancestors: {'root-1': _rootBird},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Herhangi bir exception fırlatılmamalı
      expect(find.byType(FamilyTreeView), findsOneWidget);
    });

    testWidgets('does not render placeholder ancestors beyond maxDepth', (
      tester,
    ) async {
      const root = Bird(
        id: 'root-depth-1',
        userId: 'user-1',
        name: 'Kök',
        gender: BirdGender.male,
        status: BirdStatus.alive,
        fatherId: 'father-depth-1',
        motherId: 'mother-1',
      );

      await tester.pumpWidget(
        _wrap(
          const FamilyTreeView(
            rootBird: root,
            maxDepth: 1,
            ancestors: {
              'root-depth-1': root,
              'father-depth-1': _depthLimitedFather,
              'mother-1': _motherBird,
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('genealogy.unknown_parent')), findsNothing);
    });

    testWidgets(
      'stops expanding a self-referencing cycle instead of repeating the '
      'same bird down to maxDepth',
      (tester) async {
        // Corrupted pedigree: cycle-1 is listed as its own father.
        const cycleBird = Bird(
          id: 'cycle-1',
          userId: 'user-1',
          name: 'Döngü Kuşu',
          gender: BirdGender.male,
          status: BirdStatus.alive,
          fatherId: 'cycle-1',
        );

        await tester.pumpWidget(
          _wrap(
            const FamilyTreeView(
              rootBird: cycleBird,
              maxDepth: 5,
              ancestors: {'cycle-1': cycleBird},
            ),
          ),
        );
        await tester.pump();

        // Without the path-scoped guard this would render 6 times
        // (depth 0..5), repeating the same bird down to maxDepth.
        expect(find.text('Döngü Kuşu'), findsOneWidget);
        expect(
          find.text(l10n('genealogy.unknown_parent')),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets(
      'still renders a legitimate common ancestor on both parental lines '
      '(not a cycle — different paths converging on the same bird)',
      (tester) async {
        const commonAncestor = Bird(
          id: 'common-1',
          userId: 'user-1',
          name: 'Ortak Ata',
          gender: BirdGender.male,
          status: BirdStatus.alive,
        );
        const father = Bird(
          id: 'father-common',
          userId: 'user-1',
          name: 'Baba',
          gender: BirdGender.male,
          status: BirdStatus.alive,
          fatherId: 'common-1',
        );
        const mother = Bird(
          id: 'mother-common',
          userId: 'user-1',
          name: 'Anne',
          gender: BirdGender.female,
          status: BirdStatus.alive,
          fatherId: 'common-1',
        );
        const root = Bird(
          id: 'root-common',
          userId: 'user-1',
          name: 'Kök',
          gender: BirdGender.male,
          status: BirdStatus.alive,
          fatherId: 'father-common',
          motherId: 'mother-common',
        );

        await tester.pumpWidget(
          _wrap(
            const FamilyTreeView(
              rootBird: root,
              maxDepth: 5,
              ancestors: {
                'root-common': root,
                'father-common': father,
                'mother-common': mother,
                'common-1': commonAncestor,
              },
            ),
          ),
        );
        await tester.pump();

        // Reached via both father-common and mother-common — a diamond,
        // not a cycle — so it must render in both positions.
        expect(find.text('Ortak Ata'), findsNWidgets(2));
      },
    );
  });
}
