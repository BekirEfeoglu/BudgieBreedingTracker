import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/bird_model.dart';
import '../../../data/models/breeding_pair_model.dart';
import '../../../data/models/chick_model.dart';
import '../../../data/models/egg_model.dart';
import '../../../data/models/health_record_model.dart';
import '../../../data/models/incubation_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/export/excel_export_service.dart';
import '../../../domain/services/export/pdf_export_service.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';
import '../../../core/utils/logger.dart';

/// Notifier for export loading state.
class ExportLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks an export/import operation as running or finished.
  void set(bool value) => state = value;
}

/// Whether an export operation is currently in progress.
final exportLoadingProvider = NotifierProvider<ExportLoadingNotifier, bool>(
  ExportLoadingNotifier.new,
);

/// Notifier for last export date.
class LastExportDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
}

/// Last export date, persisted only in memory for current session.
final lastExportDateProvider =
    NotifierProvider<LastExportDateNotifier, DateTime?>(
      LastExportDateNotifier.new,
    );

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
///
/// Each export method returns `true` when the export completed, `false` when
/// it was skipped because another export/import is already running, and
/// rethrows on failure so callers can decide on feedback and side effects
/// (e.g. consuming a reward-ad use only after real success).
class ExportActions {
  ExportActions(this._ref);

  final Ref _ref;

  /// Exports all data as PDF and triggers share dialog.
  Future<bool> exportPdf() => _runExport('exportPdf', () async {
    final data = await _fetchAllData();
    final pdfService = _ref.read(pdfExportServiceProvider);
    final bytes = await pdfService.generateFullReport(
      birds: data.birds,
      pairs: data.pairs,
      incubations: data.incubations,
      eggs: data.eggs,
      chicks: data.chicks,
    );
    await _shareFile(bytes, 'budgie_rapor.pdf');
  });

  /// Exports all data as Excel and triggers share dialog.
  Future<bool> exportExcel() => _runExport('exportExcel', () async {
    final data = await _fetchAllData();
    final excelService = _ref.read(excelExportServiceProvider);
    final bytes = await excelService.exportAll(
      birds: data.birds,
      pairs: data.pairs,
      incubations: data.incubations,
      eggs: data.eggs,
      chicks: data.chicks,
      healthRecords: data.healthRecords,
    );
    await _shareFile(bytes, 'budgie_veri.xlsx');
  });

  /// Exports only the bird list as PDF.
  Future<bool> exportBirdsPdf() => _runExport('exportBirdsPdf', () async {
    final userId = _ref.read(currentUserIdProvider);
    final birds = await _ref.read(birdRepositoryProvider).getAll(userId);
    final pdfService = _ref.read(pdfExportServiceProvider);
    final bytes = await pdfService.generateBirdReport(birds);
    await _shareFile(bytes, 'kuslar.pdf');
  });

  Future<bool> _runExport(String name, Future<void> Function() export) async {
    final loading = _ref.read(exportLoadingProvider.notifier);
    // In-flight guard: the UI disables tiles, but any second entry point
    // (import flow, double invocation) must not start a concurrent export.
    if (_ref.read(exportLoadingProvider)) return false;
    loading.set(true);
    try {
      await export();
      _ref.read(lastExportDateProvider.notifier).state = DateTime.now();
      return true;
    } catch (e, st) {
      AppLogger.error('ExportActions.$name', e, st);
      rethrow;
    } finally {
      loading.set(false);
    }
  }

  Future<_ExportData> _fetchAllData() async {
    final userId = _ref.read(currentUserIdProvider);
    final results = await (
      _ref.read(birdRepositoryProvider).getAll(userId),
      _ref.read(breedingPairRepositoryProvider).getAll(userId),
      _ref.read(incubationRepositoryProvider).getAll(userId),
      _ref.read(eggRepositoryProvider).getAll(userId),
      _ref.read(chickRepositoryProvider).getAll(userId),
      _ref.read(healthRecordRepositoryProvider).getAll(userId),
    ).wait;
    return _ExportData(
      birds: results.$1,
      pairs: results.$2,
      incubations: results.$3,
      eggs: results.$4,
      chicks: results.$5,
      healthRecords: results.$6,
    );
  }

  Future<void> _shareFile(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = fileName.replaceAll('.', '_$timestamp.');
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes);
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } finally {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.warning('ExportActions._shareFile cleanup failed: $e');
      }
    }
  }
}

class _ExportData {
  final List<Bird> birds;
  final List<BreedingPair> pairs;
  final List<Incubation> incubations;
  final List<Egg> eggs;
  final List<Chick> chicks;
  final List<HealthRecord> healthRecords;

  _ExportData({
    required this.birds,
    required this.pairs,
    required this.incubations,
    required this.eggs,
    required this.chicks,
    required this.healthRecords,
  });
}
