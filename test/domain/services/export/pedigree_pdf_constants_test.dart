import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pedigree_pdf_constants.dart';

void main() {
  group('PedigreePdfColors', () {
    test('brandDark is a valid dark navy color', () {
      final color = PedigreePdfColors.brandDark;
      expect(color, isA<PdfColor>());
      expect(color.red, closeTo(0.051, 0.01));
      expect(color.green, closeTo(0.106, 0.01));
      expect(color.blue, closeTo(0.165, 0.01));
    });

    test('accentBlue is a valid blue color', () {
      final color = PedigreePdfColors.accentBlue;
      expect(color, isA<PdfColor>());
      expect(color.blue, greaterThan(color.red));
      expect(color.blue, greaterThan(color.green));
    });

    test('maleBg is a light blue background', () {
      final color = PedigreePdfColors.maleBg;
      expect(color, isA<PdfColor>());
      // Light color: RGB channels should all be high
      expect(color.red, greaterThan(0.8));
      expect(color.green, greaterThan(0.9));
      expect(color.blue, greaterThan(0.9));
    });

    test('femaleBg is a light pink background', () {
      final color = PedigreePdfColors.femaleBg;
      expect(color, isA<PdfColor>());
      expect(color.red, greaterThan(0.9));
      expect(color.green, greaterThan(0.8));
      expect(color.blue, greaterThan(0.8));
    });

    test('unknownBg is a light grey', () {
      final color = PedigreePdfColors.unknownBg;
      expect(color, isA<PdfColor>());
      // Grey: R, G, B channels are approximately equal
      expect(color.red, closeTo(color.green, 0.02));
      expect(color.green, closeTo(color.blue, 0.02));
      expect(color.red, greaterThan(0.9));
    });

    test('cardBg is a near-white background', () {
      final color = PedigreePdfColors.cardBg;
      expect(color, isA<PdfColor>());
      expect(color.red, greaterThan(0.95));
      expect(color.green, greaterThan(0.95));
      expect(color.blue, greaterThan(0.95));
    });

    test('statsBg is a light blue-grey background', () {
      final color = PedigreePdfColors.statsBg;
      expect(color, isA<PdfColor>());
      expect(color.red, greaterThan(0.9));
      expect(color.green, greaterThan(0.9));
      expect(color.blue, greaterThan(0.9));
    });

    test('all colors have full opacity', () {
      final colors = [
        PedigreePdfColors.brandDark,
        PedigreePdfColors.accentBlue,
        PedigreePdfColors.maleBg,
        PedigreePdfColors.femaleBg,
        PedigreePdfColors.unknownBg,
        PedigreePdfColors.cardBg,
        PedigreePdfColors.statsBg,
      ];
      for (final color in colors) {
        expect(color.alpha, equals(1.0));
      }
    });

    test('gender backgrounds are distinct from each other', () {
      expect(PedigreePdfColors.maleBg, isNot(equals(PedigreePdfColors.femaleBg)));
      expect(PedigreePdfColors.maleBg, isNot(equals(PedigreePdfColors.unknownBg)));
      expect(PedigreePdfColors.femaleBg, isNot(equals(PedigreePdfColors.unknownBg)));
    });
  });

  group('PedigreePdfHelpers', () {
    group('dateFormat', () {
      test('formats a date in dd.MM.yyyy pattern', () {
        final date = DateTime(2024, 5, 1);
        expect(PedigreePdfHelpers.dateFormat.format(date), equals('01.05.2024'));
      });

      test('formats single-digit day and month with leading zeros', () {
        final date = DateTime(2023, 1, 3);
        expect(PedigreePdfHelpers.dateFormat.format(date), equals('03.01.2023'));
      });

      test('formats December 31 correctly', () {
        final date = DateTime(2025, 12, 31);
        expect(PedigreePdfHelpers.dateFormat.format(date), equals('31.12.2025'));
      });

      test('formats leap year date correctly', () {
        final date = DateTime(2024, 2, 29);
        expect(PedigreePdfHelpers.dateFormat.format(date), equals('29.02.2024'));
      });
    });

    group('genderBgColor', () {
      test('returns maleBg for BirdGender.male', () {
        final color = PedigreePdfHelpers.genderBgColor(BirdGender.male);
        expect(color, equals(PedigreePdfColors.maleBg));
      });

      test('returns femaleBg for BirdGender.female', () {
        final color = PedigreePdfHelpers.genderBgColor(BirdGender.female);
        expect(color, equals(PedigreePdfColors.femaleBg));
      });

      test('returns unknownBg for BirdGender.unknown', () {
        final color = PedigreePdfHelpers.genderBgColor(BirdGender.unknown);
        expect(color, equals(PedigreePdfColors.unknownBg));
      });

      test('returns a PdfColor for all BirdGender values', () {
        for (final gender in BirdGender.values) {
          expect(PedigreePdfHelpers.genderBgColor(gender), isA<PdfColor>());
        }
      });
    });
  });
}
