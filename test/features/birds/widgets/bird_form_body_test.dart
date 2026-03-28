import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_body.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_sections.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

import '../../../helpers/test_settings_notifiers.dart';

void main() {
  late TextEditingController nameCtrl;
  late TextEditingController ringCtrl;
  late TextEditingController cageCtrl;
  late TextEditingController notesCtrl;
  late TextEditingController colorNoteCtrl;
  late GlobalKey<FormState> formKey;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    nameCtrl = TextEditingController();
    ringCtrl = TextEditingController();
    cageCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    colorNoteCtrl = TextEditingController();
    formKey = GlobalKey<FormState>();
  });

  tearDown(() {
    nameCtrl.dispose();
    ringCtrl.dispose();
    cageCtrl.dispose();
    notesCtrl.dispose();
    colorNoteCtrl.dispose();
  });

  Widget buildSubject({
    bool isEdit = false,
    bool isLoading = false,
    BirdGender gender = BirdGender.male,
  }) {
    return BirdFormBody(
      formKey: formKey,
      nameController: nameCtrl,
      ringController: ringCtrl,
      cageController: cageCtrl,
      notesController: notesCtrl,
      colorNoteController: colorNoteCtrl,
      gender: gender,
      species: Species.budgie,
      colorMutation: null,
      birthDate: null,
      fatherId: null,
      motherId: null,
      editBirdId: null,
      genotype: const ParentGenotype.empty(gender: BirdGender.male),
      isEdit: isEdit,
      isLoading: isLoading,
      onGenderChanged: (_) {},
      onSpeciesChanged: (_) {},
      onColorChanged: (_) {},
      onGenotypeChanged: (_) {},
      onBirthDateChanged: (_) {},
      onFatherChanged: (_) {},
      onMotherChanged: (_) {},
      onSubmit: () {},
    );
  }

  Future<void> pumpBody(
    WidgetTester tester, {
    bool isEdit = false,
    bool isLoading = false,
    BirdGender gender = BirdGender.male,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([]),
          ),
          dateFormatProvider.overrideWith(TestDateFormatNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: buildSubject(
              isEdit: isEdit,
              isLoading: isLoading,
              gender: gender,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BirdFormBody', () {
    testWidgets('renders all form sections', (tester) async {
      await pumpBody(tester);

      expect(find.byType(BirdFormBasicInfoSection), findsOneWidget);
      expect(find.byType(BirdFormGeneticsSection), findsOneWidget);
      expect(find.byType(BirdFormIdentitySection), findsOneWidget);
      expect(find.byType(BirdFormParentsSection), findsOneWidget);
      expect(find.byType(BirdFormNotesSection), findsOneWidget);
    });

    testWidgets('renders save button when not in edit mode', (tester) async {
      await pumpBody(tester, isEdit: false);

      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('common.save'), findsOneWidget);
    });

    testWidgets('renders update button when in edit mode', (tester) async {
      await pumpBody(tester, isEdit: true);

      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('common.update'), findsOneWidget);
    });

    testWidgets('renders Form widget with autovalidate mode', (
      tester,
    ) async {
      await pumpBody(tester);

      final form = tester.widget<Form>(find.byType(Form));
      expect(
        form.autovalidateMode,
        AutovalidateMode.onUserInteraction,
      );
    });

    testWidgets('submit button invokes onSubmit callback', (tester) async {
      var submitCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            birdsStreamProvider.overrideWith(
              (ref, userId) => Stream.value([]),
            ),
            dateFormatProvider.overrideWith(TestDateFormatNotifier.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BirdFormBody(
                formKey: formKey,
                nameController: nameCtrl,
                ringController: ringCtrl,
                cageController: cageCtrl,
                notesController: notesCtrl,
                colorNoteController: colorNoteCtrl,
                gender: BirdGender.male,
                species: Species.budgie,
                colorMutation: null,
                birthDate: null,
                fatherId: null,
                motherId: null,
                editBirdId: null,
                genotype: const ParentGenotype.empty(
                  gender: BirdGender.male,
                ),
                isEdit: false,
                isLoading: false,
                onGenderChanged: (_) {},
                onSpeciesChanged: (_) {},
                onColorChanged: (_) {},
                onGenotypeChanged: (_) {},
                onBirthDateChanged: (_) {},
                onFatherChanged: (_) {},
                onMotherChanged: (_) {},
                onSubmit: () => submitCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Use tap with warnIfMissed: false since the button may be
      // partially off-screen in the scrollable area.
      await tester.ensureVisible(find.byType(PrimaryButton));
      await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
      await tester.pump();

      expect(submitCalled, isTrue);
    });

    testWidgets('wraps content in SingleChildScrollView', (tester) async {
      await pumpBody(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
