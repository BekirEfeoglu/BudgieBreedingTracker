import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../../data/models/bird_model.dart';
import 'pedigree_pdf_builder.dart';
import '../../../data/models/breeding_pair_model.dart';
import '../../../data/models/chick_model.dart';
import '../../../data/models/egg_model.dart';
import '../../../data/models/incubation_model.dart';
import '../../../data/models/statistics_highlight_models.dart';

part 'pdf_export_page_builders.dart';

/// Generates PDF reports for birds, breeding pairs, eggs, and chicks.
/// Uses bundled Roboto TTF fonts for full Turkish character support.
class PdfExportService {
  PdfExportService();

  static final _dateFormat = DateFormat('dd.MM.yyyy');

  pw.Font? _regularFont;
  pw.Font? _boldFont;

  /// Loads Roboto TTF fonts from bundled assets.
  Future<void> _ensureFontsLoaded() async {
    if (_regularFont != null) return;
    final regularData = await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    );
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    _regularFont = pw.Font.ttf(regularData);
    _boldFont = pw.Font.ttf(boldData);
  }

  pw.ThemeData get _theme =>
      pw.ThemeData.withFont(base: _regularFont!, bold: _boldFont!);

  /// Generates a full data report containing all entities.
  Future<Uint8List> generateFullReport({
    required List<Bird> birds,
    required List<BreedingPair> pairs,
    required List<Incubation> incubations,
    required List<Egg> eggs,
    required List<Chick> chicks,
  }) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document(
      title: 'export.report_title'.tr(args: [AppConstants.appName]),
      author: AppConstants.appName,
      theme: _theme,
    );

    pdf.addPage(_buildCoverPage());
    if (birds.isNotEmpty) pdf.addPage(_buildBirdsPage(birds));
    if (pairs.isNotEmpty) pdf.addPage(_buildBreedingPage(pairs));
    if (incubations.isNotEmpty) {
      pdf.addPage(_buildIncubationsPage(incubations));
    }
    if (eggs.isNotEmpty) pdf.addPage(_buildEggsPage(eggs));
    if (chicks.isNotEmpty) pdf.addPage(_buildChicksPage(chicks));

    return pdf.save();
  }

  /// Generates a bird list report.
  Future<Uint8List> generateBirdReport(List<Bird> birds) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document(
      title: 'export.report_birds'.tr(args: [AppConstants.appName]),
      author: AppConstants.appName,
      theme: _theme,
    );
    pdf.addPage(_buildBirdsPage(birds));
    return pdf.save();
  }

  /// Generates a breeding report.
  Future<Uint8List> generateBreedingReport(List<BreedingPair> pairs) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document(
      title: 'export.report_breeding'.tr(args: [AppConstants.appName]),
      author: AppConstants.appName,
      theme: _theme,
    );
    pdf.addPage(_buildBreedingPage(pairs));
    return pdf.save();
  }

  /// Generates a pedigree report for a single bird with ancestor generations.
  Future<Uint8List> generatePedigreeReport({
    required Bird rootBird,
    required Map<String, Bird> ancestors,
    required int maxDepth,
  }) async {
    await _ensureFontsLoaded();
    final builder = PedigreePdfBuilder(
      regularFont: _regularFont!,
      boldFont: _boldFont!,
    );
    final pdf = pw.Document(
      title: 'export.pedigree_report_title'.tr(args: [rootBird.name]),
      author: AppConstants.appName,
      theme: _theme,
    );
    pdf.addPage(builder.build(rootBird, ancestors, maxDepth));
    return pdf.save();
  }

  /// Generates a statistics highlights report.
  Future<Uint8List> generateStatisticsReport({
    required PersonalRecords personalRecords,
    required SeasonComparison? seasonComparison,
    required HealthTrendSummary healthTrend,
  }) async {
    await _ensureFontsLoaded();
    final pdf = pw.Document(
      title: 'statistics.title'.tr(),
      author: AppConstants.appName,
      theme: _theme,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          _header('statistics.title'.tr()),
          _statisticsSection('statistics.personal_records'.tr(), [
            [
              'statistics.record_best_season'.tr(),
              personalRecords.mostProductiveSeason == null
                  ? 'common.not_available'.tr()
                  : '${personalRecords.mostProductiveSeason!.year} · '
                        '${personalRecords.mostProductiveSeason!.chickCount}',
            ],
            [
              'statistics.record_top_pair'.tr(),
              personalRecords.topPair == null
                  ? 'common.not_available'.tr()
                  : '${personalRecords.topPair!.pairId} · '
                        '${personalRecords.topPair!.chickCount}',
            ],
            [
              'statistics.record_longest_lived'.tr(),
              personalRecords.longestLivedBird == null
                  ? 'common.not_available'.tr()
                  : '${personalRecords.longestLivedBird!.birdName} · '
                        '${(personalRecords.longestLivedBird!.daysLived / 365.25).toStringAsFixed(1)}',
            ],
          ]),
          _statisticsSection('statistics.season_comparison'.tr(), [
            if (seasonComparison == null)
              [
                'statistics.season_comparison'.tr(),
                'statistics.season_comparison_empty'.tr(),
              ]
            else ...[
              [
                seasonComparison.previous.year.toString(),
                _seasonPdfValue(seasonComparison.previous),
              ],
              [
                seasonComparison.current.year.toString(),
                _seasonPdfValue(seasonComparison.current),
              ],
              [
                'statistics.fertility_change'.tr(),
                (seasonComparison.fertilityDelta * 100).toStringAsFixed(1),
              ],
            ],
          ]),
          _statisticsSection('statistics.health_trend'.tr(), [
            [
              'statistics.health_peak_month'.tr(),
              healthTrend.busiestMonthKey == null
                  ? 'common.not_available'.tr()
                  : '${healthTrend.busiestMonthKey} · '
                        '${healthTrend.busiestMonthRecordCount}',
            ],
            [
              'statistics.health_most_visited'.tr(),
              healthTrend.mostVisitedBirdName == null
                  ? 'common.not_available'.tr()
                  : '${healthTrend.mostVisitedBirdName} · '
                        '${healthTrend.mostVisitedBirdRecordCount}',
            ],
            [
              'statistics.health_avg_treatment'.tr(),
              healthTrend.averageTreatmentDays == null
                  ? 'common.not_available'.tr()
                  : healthTrend.averageTreatmentDays!.toStringAsFixed(1),
            ],
          ]),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _statisticsSection(String title, List<List<String>> rows) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(title),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: ['common.description'.tr(), 'statistics.title'.tr()],
            data: rows,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _seasonPdfValue(SeasonStats stats) {
    return '${'statistics.total_eggs'.tr()}: ${stats.totalEggs}, '
        '${'statistics.fertility_rate'.tr()}: '
        '${(stats.fertilityRate * 100).toStringAsFixed(1)}%, '
        '${'statistics.hatched_chicks'.tr()}: ${stats.hatchedChicks}, '
        '${'statistics.live_chicks'.tr()}: ${stats.liveChicks}';
  }
}
