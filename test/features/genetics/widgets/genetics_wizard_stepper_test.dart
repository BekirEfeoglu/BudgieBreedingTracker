import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_wizard_stepper.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('GeneticsWizardStepper', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GeneticsWizardStepper), findsOneWidget);
    });

    testWidgets('shows 3 step labels', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('genetics.step_parents'), findsOneWidget);
      expect(find.text('genetics.step_genotype'), findsOneWidget);
      expect(find.text('genetics.step_results'), findsOneWidget);
    });

    testWidgets('shows step number 1 for first step when active',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows step numbers for all 3 steps at step 0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows check icon for completed step 0 when at step 1',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 1,
            hasSelections: true,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      // Step 0 is completed (check icon), step 1 shows "2", step 2 shows "3"
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows check icons for steps 0 and 1 when at step 2',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 2,
            hasSelections: true,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      // Steps 0 and 1 are completed (check icons), step 2 shows "3"
      expect(find.byIcon(LucideIcons.check), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('has 2 connecting lines between steps', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      // Two Expanded Containers (connecting lines between 3 steps)
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('onStepTap is called with correct step index',
        (tester) async {
      int? tappedStep;

      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 1,
            hasSelections: true,
            onStepTap: (step) => tappedStep = step,
          ),
        ),
      );
      await tester.pump();

      // Tap on the first step dot (step 0, which is completed)
      await tester.tap(find.text('genetics.step_parents'));
      await tester.pump();

      expect(tappedStep, equals(0));
    });

    testWidgets('step 1 is tappable when hasSelections is true',
        (tester) async {
      int? tappedStep;

      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: true,
            onStepTap: (step) => tappedStep = step,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('genetics.step_genotype'));
      await tester.pump();

      expect(tappedStep, equals(1));
    });

    testWidgets('step 1 is not tappable when hasSelections is false',
        (tester) async {
      int? tappedStep;

      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (step) => tappedStep = step,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('genetics.step_genotype'));
      await tester.pump();

      // onStepTap should not be called because step 1 has null onTap
      expect(tappedStep, isNull);
    });

    testWidgets('step 2 is not tappable when hasSelections is false',
        (tester) async {
      int? tappedStep;

      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (step) => tappedStep = step,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('genetics.step_results'));
      await tester.pump();

      expect(tappedStep, isNull);
    });

    testWidgets('step 2 is tappable when hasSelections is true',
        (tester) async {
      int? tappedStep;

      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: true,
            onStepTap: (step) => tappedStep = step,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('genetics.step_results'));
      await tester.pump();

      expect(tappedStep, equals(2));
    });

    testWidgets('renders GestureDetector for each step', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsNWidgets(3));
    });

    testWidgets('step 0 is always tappable', (tester) async {
      int? tappedStep;

      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 2,
            hasSelections: true,
            onStepTap: (step) => tappedStep = step,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('genetics.step_parents'));
      await tester.pump();

      expect(tappedStep, equals(0));
    });

    testWidgets('renders Row as root layout', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GeneticsWizardStepper(
            currentStep: 0,
            hasSelections: false,
            onStepTap: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });
}
