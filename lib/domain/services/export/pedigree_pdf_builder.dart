import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../../data/models/bird_model.dart';
import 'pedigree_pdf_chart_builder.dart';
import 'pedigree_pdf_constants.dart';
import 'pedigree_pdf_table_builder.dart';

/// Builds a professional pedigree report with bird info card,
/// visual chart (3 generations), statistics, and generation tables.
///
/// Delegates chart rendering to [PedigreePdfChartBuilder] and
/// table rendering to [PedigreePdfTableBuilder].
class PedigreePdfBuilder {
  final pw.Font regularFont;
  final pw.Font boldFont;

  late final PedigreePdfChartBuilder _chartBuilder;
  late final PedigreePdfTableBuilder _tableBuilder;

  PedigreePdfBuilder({required this.regularFont, required this.boldFont}) {
    _chartBuilder = PedigreePdfChartBuilder(
        regularFont: regularFont, boldFont: boldFont);
    _tableBuilder = PedigreePdfTableBuilder(
        regularFont: regularFont, boldFont: boldFont);
  }

  pw.Page build(Bird rootBird, Map<String, Bird> ancestors, int maxDepth) {
    final father = _resolve(rootBird.fatherId, ancestors);
    final mother = _resolve(rootBird.motherId, ancestors);
    final pgf = _resolve(father?.fatherId, ancestors);
    final pgm = _resolve(father?.motherId, ancestors);
    final mgf = _resolve(mother?.fatherId, ancestors);
    final mgm = _resolve(mother?.motherId, ancestors);

    // Collect generations for stats + deep tables
    final generations = <int, List<Bird>>{};
    _collectByGeneration(rootBird, 0, ancestors, generations, maxDepth);
    final ancestorCount = generations.entries
        .where((e) => e.key > 0)
        .fold(0, (sum, e) => sum + e.value.length);
    int possible = 0;
    for (int i = 1; i <= maxDepth; i++) {
      possible += 1 << i;
    }
    final deepestGen =
        generations.keys.where((k) => k > 0).fold(0, (a, b) => a > b ? a : b);
    final completeness =
        possible > 0 ? (ancestorCount / possible * 100) : 0.0;

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _buildHeader(rootBird),
      footer: (ctx) => _buildFooter(ctx),
      build: (ctx) => [
        _tableBuilder.buildBirdInfoCard(rootBird),
        pw.SizedBox(height: 20),
        PedigreePdfHelpers.sectionTitle('export.pedigree_chart_section'.tr()),
        pw.SizedBox(height: 8),
        _chartBuilder.buildChart(rootBird, father, mother, pgf, pgm, mgf, mgm),
        pw.SizedBox(height: 20),
        PedigreePdfHelpers.sectionTitle('export.pedigree_stats_section'.tr()),
        pw.SizedBox(height: 8),
        _chartBuilder.buildStats(ancestorCount, possible, deepestGen, completeness),
        ..._tableBuilder.buildDeepTables(generations, maxDepth),
      ],
    );
  }

  // ── Header ──

  pw.Widget _buildHeader(Bird rootBird) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(AppConstants.appName,
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600)),
                pw.SizedBox(height: 2),
                pw.Text(
                  'export.pedigree_report_title'.tr(args: [rootBird.name]),
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PedigreePdfColors.brandDark),
                ),
              ],
            ),
            pw.Text(PedigreePdfHelpers.dateFormat.format(DateTime.now()),
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: PedigreePdfColors.accentBlue),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(AppConstants.appName,
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey500)),
          pw.Text('${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  // ── Utilities ──

  Bird? _resolve(String? id, Map<String, Bird> ancestors) =>
      id != null ? ancestors[id] : null;

  void _collectByGeneration(Bird? bird, int depth, Map<String, Bird> ancestors,
      Map<int, List<Bird>> generations, int maxDepth) {
    if (bird == null || depth > maxDepth) return;
    generations.putIfAbsent(depth, () => []).add(bird);
    final father = bird.fatherId != null ? ancestors[bird.fatherId] : null;
    final mother = bird.motherId != null ? ancestors[bird.motherId] : null;
    _collectByGeneration(father, depth + 1, ancestors, generations, maxDepth);
    _collectByGeneration(mother, depth + 1, ancestors, generations, maxDepth);
  }
}
