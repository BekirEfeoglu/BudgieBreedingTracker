import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_status_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('BirdStatusBadge', () {
    testWidgets('renders without crashing for alive status', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdStatusBadge(status: BirdStatus.alive)),
      );
      await tester.pump();

      expect(find.byType(BirdStatusBadge), findsOneWidget);
    });

    testWidgets('shows alive label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdStatusBadge(status: BirdStatus.alive)),
      );
      await tester.pump();

      expect(find.text(l10n('birds.status_alive')), findsOneWidget);
    });

    testWidgets('shows dead label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdStatusBadge(status: BirdStatus.dead)),
      );
      await tester.pump();

      expect(find.text(l10n('birds.status_dead')), findsOneWidget);
    });

    testWidgets('shows sold label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdStatusBadge(status: BirdStatus.sold)),
      );
      await tester.pump();

      expect(find.text(l10n('birds.status_sold')), findsOneWidget);
    });

    testWidgets('shows unknown label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdStatusBadge(status: BirdStatus.unknown)),
      );
      await tester.pump();

      expect(find.text(l10n('birds.unknown')), findsOneWidget);
    });

    testWidgets('renders all status values without crashing', (tester) async {
      for (final status in BirdStatus.values) {
        await tester.pumpWidget(_wrap(BirdStatusBadge(status: status)));
        await tester.pump();

        expect(find.byType(BirdStatusBadge), findsOneWidget);
      }
    });
  });
}
