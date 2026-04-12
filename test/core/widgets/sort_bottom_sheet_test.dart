import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/sort_bottom_sheet.dart';

import '../../helpers/test_localization.dart';

enum _TestSort {
  newest,
  oldest,
  nameAsc;

  String get label => switch (this) {
    _TestSort.newest => 'Newest',
    _TestSort.oldest => 'Oldest',
    _TestSort.nameAsc => 'Name A-Z',
  };
}

void main() {
  group('SortBottomSheet', () {
    Widget buildSubject({
      _TestSort current = _TestSort.newest,
      ValueChanged<_TestSort>? onSelected,
    }) {
      return SortBottomSheet<_TestSort>(
        values: _TestSort.values,
        current: current,
        labelOf: (s) => s.label,
        onSelected: onSelected ?? (_) {},
      );
    }

    testWidgets('renders all sort options', (tester) async {
      await pumpLocalizedWidget(tester, buildSubject());

      expect(find.text('Newest'), findsOneWidget);
      expect(find.text('Oldest'), findsOneWidget);
      expect(find.text('Name A-Z'), findsOneWidget);
    });

    testWidgets('shows check icon for current selection', (tester) async {
      await pumpLocalizedWidget(
        tester,
        buildSubject(current: _TestSort.oldest),
      );

      // There should be exactly one check icon (for the selected item)
      expect(find.byIcon(LucideIcons.check), findsOneWidget);

      // The remaining items should have SizedBox placeholders
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 24 && w.child == null,
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('calls onSelected when option tapped', (tester) async {
      _TestSort? selected;

      await pumpLocalizedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => buildSubject(
                  current: _TestSort.newest,
                  onSelected: (s) => selected = s,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap 'Oldest' option
      await tester.tap(find.text('Oldest'));
      await tester.pumpAndSettle();

      expect(selected, _TestSort.oldest);
    });

    testWidgets('closes bottom sheet after selection', (tester) async {
      await pumpLocalizedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => buildSubject(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Newest'), findsOneWidget);

      // Tap an option
      await tester.tap(find.text('Name A-Z'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed — sort options no longer visible
      expect(find.text('Name A-Z'), findsNothing);
    });

    testWidgets('renders sort title from l10n key', (tester) async {
      await pumpLocalizedWidget(tester, buildSubject());

      // With TestAssetLoader, .tr() returns raw key 'common.sort'
      expect(find.text('common.sort'), findsOneWidget);
    });

    testWidgets('scrolls instead of overflowing on small screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final values = List<int>.generate(20, (index) => index);

      await pumpLocalizedWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showSortBottomSheet<int>(
                context: context,
                values: values,
                current: 0,
                labelOf: (value) => 'Option $value',
                onSelected: (_) {},
              );
            },
            child: const Text('Open'),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Option 19'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Option 19'),
        300,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Option 19'), findsOneWidget);
    });
  });
}
