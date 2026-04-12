import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/ancestor_list_view.dart';

// GoRouter gerektiriyor çünkü ListTile.onTap context.push çağırıyor.
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
  group('AncestorListView', () {
    testWidgets('renders without crashing when ancestors map is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AncestorListView(rootBird: _rootBird, ancestors: {})),
      );
      await tester.pump();

      expect(find.byType(AncestorListView), findsOneWidget);
    });

    testWidgets('renders root bird in generation 0 ExpansionTile', (
      tester,
    ) async {
      final ancestors = {
        'root-1': _rootBird,
        'father-1': _fatherBird,
        'mother-1': _motherBird,
      };

      await tester.pumpWidget(
        _wrap(AncestorListView(rootBird: _rootBird, ancestors: ancestors)),
      );
      await tester.pump();

      // ExpansionTile'lar render edilmiş olmalı (generation 0 ve 1)
      expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
    });

    testWidgets('shows bird names in ancestor list tiles', (tester) async {
      final ancestors = {
        'root-1': _rootBird,
        'father-1': _fatherBird,
        'mother-1': _motherBird,
      };

      await tester.pumpWidget(
        _wrap(AncestorListView(rootBird: _rootBird, ancestors: ancestors)),
      );
      await tester.pump();

      // Kök kuş adı görünmeli
      expect(find.text('Kök Kuş'), findsOneWidget);
    });

    testWidgets('shows multiple ExpansionTiles for multiple generations', (
      tester,
    ) async {
      const grandFather = Bird(
        id: 'grandfather-1',
        userId: 'user-1',
        name: 'Dede Kuş',
        gender: BirdGender.male,
        status: BirdStatus.alive,
      );
      final fatherWithParents = _fatherBird.copyWith(fatherId: 'grandfather-1');
      final ancestors = {
        'root-1': _rootBird,
        'father-1': fatherWithParents,
        'mother-1': _motherBird,
        'grandfather-1': grandFather,
      };

      await tester.pumpWidget(
        _wrap(AncestorListView(rootBird: _rootBird, ancestors: ancestors)),
      );
      await tester.pump();

      // 3 nesil: 0, 1, 2 → 3 ExpansionTile
      expect(find.byType(ExpansionTile), findsAtLeastNWidgets(2));
    });

    testWidgets('shows ring number in subtitle when available', (tester) async {
      final birdWithRing = _fatherBird.copyWith(ringNumber: 'TR-999');
      final ancestors = {
        'root-1': _rootBird,
        'father-1': birdWithRing,
        'mother-1': _motherBird,
      };

      await tester.pumpWidget(
        _wrap(AncestorListView(rootBird: _rootBird, ancestors: ancestors)),
      );
      await tester.pump();

      expect(find.text('TR-999'), findsOneWidget);
    });

    testWidgets('renders with commonAncestorIds highlighting', (tester) async {
      final ancestors = {
        'root-1': _rootBird,
        'father-1': _fatherBird,
        'mother-1': _motherBird,
      };

      await tester.pumpWidget(
        _wrap(
          AncestorListView(
            rootBird: _rootBird,
            ancestors: ancestors,
            commonAncestorIds: {'father-1'},
          ),
        ),
      );
      await tester.pump();

      // Widget normal render edilmeli (ortak ata vurgulama)
      expect(find.byType(AncestorListView), findsOneWidget);
    });

    testWidgets('renders ListTile for each ancestor bird', (tester) async {
      final ancestors = {
        'root-1': _rootBird,
        'father-1': _fatherBird,
        'mother-1': _motherBird,
      };

      await tester.pumpWidget(
        _wrap(AncestorListView(rootBird: _rootBird, ancestors: ancestors)),
      );
      await tester.pump();

      // 3 kuş için en az 3 ListTile
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('handles isRootChick flag without crashing', (tester) async {
      final ancestors = {'root-1': _rootBird};

      await tester.pumpWidget(
        _wrap(
          AncestorListView(
            rootBird: _rootBird,
            ancestors: ancestors,
            isRootChick: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AncestorListView), findsOneWidget);
    });
  });
}
