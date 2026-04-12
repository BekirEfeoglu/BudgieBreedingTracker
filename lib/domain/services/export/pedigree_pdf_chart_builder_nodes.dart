part of 'pedigree_pdf_chart_builder.dart';

// ---------------------------------------------------------------------------
// Chart node rendering & stat helpers for PedigreePdfChartBuilder
// ---------------------------------------------------------------------------

pw.Widget _buildChartNode(
  Bird? bird, {
  bool isRoot = false,
  bool small = false,
}) {
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

pw.Widget _buildStatItem(String label, String value) => pw.Column(
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

pw.Widget _buildStatDivider() =>
    pw.Container(width: 1, height: 30, color: PdfColors.grey300);
