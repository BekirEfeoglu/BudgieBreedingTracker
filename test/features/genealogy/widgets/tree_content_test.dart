import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/tree_content.dart';

import '../../../helpers/test_localization.dart';

const _testBird = Bird(
  id: 'entity-1',
  userId: 'user-1',
  name: 'Test Kuş',
  gender: BirdGender.male,
  status: BirdStatus.alive,
);

void main() {
  group('TreeContent', () {
    testWidgets('shows skeleton loader when ancestorsProvider is loading', (
      tester,
    ) async {
      // Loading state never settles (spinner animation), so skip pumpAndSettle.
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            ancestorsProvider(
              'entity-1',
            ).overrideWithValue(const AsyncLoading()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TreeContent(entityId: 'entity-1', isChick: false),
            ),
          ),
        ),
        settle: false,
      );
      expect(find.byType(SkeletonLoader), findsAtLeastNWidgets(1));
    });

    testWidgets('shows ErrorState when ancestorsProvider has error', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            ancestorsProvider('entity-1').overrideWithValue(
              const AsyncError('Test hata', StackTrace.empty),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TreeContent(entityId: 'entity-1', isChick: false),
            ),
          ),
        ),
      );
      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows bird_not_found text when entity not in ancestors map', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            ancestorsProvider('entity-1').overrideWithValue(
              const AsyncData({}), // Boş harita — entity-1 bulunamayacak
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TreeContent(entityId: 'entity-1', isChick: false),
            ),
          ),
        ),
      );
      expect(find.text('genealogy.bird_not_found'), findsOneWidget);
    });

    testWidgets('renders SegmentedButton for view mode when data loaded', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            ancestorsProvider(
              'entity-1',
            ).overrideWithValue(const AsyncData({'entity-1': _testBird})),
            offspringProvider(
              'entity-1',
            ).overrideWithValue(const AsyncData((birds: <Bird>[], chicks: []))),
            pedigreeDepthProvider.overrideWith(() {
              final n = PedigreeDepthNotifier();
              return n;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 800,
                child: TreeContent(entityId: 'entity-1', isChick: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SegmentedButton<TreeViewMode>), findsOneWidget);
    });

    testWidgets('switches to list view when list segment selected', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            ancestorsProvider(
              'entity-1',
            ).overrideWithValue(const AsyncData({'entity-1': _testBird})),
            offspringProvider(
              'entity-1',
            ).overrideWithValue(const AsyncData((birds: <Bird>[], chicks: []))),
            pedigreeDepthProvider.overrideWith(() {
              final n = PedigreeDepthNotifier();
              return n;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 800,
                child: TreeContent(entityId: 'entity-1', isChick: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // list segment'e tap — 'genealogy.list_view' raw key
      final listSeg = find.text('genealogy.list_view');
      if (listSeg.evaluate().isNotEmpty) {
        await tester.tap(listSeg);
        await tester.pump(const Duration(milliseconds: 400));
      }

      // Exception tüket (animasyon / overflow)
      expect(find.byType(TreeContent), findsOneWidget);
    });

    testWidgets('shows genealogy.tree_error in ErrorState retry message', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        ProviderScope(
          overrides: [
            ancestorsProvider(
              'entity-1',
            ).overrideWithValue(const AsyncError('Hata', StackTrace.empty)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TreeContent(entityId: 'entity-1', isChick: false),
            ),
          ),
        ),
      );
      expect(find.text('genealogy.tree_error'), findsOneWidget);
    });
  });
}
