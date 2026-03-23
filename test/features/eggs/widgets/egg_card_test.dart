import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_list_item.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_status_chip.dart';

/// Pumps widget inside ProviderScope + MaterialApp for EggListItem tests.
Future<void> _pumpEggListItem(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(
    ProviderScope(child: MaterialApp(home: Scaffold(body: widget))),
  );
}

Egg _createEgg({
  String id = 'egg-1',
  String userId = 'user-1',
  int? eggNumber = 1,
  EggStatus status = EggStatus.laid,
  DateTime? layDate,
  DateTime? hatchDate,
  String? notes,
}) {
  return Egg(
    id: id,
    userId: userId,
    eggNumber: eggNumber,
    status: status,
    layDate: layDate ?? DateTime(2024, 1, 10),
    hatchDate: hatchDate,
    notes: notes,
    createdAt: DateTime(2024, 1, 10),
    updatedAt: DateTime(2024, 1, 10),
  );
}

void main() {
  group('EggListItem - Rendering', () {
    testWidgets('renders inside a Card widget', (tester) async {
      await _pumpEggListItem(tester, EggListItem(egg: _createEgg()));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows egg number in title', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(eggNumber: 3)),
      );

      expect(find.textContaining('#3'), findsOneWidget);
    });

    testWidgets('shows egg label text', (tester) async {
      await _pumpEggListItem(tester, EggListItem(egg: _createEgg()));

      // .tr() returns the key in test, so look for the key pattern
      expect(find.textContaining('eggs.egg_label'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows EggStatusChip for current status', (tester) async {
      await _pumpEggListItem(tester, EggListItem(egg: _createEgg()));

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('shows lay date information', (tester) async {
      final egg = _createEgg(layDate: DateTime(2024, 3, 15));
      await _pumpEggListItem(tester, EggListItem(egg: egg));

      expect(find.textContaining('15.03.2024'), findsOneWidget);
    });

    testWidgets('shows incubation days count', (tester) async {
      await _pumpEggListItem(tester, EggListItem(egg: _createEgg()));

      expect(find.textContaining('eggs.days_count'), findsOneWidget);
    });

    testWidgets('renders question mark when eggNumber is null', (
      tester,
    ) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(eggNumber: null)),
      );

      expect(find.textContaining('?'), findsAtLeastNWidgets(1));
    });

    testWidgets('contains InkWell for tap interaction', (tester) async {
      await _pumpEggListItem(tester, EggListItem(egg: _createEgg()));

      expect(find.byType(InkWell), findsOneWidget);
    });
  });

  group('EggListItem - Status Badge Colors', () {
    testWidgets('laid status renders without error', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(status: EggStatus.laid)),
      );

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('fertile status renders without error', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(status: EggStatus.fertile)),
      );

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('incubating status renders without error', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(status: EggStatus.incubating)),
      );

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('hatched status renders without error', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(
          egg: _createEgg(
            status: EggStatus.hatched,
            hatchDate: DateTime(2024, 1, 28),
          ),
        ),
      );

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('infertile status renders without error', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(status: EggStatus.infertile)),
      );

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('damaged status renders without error', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(status: EggStatus.damaged)),
      );

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('discarded status renders without error', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(status: EggStatus.discarded)),
      );

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('all EggStatus values render without crashing', (
      tester,
    ) async {
      for (final status in EggStatus.values) {
        final egg = _createEgg(id: 'egg-$status', status: status);
        await _pumpEggListItem(tester, EggListItem(egg: egg));
        expect(find.byType(Card), findsOneWidget);
      }
    });
  });

  group('EggListItem - Callbacks', () {
    testWidgets('onTap callback is invoked when tapped', (tester) async {
      var tapped = false;

      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(), onTap: () => tapped = true),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('onStatusUpdate button is visible when callback provided', (
      tester,
    ) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(), onStatusUpdate: () {}),
      );

      // Should show an IconButton with LucideIcons.arrowLeftRight
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('onStatusUpdate callback is invoked on tap', (tester) async {
      var statusUpdateCalled = false;

      await _pumpEggListItem(
        tester,
        EggListItem(
          egg: _createEgg(),
          onStatusUpdate: () => statusUpdateCalled = true,
        ),
      );

      // Tap the first IconButton (status update)
      await tester.tap(find.byType(IconButton).first);
      expect(statusUpdateCalled, isTrue);
    });

    testWidgets('onDelete button is visible when callback provided', (
      tester,
    ) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(), onDelete: () {}),
      );

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('onDelete callback is invoked on tap', (tester) async {
      var deleteCalled = false;

      await _pumpEggListItem(
        tester,
        EggListItem(
          egg: _createEgg(),
          onDelete: () => deleteCalled = true,
        ),
      );

      await tester.tap(find.byType(IconButton).first);
      expect(deleteCalled, isTrue);
    });

    testWidgets('no IconButtons when no callbacks provided', (tester) async {
      await _pumpEggListItem(tester, EggListItem(egg: _createEgg()));

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('both buttons visible when both callbacks provided', (
      tester,
    ) async {
      await _pumpEggListItem(
        tester,
        EggListItem(
          egg: _createEgg(),
          onStatusUpdate: () {},
          onDelete: () {},
        ),
      );

      expect(find.byType(IconButton), findsNWidgets(2));
    });
  });

  group('EggListItem - Accessibility', () {
    testWidgets('has Semantics label with egg number', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(eggNumber: 5)),
      );

      expect(find.bySemanticsLabel(RegExp('.*5.*')), findsAtLeastNWidgets(1));
    });

    testWidgets('status update button has tooltip', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(), onStatusUpdate: () {}),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton).first,
      );
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, isNotEmpty);
    });

    testWidgets('delete button has tooltip', (tester) async {
      await _pumpEggListItem(
        tester,
        EggListItem(egg: _createEgg(), onDelete: () {}),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton).first,
      );
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, isNotEmpty);
    });
  });
}
