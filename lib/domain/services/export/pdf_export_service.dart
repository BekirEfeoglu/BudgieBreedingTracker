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

  pw.Page _buildCoverPage() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              AppConstants.appName,
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'export.data_report'.tr(),
              style: const pw.TextStyle(fontSize: 18),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              _dateFormat.format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  pw.Page _buildBirdsPage(List<Bird> birds) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) =>
          _header('export.section_birds'.tr(args: ['${birds.length}'])),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(4),
          headers: [
            'export.header_name'.tr(),
            'export.header_ring_number'.tr(),
            'export.header_gender'.tr(),
            'export.header_status'.tr(),
            'export.header_birth_date'.tr(),
          ],
          data: birds.map((b) {
            return [
              b.name,
              b.ringNumber ?? '-',
              _genderLabel(b.gender.name),
              _statusLabel(b.status.name),
              b.birthDate != null ? _dateFormat.format(b.birthDate!) : '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Page _buildBreedingPage(List<BreedingPair> pairs) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) =>
          _header('export.section_breeding'.tr(args: ['${pairs.length}'])),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(4),
          headers: [
            'export.header_id'.tr(),
            'export.header_cage'.tr(),
            'export.header_status'.tr(),
            'export.header_pairing_date'.tr(),
            'export.header_separation_date'.tr(),
          ],
          data: pairs.map((p) {
            return [
              p.id.substring(0, 8),
              p.cageNumber ?? '-',
              p.status.name,
              p.pairingDate != null ? _dateFormat.format(p.pairingDate!) : '-',
              p.separationDate != null
                  ? _dateFormat.format(p.separationDate!)
                  : '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Page _buildEggsPage(List<Egg> eggs) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) =>
          _header('export.section_eggs'.tr(args: ['${eggs.length}'])),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(4),
          headers: [
            'export.header_no'.tr(),
            'export.header_lay_date'.tr(),
            'export.header_status'.tr(),
            'export.header_hatch_date'.tr(),
          ],
          data: eggs.map((e) {
            return [
              '${e.eggNumber ?? "-"}',
              _dateFormat.format(e.layDate),
              e.status.name,
              e.hatchDate != null ? _dateFormat.format(e.hatchDate!) : '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Page _buildChicksPage(List<Chick> chicks) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) =>
          _header('export.section_chicks'.tr(args: ['${chicks.length}'])),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(4),
          headers: [
            'export.header_name'.tr(),
            'export.header_ring'.tr(),
            'export.header_gender'.tr(),
            'export.header_health'.tr(),
            'export.header_hatch_date'.tr(),
          ],
          data: chicks.map((c) {
            return [
              c.name ?? '-',
              c.ringNumber ?? '-',
              _genderLabel(c.gender.name),
              c.healthStatus.name,
              c.hatchDate != null ? _dateFormat.format(c.hatchDate!) : '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _header(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  String _genderLabel(String name) => switch (name) {
    'male' => 'export.gender_male'.tr(),
    'female' => 'export.gender_female'.tr(),
    _ => 'export.gender_unknown'.tr(),
  };

  String _statusLabel(String name) => switch (name) {
    'alive' => 'export.status_alive'.tr(),
    'dead' => 'export.status_dead'.tr(),
    'sold' => 'export.status_sold'.tr(),
    _ => name,
  };
}
