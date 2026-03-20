import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/models/bird_model.dart';
import 'pedigree_pdf_constants.dart';

/// Renders the 3-generation pedigree chart and statistics section.
class PedigreePdfChartBuilder {
  final pw.Font regularFont;
  final pw.Font boldFont;

  const PedigreePdfChartBuilder({
    required this.regularFont,
    required this.boldFont,
  });

  // ── Pedigree Chart (3 Generations) ──

  pw.Widget buildChart(
    Bird root,
    Bird? father,
    Bird? mother,
    Bird? pgf,
    Bird? pgm,
    Bird? mgf,
    Bird? mgm,
  ) {
    return pw.Container(
      height: 260,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.75),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          // Column headers
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PedigreePdfColors.brandDark,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(3),
                topRight: pw.Radius.circular(3),
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            child: pw.Row(
              children: [
                _chartHeader('genealogy.root'.tr()),
                _chartHeader('genealogy.parents_gen'.tr()),
                _chartHeader('genealogy.grandparents'.tr()),
              ],
            ),
          ),
          // Chart body
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Gen 0: Root
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(
                          color: PdfColors.grey400,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Center(child: _chartNode(root, isRoot: true)),
                  ),
                ),
                // Gen 1: Parents
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                color: PdfColors.grey400,
                                width: 0.5,
                              ),
                              bottom: pw.BorderSide(
                                color: PdfColors.grey600,
                                width: 1,
                              ),
                            ),
                          ),
                          child: pw.Center(child: _chartNode(father)),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                color: PdfColors.grey400,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: pw.Center(child: _chartNode(mother)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Gen 2: Grandparents
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _gpCell(pgf, bottomBorder: PdfColors.grey300),
                      _gpCell(
                        pgm,
                        bottomBorder: PdfColors.grey600,
                        thick: true,
                      ),
                      _gpCell(mgf, bottomBorder: PdfColors.grey300),
                      _gpCell(mgm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Statistics ──

  pw.Widget buildStats(
    int found,
    int possible,
    int deepestGen,
    double completeness,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PedigreePdfColors.statsBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('genealogy.ancestors_found'.tr(), '$found / $possible'),
          _statDivider(),
          _statItem(
            'genealogy.completeness'.tr(),
            '%${completeness.toStringAsFixed(1)}',
          ),
          _statDivider(),
          _statItem(
            'genealogy.deepest_generation'.tr(),
            deepestGen > 0 ? '$deepestGen.' : '-',
          ),
        ],
      ),
    );
  }

  // ── Private Helpers ──

  pw.Widget _chartHeader(String text) => pw.Expanded(
    child: pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    ),
  );

  pw.Widget _gpCell(Bird? bird, {PdfColor? bottomBorder, bool thick = false}) {
    return pw.Expanded(
      child: pw.Container(
        decoration: bottomBorder != null
            ? pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: bottomBorder,
                    width: thick ? 1 : 0.5,
                  ),
                ),
              )
            : null,
        child: pw.Center(child: _chartNode(bird, small: true)),
      ),
    );
  }

  pw.Widget _chartNode(Bird? bird, {bool isRoot = false, bool small = false}) {
    if (bird == null) {
      return pw.Container(
        margin: const pw.EdgeInsets.all(3),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: pw.BoxDecoration(
          color: PedigreePdfColors.unknownBg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              '?',
              style: pw.TextStyle(
                fontSize: small ? 12.0 : 14.0,
                color: PdfColors.grey400,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'genealogy.unknown_parent'.tr(),
              style: pw.TextStyle(
                fontSize: small ? 6.0 : 7.0,
                color: PdfColors.grey500,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );
    }

    final bgColor = PedigreePdfHelpers.genderBgColor(bird.gender);
    final nameFontSize = isRoot ? 10.0 : (small ? 7.5 : 9.0);
    final subFontSize = isRoot ? 8.0 : (small ? 6.5 : 7.0);

    return pw.Container(
      margin: const pw.EdgeInsets.all(3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            bird.name,
            style: pw.TextStyle(
              fontSize: nameFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 1,
          ),
          if (bird.ringNumber != null)
            pw.Text(
              bird.ringNumber!,
              style: pw.TextStyle(
                fontSize: subFontSize,
                color: PdfColors.grey700,
              ),
            ),
          pw.Text(
            '${PedigreePdfHelpers.genderLabel(bird.gender.name)} · ${PedigreePdfHelpers.statusLabel(bird.status.name)}',
            style: pw.TextStyle(
              fontSize: subFontSize,
              color: PdfColors.grey600,
            ),
          ),
          if (isRoot && bird.birthDate != null)
            pw.Text(
              PedigreePdfHelpers.dateFormat.format(bird.birthDate!),
              style: pw.TextStyle(
                fontSize: subFontSize,
                color: PdfColors.grey600,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _statItem(String label, String value) => pw.Column(
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PedigreePdfColors.accentBlue,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        textAlign: pw.TextAlign.center,
      ),
    ],
  );

  pw.Widget _statDivider() =>
      pw.Container(width: 1, height: 30, color: PdfColors.grey300);
}
