import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_form_fields.dart';

void main() {
  late TextEditingController nameCtrl;
  late TextEditingController ringCtrl;
  late TextEditingController hatchWeightCtrl;
  late TextEditingController notesCtrl;

  setUp(() {
    nameCtrl = TextEditingController();
    ringCtrl = TextEditingController();
    hatchWeightCtrl = TextEditingController();
    notesCtrl = TextEditingController();
  });

  tearDown(() {
    nameCtrl.dispose();
    ringCtrl.dispose();
    hatchWeightCtrl.dispose();
    notesCtrl.dispose();
  });

  Future<void> pumpFields(
    WidgetTester tester, {
    BirdGender gender = BirdGender.unknown,
    ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
    DateTime? hatchDate,
    ValueChanged<BirdGender>? onGenderChanged,
    ValueChanged<ChickHealthStatus>? onHealthStatusChanged,
    ValueChanged<DateTime?>? onHatchDateChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              child: ChickFormFields(
                nameController: nameCtrl,
                ringController: ringCtrl,
                hatchWeightController: hatchWeightCtrl,
                notesController: notesCtrl,
                gender: gender,
                healthStatus: healthStatus,
                hatchDate: hatchDate,
                dateFormatter: null,
                onGenderChanged: onGenderChanged ?? (_) {},
                onHealthStatusChanged: onHealthStatusChanged ?? (_) {},
                onHatchDateChanged: onHatchDateChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ChickFormFields', () {
    testWidgets('renders name field', (tester) async {
      await pumpFields(tester);
      expect(find.text(l10n('chicks.name_optional')), findsOneWidget);
    });

    testWidgets('renders gender selector', (tester) async {
      await pumpFields(tester);
      expect(find.byType(SegmentedButton<BirdGender>), findsOneWidget);
      expect(find.text(l10n('chicks.gender')), findsOneWidget);
    });

    testWidgets('renders health status selector', (tester) async {
      await pumpFields(tester);
      expect(
        find.byType(SegmentedButton<ChickHealthStatus>),
        findsOneWidget,
      );
      expect(find.text(l10n('chicks.health_status')), findsOneWidget);
    });

    testWidgets('renders hatch date picker', (tester) async {
      await pumpFields(tester);
      expect(find.byType(DatePickerField), findsOneWidget);
      expect(find.text(l10n('chicks.hatch_date_required')), findsOneWidget);
    });

    testWidgets('renders hatch weight field', (tester) async {
      await pumpFields(tester);
      expect(find.text(l10n('chicks.birth_weight_label')), findsOneWidget);
    });

    testWidgets('renders ring number field', (tester) async {
      await pumpFields(tester);
      expect(find.text(l10n('chicks.ring_number')), findsOneWidget);
    });

    testWidgets('renders notes field', (tester) async {
      await pumpFields(tester);
      expect(find.text(l10n('common.notes')), findsOneWidget);
    });

    testWidgets('gender callback is invoked on selection', (tester) async {
      BirdGender? changed;
      await pumpFields(
        tester,
        gender: BirdGender.unknown,
        onGenderChanged: (g) => changed = g,
      );

      await tester.tap(find.text(l10n('chicks.male')));
      await tester.pump();

      expect(changed, BirdGender.male);
    });

    testWidgets('health status callback is invoked on selection', (
      tester,
    ) async {
      ChickHealthStatus? changed;
      await pumpFields(
        tester,
        healthStatus: ChickHealthStatus.healthy,
        onHealthStatusChanged: (s) => changed = s,
      );

      await tester.tap(find.text(l10n('chicks.sick')));
      await tester.pump();

      expect(changed, ChickHealthStatus.sick);
    });

    testWidgets('hatch weight validates invalid number', (tester) async {
      final formKey = GlobalKey<FormState>();
      hatchWeightCtrl.text = 'abc';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: ChickFormFields(
                  nameController: nameCtrl,
                  ringController: ringCtrl,
                  hatchWeightController: hatchWeightCtrl,
                  notesController: notesCtrl,
                  gender: BirdGender.unknown,
                  healthStatus: ChickHealthStatus.healthy,
                  hatchDate: null,
                  dateFormatter: null,
                  onGenderChanged: (_) {},
                  onHealthStatusChanged: (_) {},
                  onHatchDateChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text(l10n('chicks.invalid_number')), findsOneWidget);
    });

    testWidgets('hatch weight validates negative number', (tester) async {
      final formKey = GlobalKey<FormState>();
      hatchWeightCtrl.text = '-5';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: ChickFormFields(
                  nameController: nameCtrl,
                  ringController: ringCtrl,
                  hatchWeightController: hatchWeightCtrl,
                  notesController: notesCtrl,
                  gender: BirdGender.unknown,
                  healthStatus: ChickHealthStatus.healthy,
                  hatchDate: null,
                  dateFormatter: null,
                  onGenderChanged: (_) {},
                  onHealthStatusChanged: (_) {},
                  onHatchDateChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text(l10n('chicks.invalid_number')), findsOneWidget);
    });

    testWidgets('hatch weight accepts valid number', (tester) async {
      final formKey = GlobalKey<FormState>();
      hatchWeightCtrl.text = '2.5';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: ChickFormFields(
                  nameController: nameCtrl,
                  ringController: ringCtrl,
                  hatchWeightController: hatchWeightCtrl,
                  notesController: notesCtrl,
                  gender: BirdGender.unknown,
                  healthStatus: ChickHealthStatus.healthy,
                  hatchDate: DateTime(2025, 1, 10),
                  dateFormatter: null,
                  onGenderChanged: (_) {},
                  onHealthStatusChanged: (_) {},
                  onHatchDateChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final result = formKey.currentState?.validate();
      await tester.pump();

      expect(result, isTrue);
    });

    testWidgets('empty hatch weight passes validation', (tester) async {
      final formKey = GlobalKey<FormState>();
      hatchWeightCtrl.text = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: ChickFormFields(
                  nameController: nameCtrl,
                  ringController: ringCtrl,
                  hatchWeightController: hatchWeightCtrl,
                  notesController: notesCtrl,
                  gender: BirdGender.unknown,
                  healthStatus: ChickHealthStatus.healthy,
                  hatchDate: DateTime(2025, 1, 10),
                  dateFormatter: null,
                  onGenderChanged: (_) {},
                  onHealthStatusChanged: (_) {},
                  onHatchDateChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final result = formKey.currentState?.validate();
      await tester.pump();

      expect(result, isTrue);
    });
  });
}
