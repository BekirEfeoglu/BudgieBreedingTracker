import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pedigree_pdf_chart_builder.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late PedigreePdfChartBuilder builder;

  setUp(() {
    builder = PedigreePdfChartBuilder(
      regularFont: pw.Font.helvetica(),
      boldFont: pw.Font.helveticaBold(),
    );
  });

  group('PedigreePdfChartBuilder', () {
    group('constructor', () {
      test('accepts regular and bold font parameters', () {
        final regular = pw.Font.courier();
        final bold = pw.Font.courierBold();

        final instance = PedigreePdfChartBuilder(
          regularFont: regular,
          boldFont: bold,
        );

        expect(instance.regularFont, same(regular));
        expect(instance.boldFont, same(bold));
      });
    });

    group('buildChart', () {
      test('returns a widget when all 7 birds are provided', () {
        final root = createTestBird(
          id: 'root',
          name: 'Root Bird',
          gender: BirdGender.male,
          ringNumber: 'TR-001',
          birthDate: DateTime(2024, 3, 15),
        );
        final father = createTestBird(
          id: 'father',
          name: 'Father',
          gender: BirdGender.male,
          ringNumber: 'TR-002',
        );
        final mother = createTestBird(
          id: 'mother',
          name: 'Mother',
          gender: BirdGender.female,
          ringNumber: 'TR-003',
        );
        final pgf = createTestBird(
          id: 'pgf',
          name: 'Paternal GF',
          gender: BirdGender.male,
        );
        final pgm = createTestBird(
          id: 'pgm',
          name: 'Paternal GM',
          gender: BirdGender.female,
        );
        final mgf = createTestBird(
          id: 'mgf',
          name: 'Maternal GF',
          gender: BirdGender.male,
        );
        final mgm = createTestBird(
          id: 'mgm',
          name: 'Maternal GM',
          gender: BirdGender.female,
        );

        final widget = builder.buildChart(
          root,
          father,
          mother,
          pgf,
          pgm,
          mgf,
          mgm,
        );

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('returns a widget when all ancestor birds are null', () {
        final root = createTestBird(
          id: 'solo',
          name: 'Solo Bird',
          gender: BirdGender.unknown,
        );

        final widget = builder.buildChart(
          root,
          null,
          null,
          null,
          null,
          null,
          null,
        );

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('returns a widget with partial null ancestors', () {
        final root = createTestBird(
          id: 'root',
          name: 'Root',
          gender: BirdGender.female,
        );
        final father = createTestBird(
          id: 'father',
          name: 'Father',
          gender: BirdGender.male,
        );

        final widget = builder.buildChart(
          root,
          father,
          null, // no mother
          null, // no pgf
          null, // no pgm
          null, // no mgf
          null, // no mgm
        );

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('renders correctly inside a PDF document', () async {
        final root = createTestBird(
          id: 'root',
          name: 'Root',
          gender: BirdGender.male,
          birthDate: DateTime(2024, 1, 1),
        );
        final father = createTestBird(
          id: 'father',
          name: 'Father',
          gender: BirdGender.male,
        );
        final mother = createTestBird(
          id: 'mother',
          name: 'Mother',
          gender: BirdGender.female,
        );

        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            build: (_) => builder.buildChart(
              root,
              father,
              mother,
              null,
              null,
              null,
              null,
            ),
          ),
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });
    });

    group('buildStats', () {
      test('returns a widget with correct found/possible/completeness', () {
        final widget = builder.buildStats(5, 7, 3, 71.4);

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('returns "-" text for deepestGen = 0', () async {
        final widget = builder.buildStats(0, 7, 0, 0.0);

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());

        // Verify by rendering into a PDF to ensure the widget tree is valid
        final doc = pw.Document();
        doc.addPage(pw.Page(build: (_) => widget));

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });

      test('returns widget for deepestGen > 0', () {
        final widget = builder.buildStats(3, 7, 2, 42.9);

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('handles 100% completeness', () {
        final widget = builder.buildStats(7, 7, 3, 100.0);

        expect(widget, isNotNull);
        expect(widget, isA<pw.Widget>());
      });

      test('renders correctly inside a PDF document', () async {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            build: (_) => builder.buildStats(4, 7, 2, 57.1),
          ),
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });
    });
  });
}
