part of 'pdf_export_service.dart';

extension _PdfPageBuilders on PdfExportService {
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
              PdfExportService._dateFormat.format(DateTime.now()),
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
              b.birthDate != null ? PdfExportService._dateFormat.format(b.birthDate!) : '-',
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
              p.pairingDate != null ? PdfExportService._dateFormat.format(p.pairingDate!) : '-',
              p.separationDate != null
                  ? PdfExportService._dateFormat.format(p.separationDate!)
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
              PdfExportService._dateFormat.format(e.layDate),
              e.status.name,
              e.hatchDate != null ? PdfExportService._dateFormat.format(e.hatchDate!) : '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Page _buildIncubationsPage(List<Incubation> incubations) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => _header(
        'export.section_incubations'.tr(args: ['${incubations.length}']),
      ),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(4),
          headers: [
            'export.header_id'.tr(),
            'export.header_breeding_pair_id'.tr(),
            'export.header_species'.tr(),
            'export.header_status'.tr(),
            'export.header_expected_hatch_date'.tr(),
          ],
          data: incubations.map((incubation) {
            return [
              incubation.id.substring(0, 8),
              incubation.breedingPairId ?? '-',
              incubation.species.name,
              incubation.status.name,
              incubation.computedExpectedHatchDate != null
                  ? PdfExportService._dateFormat.format(incubation.computedExpectedHatchDate!)
                  : '-',
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
              c.hatchDate != null ? PdfExportService._dateFormat.format(c.hatchDate!) : '-',
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
