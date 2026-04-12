import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pedigree_pdf_table_builder.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late PedigreePdfTableBuilder builder;

  setUp(() {
    builder = PedigreePdfTableBuilder(
      regularFont: pw.Font.helvetica(),
      boldFont: pw.Font.helveticaBold(),
    );
  });

  group('PedigreePdfTableBuilder', () {
    group('constructor', () {
      test('accepts regular and bold font parameters', () {
        final regular = pw.Font.courier();
        final bold = pw.Font.courierBold();

        final instance = PedigreePdfTableBuilder(
          regularFont: regular,
          boldFont: bold,
        );

        expect(instance.regularFont, same(regular));
        expect(instance.boldFont, same(bold));
      });
    });

    group('buildBirdInfoCard', () {
      test('returns a widget with all fields populated', () {
        final bird = Bird(
          id: 'bird-full',
          name: 'Mavis',
          gender: BirdGender.male,
          userId: 'user-1',
          status: BirdStatus.alive,
          ringNumber: 'TR-2024-001',
          birthDate: DateTime(2024, 3, 15),
          colorMutation: BirdColor.blue,
          cageNumber: 'A-12',
        );

        final widget = builder.buildBirdInfoCard(bird);

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('returns a widget when optional fields are null', () {
        final bird = createTestBird(
          id: 'bird-minimal',
          name: 'Minimal Bird',
          gender: BirdGender.female,
          status: BirdStatus.alive,
        );
        // ringNumber, birthDate, colorMutation, cageNumber are all null

        final widget = builder.buildBirdInfoCard(bird);

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('renders correctly inside a PDF document with full bird', () async {
        final bird = Bird(
          id: 'bird-pdf',
          name: 'PDF Test Bird',
          gender: BirdGender.male,
          userId: 'user-1',
          status: BirdStatus.sold,
          ringNumber: 'DE-2025-999',
          birthDate: DateTime(2023, 12, 1),
          colorMutation: BirdColor.lutino,
          cageNumber: 'B-05',
        );

        final doc = pw.Document();
        doc.addPage(
          pw.Page(build: (_) => builder.buildBirdInfoCard(bird)),
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });

      test('renders correctly inside a PDF document with minimal bird',
          () async {
        final bird = createTestBird(
          id: 'bird-min-pdf',
          name: 'Min Bird',
          gender: BirdGender.unknown,
          status: BirdStatus.dead,
        );

        final doc = pw.Document();
        doc.addPage(
          pw.Page(build: (_) => builder.buildBirdInfoCard(bird)),
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });
    });

    group('buildDeepTables', () {
      test('returns empty list when generations map is empty', () {
        final result = builder.buildDeepTables({}, 5);

        expect(result, isA<List<pw.Widget>>());
        expect(result, isEmpty);
      });

      test('returns empty list when only gen 0-2 data exists', () {
        final generations = <int, List<Bird>>{
          0: [createTestBird(id: 'root', name: 'Root')],
          1: [
            createTestBird(id: 'father', name: 'Father'),
            createTestBird(
              id: 'mother',
              name: 'Mother',
              gender: BirdGender.female,
            ),
          ],
          2: [
            createTestBird(id: 'pgf', name: 'PGF'),
            createTestBird(
              id: 'pgm',
              name: 'PGM',
              gender: BirdGender.female,
            ),
          ],
        };

        final result = builder.buildDeepTables(generations, 2);

        expect(result, isEmpty);
      });

      test('returns widgets when gen 3+ birds exist', () {
        final generations = <int, List<Bird>>{
          3: [
            createTestBird(
              id: 'ggf1',
              name: 'Great Grandfather 1',
              gender: BirdGender.male,
              ringNumber: 'TR-100',
            ),
            createTestBird(
              id: 'ggm1',
              name: 'Great Grandmother 1',
              gender: BirdGender.female,
              ringNumber: 'TR-101',
            ),
          ],
        };

        final result = builder.buildDeepTables(generations, 3);

        expect(result, isNotEmpty);
        expect(result, isA<List<pw.Widget>>());
        for (final widget in result) {
          expect(widget, isA<pw.Widget>());
        }
      });

      test('returns widgets for multiple deep generations', () {
        final generations = <int, List<Bird>>{
          3: [
            createTestBird(id: 'gen3-1', name: 'Gen3 Bird 1'),
            createTestBird(
              id: 'gen3-2',
              name: 'Gen3 Bird 2',
              gender: BirdGender.female,
            ),
          ],
          4: [
            createTestBird(id: 'gen4-1', name: 'Gen4 Bird 1'),
          ],
          5: [
            createTestBird(id: 'gen5-1', name: 'Gen5 Bird 1'),
            createTestBird(id: 'gen5-2', name: 'Gen5 Bird 2'),
            createTestBird(
              id: 'gen5-3',
              name: 'Gen5 Bird 3',
              gender: BirdGender.female,
            ),
          ],
        };

        final result = builder.buildDeepTables(generations, 5);

        expect(result, isNotEmpty);
        // At minimum: section header + spacing + gen label + spacing + table
        // per generation, plus the initial section header
        expect(result.length, greaterThanOrEqualTo(5));
      });

      test('skips generations with empty bird lists', () {
        final generations = <int, List<Bird>>{
          3: [], // empty - should be skipped
          4: [createTestBird(id: 'gen4-1', name: 'Gen4 Bird')],
          5: [], // empty - should be skipped
        };

        final result = builder.buildDeepTables(generations, 5);

        expect(result, isNotEmpty);
        for (final widget in result) {
          expect(widget, isA<pw.Widget>());
        }
      });

      test('renders deep tables correctly inside a PDF document', () async {
        final generations = <int, List<Bird>>{
          3: [
            createTestBird(
              id: 'ggf',
              name: 'Great GF',
              gender: BirdGender.male,
              ringNumber: 'TR-300',
            ),
            createTestBird(
              id: 'ggm',
              name: 'Great GM',
              gender: BirdGender.female,
            ),
          ],
          4: [
            createTestBird(id: 'gggf', name: 'Great Great GF'),
          ],
        };

        final widgets = builder.buildDeepTables(generations, 4);
        expect(widgets, isNotEmpty);

        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            build: (_) => pw.Column(children: widgets),
          ),
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });
    });
  });
}
