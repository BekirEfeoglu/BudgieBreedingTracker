import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/allele_state_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('AlleleStateBadge', () {
    testWidgets('renders without crashing for visual state', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.visual,
          canToggle: true,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.byType(AlleleStateBadge), findsOneWidget);
    });

    testWidgets('renders without crashing for carrier state', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.carrier,
          canToggle: true,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.byType(AlleleStateBadge), findsOneWidget);
    });

    testWidgets('renders without crashing for split state', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.split,
          canToggle: true,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.byType(AlleleStateBadge), findsOneWidget);
    });

    testWidgets('shows localized label for visual state', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.visual,
          canToggle: false,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.allele_visual_short')), findsOneWidget);
    });

    testWidgets('shows localized label for carrier state', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.carrier,
          canToggle: false,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.allele_carrier_short')), findsOneWidget);
    });

    testWidgets('shows localized label for split state', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.split,
          canToggle: false,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.allele_split_short')), findsOneWidget);
    });

    testWidgets('shows DF label for dosage-based visual', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.visual,
          canToggle: false,
          isDosageBased: true,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.allele_df_short')), findsOneWidget);
    });

    testWidgets('shows SF label for dosage-based carrier', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.carrier,
          canToggle: false,
          isDosageBased: true,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.allele_sf_short')), findsOneWidget);
    });

    testWidgets('calls onToggle when canToggle is true', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.visual,
          canToggle: true,
          onToggle: () => toggled = true,
        )),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      expect(toggled, isTrue);
    });

    testWidgets('does not call onToggle when canToggle is false',
        (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.visual,
          canToggle: false,
          onToggle: () => toggled = true,
        )),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      expect(toggled, isFalse);
    });

    testWidgets('wraps content in Material and InkWell', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.visual,
          canToggle: true,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(Material), findsAtLeastNWidgets(1));
    });

    testWidgets('contains Container with decoration', (tester) async {
      await tester.pumpWidget(
        _wrap(AlleleStateBadge(
          state: AlleleState.carrier,
          canToggle: false,
          onToggle: () {},
        )),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });
}
