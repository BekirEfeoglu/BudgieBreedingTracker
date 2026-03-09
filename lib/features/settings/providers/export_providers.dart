import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/export/excel_export_service.dart';
import '../../../domain/services/export/pdf_export_service.dart';
import '../../auth/providers/auth_providers.dart';

/// Notifier for export loading state.
class ExportLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

/// Whether an export operation is currently in progress.
final exportLoadingProvider =
    NotifierProvider<ExportLoadingNotifier, bool>(ExportLoadingNotifier.new);

/// Notifier for last export date.
class LastExportDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
}

/// Last export date, persisted only in memory for current session.
final lastExportDateProvider =
    NotifierProvider<LastExportDateNotifier, DateTime?>(LastExportDateNotifier.new);

/// Service providers.
final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

final excelExportServiceProvider = Provider<ExcelExportService>((ref) {
  return ExcelExportService();
});

/// Export actions callable from the UI.
final exportActionsProvider = Provider<ExportActions>((ref) {
  return ExportActions(ref);
});

/// Encapsulates export operations for PDF and Excel formats.
class ExportActions {
  ExportActions(this._ref);

  final Ref _ref;

  /// Exports all data as PDF and triggers share dialog.
  Future<void> exportPdf() async {
    _ref.read(exportLoadingProvider.notifier).state = true;
    try {
      final data = await _fetchAllData();
      final pdfService = _ref.read(pdfExportServiceProvider);
      final bytes = await pdfService.generateFullReport(
        birds: data.birds,
        pairs: data.pairs,
        eggs: data.eggs,
        chicks: data.chicks,
      );
      await _shareFile(bytes, 'budgie_rapor.pdf');
      _ref.read(lastExportDateProvider.notifier).state = DateTime.now();
    } finally {
      _ref.read(exportLoadingProvider.notifier).state = false;
    }
  }

  /// Exports all data as Excel and triggers share dialog.
  Future<void> exportExcel() async {
    _ref.read(exportLoadingProvider.notifier).state = true;
    try {
      final data = await _fetchAllData();
      final excelService = _ref.read(excelExportServiceProvider);
      final bytes = await excelService.exportAll(
        birds: data.birds,
        pairs: data.pairs,
        eggs: data.eggs,
        chicks: data.chicks,
      );
      await _shareFile(bytes, 'budgie_veri.xlsx');
      _ref.read(lastExportDateProvider.notifier).state = DateTime.now();
    } finally {
      _ref.read(exportLoadingProvider.notifier).state = false;
    }
  }

  /// Exports only the bird list as PDF.
  Future<void> exportBirdsPdf() async {
    _ref.read(exportLoadingProvider.notifier).state = true;
    try {
      final userId = _ref.read(currentUserIdProvider);
      final birds = await _ref.read(birdRepositoryProvider).getAll(userId);
      final pdfService = _ref.read(pdfExportServiceProvider);
      final bytes = await pdfService.generateBirdReport(birds);
      await _shareFile(bytes, 'kuslar.pdf');
    } finally {
      _ref.read(exportLoadingProvider.notifier).state = false;
    }
  }

  Future<_ExportData> _fetchAllData() async {
    final userId = _ref.read(currentUserIdProvider);
    final results = await Future.wait([
      _ref.read(birdRepositoryProvider).getAll(userId),
      _ref.read(breedingPairRepositoryProvider).getAll(userId),
      _ref.read(eggRepositoryProvider).getAll(userId),
      _ref.read(chickRepositoryProvider).getAll(userId),
    ]);
    return _ExportData(
      birds: results[0] as dynamic,
      pairs: results[1] as dynamic,
      eggs: results[2] as dynamic,
      chicks: results[3] as dynamic,
    );
  }

  Future<void> _shareFile(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = fileName.replaceAll('.', '_$timestamp.');
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}

class _ExportData {
  final dynamic birds;
  final dynamic pairs;
  final dynamic eggs;
  final dynamic chicks;

  _ExportData({
    required this.birds,
    required this.pairs,
    required this.eggs,
    required this.chicks,
  });
}
