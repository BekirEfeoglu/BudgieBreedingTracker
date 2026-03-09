import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pedigree_pdf_builder.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('PedigreePdfBuilder', () {
    late PedigreePdfBuilder builder;

    setUp(() {
      builder = PedigreePdfBuilder(
        regularFont: pw.Font.helvetica(),
        boldFont: pw.Font.helveticaBold(),
      );
    });

    test('build creates a valid PDF page for a populated pedigree', () async {
      final root = createTestBird(
        id: 'root',
        name: 'Root',
        gender: BirdGender.male,
        ringNumber: 'TR-100',
        birthDate: DateTime(2024, 5, 1),
        fatherId: 'father',
        motherId: 'mother',
      );
      final father = createTestBird(
        id: 'father',
        name: 'Father',
        gender: BirdGender.male,
        fatherId: 'pgf',
        motherId: 'pgm',
      );
      final mother = createTestBird(
        id: 'mother',
        name: 'Mother',
        gender: BirdGender.female,
        fatherId: 'mgf',
        motherId: 'mgm',
      );

      final ancestors = <String, Bird>{
        'father': father,
        'mother': mother,
        'pgf': createTestBird(id: 'pgf', name: 'PGF', gender: BirdGender.male),
        'pgm': createTestBird(
          id: 'pgm',
          name: 'PGM',
          gender: BirdGender.female,
        ),
        'mgf': createTestBird(id: 'mgf', name: 'MGF', gender: BirdGender.male),
        'mgm': createTestBird(
          id: 'mgm',
          name: 'MGM',
          gender: BirdGender.female,
        ),
      };

      final doc = pw.Document();
      doc.addPage(builder.build(root, ancestors, 4));

      final bytes = await doc.save();
      _expectPdf(bytes);
      expect(bytes.length, greaterThan(900));
    });

    test('build works when ancestor map is empty', () async {
      final root = createTestBird(
        id: 'root',
        name: 'Solo',
        gender: BirdGender.unknown,
      );

      final doc = pw.Document();
      doc.addPage(builder.build(root, const {}, 3));

      final bytes = await doc.save();
      _expectPdf(bytes);
      expect(bytes.length, greaterThan(500));
    });
  });
}

void _expectPdf(Uint8List bytes) {
  expect(bytes, isNotEmpty);
  expect(String.fromCharCodes(bytes.take(4)), '%PDF');
}
