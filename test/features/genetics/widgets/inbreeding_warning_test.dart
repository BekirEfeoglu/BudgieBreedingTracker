import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inbreeding_warning.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('InbreedingWarning', () {
    testWidgets('renders without crashing for minimal risk', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(
            coefficient: 0.05,
            risk: InbreedingRisk.minimal,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InbreedingWarning), findsOneWidget);
    });

    testWidgets('returns nothing (no progress bar) when risk is none', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(coefficient: 0.0, risk: InbreedingRisk.none),
        ),
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows Container for non-none risk', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(coefficient: 0.1, risk: InbreedingRisk.low),
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('shows LinearProgressIndicator for non-none risk', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(
            coefficient: 0.15,
            risk: InbreedingRisk.moderate,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows coefficient percentage text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(coefficient: 0.25, risk: InbreedingRisk.high),
        ),
      );
      await tester.pump();

      // 0.25 * 100 = 25.0 → "F = 25.0%"
      expect(find.textContaining('25.0%'), findsOneWidget);
    });

    testWidgets('renders without crashing for critical risk', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(
            coefficient: 0.5,
            risk: InbreedingRisk.critical,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InbreedingWarning), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Row layout for non-none risk', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(coefficient: 0.1, risk: InbreedingRisk.low),
        ),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Column layout for non-none risk', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InbreedingWarning(
            coefficient: 0.2,
            risk: InbreedingRisk.moderate,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('renders all risk levels without crashing', (tester) async {
      for (final risk in InbreedingRisk.values) {
        await tester.pumpWidget(
          _wrap(InbreedingWarning(coefficient: 0.1, risk: risk)),
        );
        await tester.pump();

        expect(find.byType(InbreedingWarning), findsOneWidget);
      }
    });
  });
}
