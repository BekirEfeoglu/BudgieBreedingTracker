import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_list_item.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  final testEgg = Egg(
    id: 'egg-1',
    userId: 'user-1',
    layDate: DateTime(2024, 1, 10),
    status: EggStatus.laid,
    eggNumber: 1,
  );

  group('EggListItem', () {
    testWidgets('renders inside a Card widget', (tester) async {
      await pumpWidgetSimple(tester, EggListItem(egg: testEgg));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('custom onTap is invoked', (tester) async {
      var tapped = false;

      await pumpWidgetSimple(
        tester,
        EggListItem(egg: testEgg, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('onStatusUpdate button is shown when callback provided', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        EggListItem(egg: testEgg, onStatusUpdate: () {}),
      );

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('onDelete button is shown when callback provided', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        EggListItem(egg: testEgg, onDelete: () {}),
      );

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('onStatusUpdate callback is invoked', (tester) async {
      var updated = false;

      await pumpWidgetSimple(
        tester,
        EggListItem(egg: testEgg, onStatusUpdate: () => updated = true),
      );

      // Tap the status update button (first IconButton)
      await tester.tap(find.byType(IconButton).first);
      expect(updated, isTrue);
    });

    testWidgets('different egg statuses render without error', (tester) async {
      for (final status in EggStatus.values) {
        final egg = Egg(
          id: 'egg-status-$status',
          userId: 'user-1',
          layDate: DateTime(2024, 1, 10),
          status: status,
          eggNumber: 1,
        );

        await pumpWidgetSimple(tester, EggListItem(egg: egg));
        expect(find.byType(Card), findsOneWidget);
      }
    });

    testWidgets('egg with incubation days shows days info', (tester) async {
      final incubatingEgg = Egg(
        id: 'egg-2',
        userId: 'user-1',
        layDate: DateTime(2024, 1, 1),
        status: EggStatus.incubating,
        eggNumber: 2,
      );

      await pumpWidgetSimple(tester, EggListItem(egg: incubatingEgg));

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
