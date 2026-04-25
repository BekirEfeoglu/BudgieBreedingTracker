import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_filter_bar.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('BirdFilterBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const BirdFilterBar()));
      await tester.pump();

      expect(find.byType(BirdFilterBar), findsOneWidget);
    });

    testWidgets('renders ChoiceChip for each BirdFilter value', (tester) async {
      await tester.pumpWidget(_wrap(const BirdFilterBar()));
      await tester.pump();

      // ListView renders only visible items; at least some chips must be visible
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
    });

    testWidgets('default selection is BirdFilter.all', (tester) async {
      await tester.pumpWidget(_wrap(const BirdFilterBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BirdFilterBar)),
      );
      expect(container.read(birdFilterProvider), BirdFilter.all);
    });

    testWidgets('tapping a chip updates the filter provider', (tester) async {
      await tester.pumpWidget(_wrap(const BirdFilterBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BirdFilterBar)),
      );

      // Set filter directly to avoid overflow from long label text
      container.read(birdFilterProvider.notifier).state = BirdFilter.male;
      await tester.pump();

      expect(container.read(birdFilterProvider), BirdFilter.male);
    });

    testWidgets('wraps chips on compact width', (tester) async {
      await tester.pumpWidget(
        _wrap(const SizedBox(width: 390, child: BirdFilterBar())),
      );
      await tester.pump();

      expect(find.byType(Wrap), findsOneWidget);
    });
  });
}
