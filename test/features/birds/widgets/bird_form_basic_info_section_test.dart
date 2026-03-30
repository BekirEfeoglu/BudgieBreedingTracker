import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_basic_info_section.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: Form(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BirdFormBasicInfoSection', () {
    testWidgets('renders without crashing', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.byType(BirdFormBasicInfoSection), findsOneWidget);
    });

    testWidgets('shows section header', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.section_basic')), findsOneWidget);
    });

    testWidgets('shows name field with label', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.name_label')), findsOneWidget);
    });

    testWidgets('shows gender segmented button with three options', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.byType(SegmentedButton<BirdGender>), findsOneWidget);
      expect(find.text(l10n('birds.male')), findsOneWidget);
      expect(find.text(l10n('birds.female')), findsOneWidget);
      expect(find.text(l10n('birds.unknown')), findsOneWidget);
    });

    testWidgets('shows gender label text', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.gender')), findsOneWidget);
    });

    testWidgets('shows species dropdown', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.species')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows color dropdown', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.color')), findsAtLeastNWidgets(1));
    });

    testWidgets('validates empty name field', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: BirdFormBasicInfoSection(
                  nameController: nameCtrl,
                  gender: BirdGender.male,
                  species: Species.budgie,
                  colorMutation: null,
                  colorNoteController: colorCtrl,
                  onGenderChanged: (_) {},
                  onSpeciesChanged: (_) {},
                  onColorChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text(l10n('birds.name_required')), findsOneWidget);
    });

    testWidgets('validates missing species selection', (tester) async {
      final nameCtrl = TextEditingController(text: 'Mavi');
      final colorCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: BirdFormBasicInfoSection(
                  nameController: nameCtrl,
                  gender: BirdGender.male,
                  species: Species.unknown,
                  colorMutation: null,
                  colorNoteController: colorCtrl,
                  onGenderChanged: (_) {},
                  onSpeciesChanged: (_) {},
                  onColorChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text(l10n('birds.species_required')), findsOneWidget);
    });

    testWidgets('does not show error when name is provided', (tester) async {
      final nameCtrl = TextEditingController(text: 'Mavi');
      final colorCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: BirdFormBasicInfoSection(
                  nameController: nameCtrl,
                  gender: BirdGender.male,
                  species: Species.budgie,
                  colorMutation: null,
                  colorNoteController: colorCtrl,
                  onGenderChanged: (_) {},
                  onSpeciesChanged: (_) {},
                  onColorChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      formKey.currentState?.validate();
      await tester.pump();

      expect(find.text(l10n('birds.name_required')), findsNothing);
    });

    testWidgets('calls onGenderChanged when gender is tapped', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();
      BirdGender? changedGender;

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (g) => changedGender = g,
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      await tester.tap(find.text(l10n('birds.female')));
      await tester.pump();

      expect(changedGender, BirdGender.female);
    });

    testWidgets('shows color note field when colorMutation is other', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: BirdColor.other,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.color_name')), findsOneWidget);
    });

    testWidgets('hides color note field when colorMutation is not other', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: BirdColor.blue,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.color_name')), findsNothing);
    });

    testWidgets('normalizes unknown color to null in dropdown', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: BirdColor.unknown,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      final dropdownFinder = find.byWidgetPredicate(
        (widget) => widget is DropdownButton<BirdColor?>,
      );
      expect(dropdownFinder, findsOneWidget);

      final dropdown = tester.widget<DropdownButton<BirdColor?>>(
        dropdownFinder,
      );
      expect(dropdown.value, isNull);
    });

    testWidgets('color dropdown excludes unknown value', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      final dropdownFinder = find.byWidgetPredicate(
        (widget) => widget is DropdownButton<BirdColor?>,
      );
      final dropdown = tester.widget<DropdownButton<BirdColor?>>(
        dropdownFinder,
      );
      final colorValues = dropdown.items!
          .map((item) => item.value)
          .whereType<BirdColor>()
          .toList();

      expect(colorValues, isNot(contains(BirdColor.unknown)));
    });

    testWidgets('species dropdown keeps non-budgie species visible', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.canary,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      final speciesDropdownFinder = find.byWidgetPredicate(
        (widget) => widget is DropdownButton<Species>,
      );
      expect(speciesDropdownFinder, findsOneWidget);

      final speciesDropdown = tester.widget<DropdownButton<Species>>(
        speciesDropdownFinder,
      );
      expect(speciesDropdown.value, Species.canary);
    });

    testWidgets('species dropdown starts empty for unknown species', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.unknown,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      final speciesDropdownFinder = find.byWidgetPredicate(
        (widget) => widget is DropdownButton<Species>,
      );
      expect(speciesDropdownFinder, findsOneWidget);

      final speciesDropdown = tester.widget<DropdownButton<Species>>(
        speciesDropdownFinder,
      );
      expect(speciesDropdown.value, isNull);
    });

    testWidgets('shows AppIcon for bird name prefix icon', (tester) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.byType(AppIcon), findsAtLeastNWidgets(1));
    });

    testWidgets('no color selected option is present in dropdown', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      final colorCtrl = TextEditingController();

      await _pump(
        tester,
        BirdFormBasicInfoSection(
          nameController: nameCtrl,
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: null,
          colorNoteController: colorCtrl,
          onGenderChanged: (_) {},
          onSpeciesChanged: (_) {},
          onColorChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.no_color_selected')), findsOneWidget);
    });
  });
}
