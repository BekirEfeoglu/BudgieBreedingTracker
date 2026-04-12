import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/enums/bird_enums.dart';

/// Shared color constants and utility helpers used by all pedigree PDF builders.
abstract final class PedigreePdfColors {
  static final brandDark = PdfColor.fromHex('#0D1B2A');
  static final accentBlue = PdfColor.fromHex('#1565C0');
  static final maleBg = PdfColor.fromHex('#E3F2FD');
  static final femaleBg = PdfColor.fromHex('#FCE4EC');
  static final unknownBg = PdfColor.fromHex('#F5F5F5');
  static final cardBg = PdfColor.fromHex('#FAFAFA');
  static final statsBg = PdfColor.fromHex('#F0F4F8');
}

/// Shared helper functions for pedigree PDF generation.
abstract final class PedigreePdfHelpers {
  static final dateFormat = DateFormat('dd.MM.yyyy');

  static PdfColor genderBgColor(BirdGender g) => switch (g) {
    BirdGender.male => PedigreePdfColors.maleBg,
    BirdGender.female => PedigreePdfColors.femaleBg,
    _ => PedigreePdfColors.unknownBg,
  };

  static String genderLabel(String name) => switch (name) {
    'male' => 'export.gender_male'.tr(),
    'female' => 'export.gender_female'.tr(),
    _ => 'export.gender_unknown'.tr(),
  };

  static String statusLabel(String name) => switch (name) {
    'alive' => 'export.status_alive'.tr(),
    'dead' => 'export.status_dead'.tr(),
    'sold' => 'export.status_sold'.tr(),
    _ => name,
  };

  static String pedigreeGenLabel(int gen) => switch (gen) {
    0 => 'genealogy.root'.tr(),
    1 => 'genealogy.parents_gen'.tr(),
    2 => 'genealogy.grandparents'.tr(),
    3 => 'genealogy.great_grandparents'.tr(),
    _ => 'genealogy.generation'.tr(args: [gen.toString()]),
  };

  static pw.Widget sectionTitle(String title) => pw.Container(
    padding: const pw.EdgeInsets.only(left: 8, top: 3, bottom: 3),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(color: PedigreePdfColors.accentBlue, width: 3),
      ),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PedigreePdfColors.brandDark,
      ),
    ),
  );
}
