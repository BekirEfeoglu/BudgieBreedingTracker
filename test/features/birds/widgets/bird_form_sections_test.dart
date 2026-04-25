import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_profile.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_sections.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

Future<void> _pumpSimple(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: Form(child: child)),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpWithProvider(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: Form(child: child)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BirdFormBasicInfoSection', () {
    testWidgets('shows name field', (tester) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);

      await _pumpSimple(
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

    testWidgets('shows gender segmented button', (tester) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);

      await _pumpSimple(
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
    });

    testWidgets('shows species dropdown', (tester) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);

      await _pumpSimple(
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

    testWidgets('species dropdown keeps current non-budgie value visible', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);

      await _pumpSimple(
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
      final speciesValues = speciesDropdown.items!
          .map((item) => item.value)
          .whereType<Species>()
          .toList();

      expect(speciesDropdown.value, Species.canary);
      expect(
        speciesValues,
        equals([
          Species.budgie,
          Species.canary,
          Species.cockatiel,
          Species.finch,
          Species.other,
        ]),
      );
    });

    testWidgets('species dropdown starts empty for unknown species', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);

      await _pumpSimple(
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

    testWidgets(
      'color dropdown excludes unknown option and normalizes unknown value',
      (tester) async {
        final nameCtrl = TextEditingController();
        addTearDown(nameCtrl.dispose);
        final colorCtrl = TextEditingController();
        addTearDown(colorCtrl.dispose);

        await _pumpSimple(
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

        final colorValues = dropdown.items!
            .map((item) => item.value)
            .whereType<BirdColor>()
            .toList();

        expect(dropdown.value, isNull);
        expect(colorValues, isNot(contains(BirdColor.unknown)));
        expect(
          colorValues.where((color) => color == BirdColor.other),
          hasLength(1),
        );
      },
    );

    testWidgets(
      'shows color note field when colorMutation is BirdColor.other',
      (tester) async {
        final nameCtrl = TextEditingController();
        addTearDown(nameCtrl.dispose);
        final colorCtrl = TextEditingController();
        addTearDown(colorCtrl.dispose);

        await _pumpSimple(
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
      },
    );

    testWidgets('does not show color note field for non-other color', (
      tester,
    ) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);

      await _pumpSimple(
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

    testWidgets('validates empty name', (tester) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);
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

    testWidgets('gender change callback is invoked', (tester) async {
      final nameCtrl = TextEditingController();
      addTearDown(nameCtrl.dispose);
      final colorCtrl = TextEditingController();
      addTearDown(colorCtrl.dispose);
      BirdGender? changedGender;

      await _pumpSimple(
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
  });

  group('BirdFormIdentitySection', () {
    testWidgets('shows ring number field', (tester) async {
      final ringCtrl = TextEditingController();
      addTearDown(ringCtrl.dispose);
      final cageCtrl = TextEditingController();
      addTearDown(cageCtrl.dispose);

      await _pumpSimple(
        tester,
        BirdFormIdentitySection(
          ringController: ringCtrl,
          cageController: cageCtrl,
          birthDate: null,
          onBirthDateChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.ring_number')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows cage number field', (tester) async {
      final ringCtrl = TextEditingController();
      addTearDown(ringCtrl.dispose);
      final cageCtrl = TextEditingController();
      addTearDown(cageCtrl.dispose);

      await _pumpSimple(
        tester,
        BirdFormIdentitySection(
          ringController: ringCtrl,
          cageController: cageCtrl,
          birthDate: null,
          onBirthDateChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.cage_number')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows birth date picker field', (tester) async {
      final ringCtrl = TextEditingController();
      addTearDown(ringCtrl.dispose);
      final cageCtrl = TextEditingController();
      addTearDown(cageCtrl.dispose);

      await _pumpSimple(
        tester,
        BirdFormIdentitySection(
          ringController: ringCtrl,
          cageController: cageCtrl,
          birthDate: null,
          onBirthDateChanged: (_) {},
        ),
      );

      expect(find.text(l10n('birds.birth_date')), findsAtLeastNWidgets(1));
    });
  });

  group('BirdFormGeneticsSection', () {
    testWidgets('shows genetics title', (tester) async {
      await _pumpSimple(
        tester,
        BirdFormGeneticsSection(
          species: Species.budgie,
          geneticsMode: GeneticsMode.full,
          gender: BirdGender.male,
          genotype: const ParentGenotype.empty(gender: BirdGender.male),
          onGenotypeChanged: (_) {},
        ),
      );

      expect(find.text(l10n('genetics.title')), findsOneWidget);
    });
  });

  group('BirdFormNotesSection', () {
    testWidgets('shows notes text field', (tester) async {
      final notesCtrl = TextEditingController();
      addTearDown(notesCtrl.dispose);

      await _pumpSimple(
        tester,
        BirdFormNotesSection(notesController: notesCtrl),
      );

      expect(find.text(l10n('common.notes_optional')), findsAtLeastNWidgets(1));
    });

    testWidgets('field has max lines of 4', (tester) async {
      final notesCtrl = TextEditingController();
      addTearDown(notesCtrl.dispose);

      await _pumpSimple(
        tester,
        BirdFormNotesSection(notesController: notesCtrl),
      );

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.maxLines, 4);
    });
  });

  group('BirdFormParentsSection', () {
    testWidgets('shows section header', (tester) async {
      await _pumpWithProvider(
        tester,
        BirdFormParentsSection(
          species: Species.budgie,
          fatherId: null,
          motherId: null,
          onFatherChanged: (_) {},
          onMotherChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith((ref, userId) => Stream.value([])),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.parents')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows father selector label', (tester) async {
      await _pumpWithProvider(
        tester,
        BirdFormParentsSection(
          species: Species.budgie,
          fatherId: null,
          motherId: null,
          onFatherChanged: (_) {},
          onMotherChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith((ref, userId) => Stream.value([])),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.select_father')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows mother selector label', (tester) async {
      await _pumpWithProvider(
        tester,
        BirdFormParentsSection(
          species: Species.budgie,
          fatherId: null,
          motherId: null,
          onFatherChanged: (_) {},
          onMotherChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith((ref, userId) => Stream.value([])),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.select_mother')), findsAtLeastNWidgets(1));
    });
  });
}
