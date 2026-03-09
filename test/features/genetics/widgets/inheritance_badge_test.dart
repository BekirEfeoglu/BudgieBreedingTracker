import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inheritance_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('InheritanceBadge', () {
    testWidgets('renders without crashing for autosomalRecessive', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const InheritanceBadge(type: InheritanceType.autosomalRecessive)),
      );
      await tester.pump();

      expect(find.byType(InheritanceBadge), findsOneWidget);
    });

    testWidgets('shows AR badge text for autosomalRecessive', (tester) async {
      await tester.pumpWidget(
        _wrap(const InheritanceBadge(type: InheritanceType.autosomalRecessive)),
      );
      await tester.pump();

      expect(find.text('AR'), findsOneWidget);
    });

    testWidgets('shows AD badge text for autosomalDominant', (tester) async {
      await tester.pumpWidget(
        _wrap(const InheritanceBadge(type: InheritanceType.autosomalDominant)),
      );
      await tester.pump();

      expect(find.text('AD'), findsOneWidget);
    });

    testWidgets('shows AID badge text for autosomalIncompleteDominant', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const InheritanceBadge(
            type: InheritanceType.autosomalIncompleteDominant,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AID'), findsOneWidget);
    });

    testWidgets('shows SLR badge text for sexLinkedRecessive', (tester) async {
      await tester.pumpWidget(
        _wrap(const InheritanceBadge(type: InheritanceType.sexLinkedRecessive)),
      );
      await tester.pump();

      expect(find.text('SLR'), findsOneWidget);
    });

    testWidgets('shows SLC badge text for sexLinkedCodominant', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InheritanceBadge(type: InheritanceType.sexLinkedCodominant),
        ),
      );
      await tester.pump();

      expect(find.text('SLC'), findsOneWidget);
    });

    testWidgets('renders Container wrapper', (tester) async {
      await tester.pumpWidget(
        _wrap(const InheritanceBadge(type: InheritanceType.autosomalRecessive)),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('each badge shows different text', (tester) async {
      final badges = {
        InheritanceType.autosomalRecessive: 'AR',
        InheritanceType.autosomalDominant: 'AD',
        InheritanceType.autosomalIncompleteDominant: 'AID',
        InheritanceType.sexLinkedRecessive: 'SLR',
        InheritanceType.sexLinkedCodominant: 'SLC',
      };

      for (final entry in badges.entries) {
        await tester.pumpWidget(_wrap(InheritanceBadge(type: entry.key)));
        await tester.pump();
        expect(find.text(entry.value), findsOneWidget);
      }
    });
  });
}
