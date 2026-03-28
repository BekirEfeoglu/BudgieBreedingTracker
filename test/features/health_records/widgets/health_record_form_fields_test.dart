import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_form_fields.dart';

void main() {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController treatmentCtrl;
  late TextEditingController vetCtrl;
  late TextEditingController notesCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController costCtrl;

  setUp(() {
    titleCtrl = TextEditingController();
    descCtrl = TextEditingController();
    treatmentCtrl = TextEditingController();
    vetCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    weightCtrl = TextEditingController();
    costCtrl = TextEditingController();
  });

  tearDown(() {
    titleCtrl.dispose();
    descCtrl.dispose();
    treatmentCtrl.dispose();
    vetCtrl.dispose();
    notesCtrl.dispose();
    weightCtrl.dispose();
    costCtrl.dispose();
  });

  Widget buildSubject({
    HealthRecordType type = HealthRecordType.checkup,
    DateTime? date,
    DateTime? followUpDate,
    String? birdId,
    ValueChanged<HealthRecordType>? onTypeChanged,
  }) {
    return HealthRecordFormFields(
      titleController: titleCtrl,
      descriptionController: descCtrl,
      treatmentController: treatmentCtrl,
      vetController: vetCtrl,
      notesController: notesCtrl,
      weightController: weightCtrl,
      costController: costCtrl,
      type: type,
      date: date ?? DateTime(2025, 1, 15),
      followUpDate: followUpDate,
      birdId: birdId,
      birds: const [],
      chicks: const [],
      isAnimalsLoading: false,
      dateFormatter: null,
      onTypeChanged: onTypeChanged ?? (_) {},
      onDateChanged: (_) {},
      onFollowUpDateChanged: (_) {},
      onBirdChanged: (_) {},
    );
  }

  Future<void> pumpFields(
    WidgetTester tester, {
    HealthRecordType type = HealthRecordType.checkup,
    GlobalKey<FormState>? formKey,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: buildSubject(type: type),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('HealthRecordFormFields', () {
    testWidgets('renders title field', (tester) async {
      await pumpFields(tester);
      expect(find.text('health_records.record_title'), findsOneWidget);
    });

    testWidgets('renders type selector with choice chips', (tester) async {
      await pumpFields(tester);
      expect(find.text('common.type'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
    });

    testWidgets('renders date picker fields', (tester) async {
      await pumpFields(tester);
      // Date field + follow-up date field
      expect(find.byType(DatePickerField), findsNWidgets(2));
    });

    testWidgets('renders description field', (tester) async {
      await pumpFields(tester);
      expect(find.text('common.description'), findsOneWidget);
    });

    testWidgets('renders treatment field', (tester) async {
      await pumpFields(tester);
      expect(find.text('health_records.treatment'), findsOneWidget);
    });

    testWidgets('renders veterinarian field', (tester) async {
      await pumpFields(tester);
      expect(find.text('health_records.veterinarian'), findsOneWidget);
    });

    testWidgets('renders weight field', (tester) async {
      await pumpFields(tester);
      expect(find.text('health_records.weight'), findsOneWidget);
    });

    testWidgets('renders cost field', (tester) async {
      await pumpFields(tester);
      expect(find.text('health_records.cost'), findsOneWidget);
    });

    testWidgets('renders notes field', (tester) async {
      await pumpFields(tester);
      expect(find.text('common.notes_optional'), findsOneWidget);
    });

    testWidgets('renders follow-up date field', (tester) async {
      await pumpFields(tester);
      expect(find.text('health_records.follow_up'), findsOneWidget);
    });

    testWidgets('title validation rejects empty value', (tester) async {
      final formKey = GlobalKey<FormState>();
      titleCtrl.text = '';

      await pumpFields(tester, formKey: formKey);

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text('health_records.title_required'), findsOneWidget);
    });

    testWidgets('title validation accepts non-empty value', (tester) async {
      final formKey = GlobalKey<FormState>();
      titleCtrl.text = 'Check-up visit';

      await pumpFields(tester, formKey: formKey);

      final result = formKey.currentState?.validate();
      await tester.pump();

      expect(result, isTrue);
    });

    testWidgets('weight validation rejects non-numeric value', (tester) async {
      final formKey = GlobalKey<FormState>();
      titleCtrl.text = 'Test';
      weightCtrl.text = 'abc';

      await pumpFields(tester, formKey: formKey);

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text('chicks.invalid_number'), findsOneWidget);
    });

    testWidgets('weight validation rejects zero or negative value', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      titleCtrl.text = 'Test';
      weightCtrl.text = '0';

      await pumpFields(tester, formKey: formKey);

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text('validation.weight_positive'), findsOneWidget);
    });

    testWidgets('cost validation rejects non-numeric value', (tester) async {
      final formKey = GlobalKey<FormState>();
      titleCtrl.text = 'Test';
      costCtrl.text = 'xyz';

      await pumpFields(tester, formKey: formKey);

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text('chicks.invalid_number'), findsOneWidget);
    });

    testWidgets('type selector excludes unknown type', (tester) async {
      await pumpFields(tester);

      // HealthRecordType.unknown should not appear as a chip
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      // There are 6 non-unknown types
      expect(chips.length, HealthRecordType.values.length - 1);
    });

    testWidgets('type selector invokes callback on tap', (tester) async {
      HealthRecordType? changed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                child: buildSubject(
                  type: HealthRecordType.checkup,
                  onTypeChanged: (t) => changed = t,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap a different type chip (illness)
      // Find illness chip - second in the list
      await tester.tap(find.byType(ChoiceChip).at(1));
      await tester.pump();

      expect(changed, HealthRecordType.illness);
    });
  });
}
