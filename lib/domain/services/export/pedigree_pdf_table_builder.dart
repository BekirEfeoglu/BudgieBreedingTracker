import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/models/bird_model.dart';
import 'pedigree_pdf_constants.dart';

/// Renders the bird info card and deep generation tables for pedigree PDF.
class PedigreePdfTableBuilder {
  final pw.Font regularFont;
  final pw.Font boldFont;

  const PedigreePdfTableBuilder({
    required this.regularFont,
    required this.boldFont,
  });

  // ── Bird Info Card ──

  pw.Widget buildBirdInfoCard(Bird bird) {
    final pairs = <List<String>>[
      ['export.header_name'.tr(), bird.name],
      ['export.header_ring_number'.tr(), bird.ringNumber ?? '-'],
      ['export.header_gender'.tr(), PedigreePdfHelpers.genderLabel(bird.gender.name)],
      ['export.header_status'.tr(), PedigreePdfHelpers.statusLabel(bird.status.name)],
      if (bird.birthDate != null)
        ['export.header_birth_date'.tr(), PedigreePdfHelpers.dateFormat.format(bird.birthDate!)],
      if (bird.colorMutation != null)
        ['export.header_color'.tr(), bird.colorMutation!.name],
      if (bird.cageNumber != null)
        ['export.header_cage'.tr(), bird.cageNumber!],
    ];

    final rows = <pw.TableRow>[];
    for (int i = 0; i < pairs.length; i += 2) {
      final left = pairs[i];
      final right = (i + 1 < pairs.length) ? pairs[i + 1] : null;
      rows.add(pw.TableRow(children: [
        _labelCell(left[0]),
        _valueCell(left[1]),
        if (right != null) _labelCell(right[0]) else pw.SizedBox(),
        if (right != null) _valueCell(right[1]) else pw.SizedBox(),
      ]));
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PedigreePdfColors.cardBg,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('export.pedigree_bird_info'.tr(),
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PedigreePdfColors.brandDark)),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1.5),
            },
            children: rows,
          ),
        ],
      ),
    );
  }

  // ── Deep Generation Tables (gen 3+) ──

  List<pw.Widget> buildDeepTables(
      Map<int, List<Bird>> generations, int maxDepth) {
    final widgets = <pw.Widget>[];
    for (int gen = 3; gen <= maxDepth; gen++) {
      final birds = generations[gen];
      if (birds == null || birds.isEmpty) continue;

      if (widgets.isEmpty) {
        widgets.add(pw.SizedBox(height: 20));
        widgets.add(PedigreePdfHelpers.sectionTitle(
            'export.pedigree_gen_details'.tr()));
      }
      widgets.add(pw.SizedBox(height: 10));
      widgets.add(pw.Text(
        '${PedigreePdfHelpers.pedigreeGenLabel(gen)} (${birds.length})',
        style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PedigreePdfColors.brandDark),
      ));
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: PdfColors.white),
        headerDecoration:
            pw.BoxDecoration(color: PedigreePdfColors.brandDark),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellPadding: const pw.EdgeInsets.all(4),
        oddRowDecoration:
            const pw.BoxDecoration(color: PdfColors.grey100),
        headers: [
          'export.header_name'.tr(),
          'export.header_ring_number'.tr(),
          'export.header_gender'.tr(),
          'export.header_status'.tr(),
        ],
        data: birds
            .map((b) => [
                  b.name,
                  b.ringNumber ?? '-',
                  PedigreePdfHelpers.genderLabel(b.gender.name),
                  PedigreePdfHelpers.statusLabel(b.status.name),
                ])
            .toList(),
      ));
    }
    return widgets;
  }

  // ── Private Helpers ──

  pw.Widget _labelCell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700)));

  pw.Widget _valueCell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)));
}
