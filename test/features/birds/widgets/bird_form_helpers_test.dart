import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_helpers.dart';

void main() {
  group('extractColorNote', () {
    test('returns null when notes is null', () {
      expect(extractColorNote(null), isNull);
    });

    test('returns null when notes does not start with color prefix', () {
      expect(extractColorNote('normal notes text'), isNull);
    });

    test('extracts color note from single-line prefix', () {
      const notes = 'color:Opalin Yeşil';
      expect(extractColorNote(notes), 'Opalin Yeşil');
    });

    test('extracts color note from multi-line string (before newline)', () {
      const notes = 'color:Sarı Opalin\nKus iyi durumda';
      expect(extractColorNote(notes), 'Sarı Opalin');
    });

    test('returns empty string when color note is empty prefix only', () {
      const notes = 'color:';
      expect(extractColorNote(notes), '');
    });

    test('extracts only the first line as color note', () {
      const notes = 'color:Mavi\nLine2\nLine3';
      expect(extractColorNote(notes), 'Mavi');
    });
  });

  group('notesBody', () {
    test('returns null when notes is null', () {
      expect(notesBody(null), isNull);
    });

    test('returns original text when no color prefix', () {
      const text = 'normal notes';
      expect(notesBody(text), text);
    });

    test('returns null when notes is only a color prefix with no body', () {
      const notes = 'color:Opalin';
      expect(notesBody(notes), isNull);
    });

    test('returns null when body after newline is empty', () {
      const notes = 'color:Opalin\n';
      expect(notesBody(notes), isNull);
    });

    test('returns body text after color prefix line', () {
      const notes = 'color:Opalin\nKus notlari buraya';
      expect(notesBody(notes), 'Kus notlari buraya');
    });

    test('returns multiline body correctly', () {
      const notes = 'color:Sarı\nSatır 1\nSatır 2';
      expect(notesBody(notes), 'Satır 1\nSatır 2');
    });
  });

  group('buildNotes', () {
    test('returns null when both color note and notes are empty', () {
      final result = buildNotes(
        colorMutation: null,
        colorNoteText: '',
        notesText: '',
      );
      expect(result, isNull);
    });

    test('returns only notes when colorMutation is not BirdColor.other', () {
      final result = buildNotes(
        colorMutation: BirdColor.blue,
        colorNoteText: 'Mavi Not',
        notesText: 'Kus iyi',
      );
      expect(result, 'Kus iyi');
    });

    test('ignores color note when colorMutation is null', () {
      final result = buildNotes(
        colorMutation: null,
        colorNoteText: 'Not',
        notesText: 'Body',
      );
      expect(result, 'Body');
    });

    test(
      'returns only notes when colorMutation is not other and notes not empty',
      () {
        final result = buildNotes(
          colorMutation: BirdColor.green,
          colorNoteText: '',
          notesText: 'Notlar',
        );
        expect(result, 'Notlar');
      },
    );

    test('returns null for non-other colorMutation with empty notes', () {
      final result = buildNotes(
        colorMutation: BirdColor.green,
        colorNoteText: 'Color note',
        notesText: '',
      );
      expect(result, isNull);
    });

    test(
      'returns color prefix only when BirdColor.other with note and no body',
      () {
        final result = buildNotes(
          colorMutation: BirdColor.other,
          colorNoteText: 'Opalin',
          notesText: '',
        );
        expect(result, '${birdFormColorPrefix}Opalin');
      },
    );

    test(
      'returns combined prefix+body when BirdColor.other with note and body',
      () {
        final result = buildNotes(
          colorMutation: BirdColor.other,
          colorNoteText: 'Opalin',
          notesText: 'Kus aktif',
        );
        expect(result, '${birdFormColorPrefix}Opalin\nKus aktif');
      },
    );

    test('returns only body when BirdColor.other but empty color note', () {
      final result = buildNotes(
        colorMutation: BirdColor.other,
        colorNoteText: '',
        notesText: 'Notlar',
      );
      expect(result, 'Notlar');
    });

    test(
      'returns null when BirdColor.other with empty color note and empty body',
      () {
        final result = buildNotes(
          colorMutation: BirdColor.other,
          colorNoteText: '',
          notesText: '',
        );
        expect(result, isNull);
      },
    );

    test('trims whitespace from color note and notes', () {
      final result = buildNotes(
        colorMutation: BirdColor.other,
        colorNoteText: '  Opalin  ',
        notesText: '  Notlar  ',
      );
      expect(result, '${birdFormColorPrefix}Opalin\nNotlar');
    });
  });

  group('birdFormColorPrefix constant', () {
    test('has expected value', () {
      expect(birdFormColorPrefix, 'color:');
    });
  });

  group('normalizeGenotypeForGender', () {
    test('forces sex-linked carrier states to visual for female', () {
      final genotype = ParentGenotype(
        mutations: const {
          'ino': AlleleState.carrier,
          'blue': AlleleState.carrier,
        },
        gender: BirdGender.male,
      );

      final normalized = normalizeGenotypeForGender(
        genotype: genotype,
        gender: BirdGender.female,
      );

      expect(normalized.gender, BirdGender.female);
      expect(normalized.getState('ino'), AlleleState.visual);
      expect(normalized.getState('blue'), AlleleState.carrier);
    });

    test('keeps one sex-linked mutation per locus for female', () {
      final genotype = ParentGenotype(
        mutations: const {
          'ino': AlleleState.visual,
          'pallid': AlleleState.visual,
          'blue': AlleleState.visual,
        },
        gender: BirdGender.male,
      );

      final normalized = normalizeGenotypeForGender(
        genotype: genotype,
        gender: BirdGender.female,
      );

      final inoLocusSelections = [
        'ino',
        'pallid',
      ].where((id) => normalized.mutations.containsKey(id)).length;
      expect(inoLocusSelections, 1);
      expect(normalized.mutations.containsKey('blue'), isTrue);
    });

    test('does not alter mutation states for non-female genders', () {
      final genotype = ParentGenotype(
        mutations: const {
          'ino': AlleleState.carrier,
          'blue': AlleleState.visual,
        },
        gender: BirdGender.male,
      );

      final normalized = normalizeGenotypeForGender(
        genotype: genotype,
        gender: BirdGender.male,
      );

      expect(normalized.gender, BirdGender.male);
      expect(normalized.getState('ino'), AlleleState.carrier);
      expect(normalized.getState('blue'), AlleleState.visual);
    });
  });

  group('prepareBirdGenotypeData', () {
    test('returns no genotype payload for limited-genetics species', () {
      final result = prepareBirdGenotypeData(
        genotype: ParentGenotype(
          mutations: const {'cinnamon': AlleleState.visual},
          gender: BirdGender.male,
        ),
        gender: BirdGender.male,
        species: Species.canary,
        colorMutation: BirdColor.cinnamon,
      );

      expect(result.mutationIds, isNull);
      expect(result.genotypeInfo, isNull);
    });

    test(
      'maps color mutation to genotype payload for full-genetics species',
      () {
        final result = prepareBirdGenotypeData(
          genotype: const ParentGenotype.empty(gender: BirdGender.male),
          gender: BirdGender.male,
          species: Species.budgie,
          colorMutation: BirdColor.blue,
        );

        expect(result.mutationIds, ['blue']);
        expect(result.genotypeInfo, {'blue': 'visual'});
      },
    );
  });
}
