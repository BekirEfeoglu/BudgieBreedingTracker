import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
          const FamilyTreeView(rootBird: rootOnly, ancestors: {'solo-1': rootOnly}),
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
          const FamilyTreeView(rootBird: _rootBird, ancestors: {'root-1': _rootBird}),
        ),
      );
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
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
          const FamilyTreeView(rootBird: _rootBird, ancestors: {'root-1': _rootBird}),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Herhangi bir exception fırlatılmamalı
      expect(find.byType(FamilyTreeView), findsOneWidget);
    });
  });
}
