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
import '../../../data/models/incubation_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/export/excel_export_service.dart';
import '../../../domain/services/export/pdf_export_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import '../../../core/utils/logger.dart';

/// Notifier for export loading state.
class ExportLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
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
        incubations: data.incubations,
        eggs: data.eggs,
        chicks: data.chicks,
      );
      await _shareFile(bytes, 'budgie_rapor.pdf');
      _ref.read(lastExportDateProvider.notifier).state = DateTime.now();
    } catch (e, st) {
      AppLogger.error('ExportActions.exportPdf', e, st);
      ActionFeedbackService.show(
        'backup.export_error'.tr(),
        type: ActionFeedbackType.error,
      );
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
        incubations: data.incubations,
        eggs: data.eggs,
        chicks: data.chicks,
      );
      await _shareFile(bytes, 'budgie_veri.xlsx');
      _ref.read(lastExportDateProvider.notifier).state = DateTime.now();
    } catch (e, st) {
      AppLogger.error('ExportActions.exportExcel', e, st);
      ActionFeedbackService.show(
        'backup.export_error'.tr(),
        type: ActionFeedbackType.error,
      );
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
    } catch (e, st) {
      AppLogger.error('ExportActions.exportBirdsPdf', e, st);
      ActionFeedbackService.show(
        'backup.export_error'.tr(),
        type: ActionFeedbackType.error,
      );
    } finally {
      _ref.read(exportLoadingProvider.notifier).state = false;
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
    ).wait;
    return _ExportData(
      birds: results.$1,
      pairs: results.$2,
      incubations: results.$3,
      eggs: results.$4,
      chicks: results.$5,
    );
  }

  Future<void> _shareFile(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = fileName.replaceAll('.', '_$timestamp.');
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}

class _ExportData {
  final List<Bird> birds;
  final List<BreedingPair> pairs;
  final List<Incubation> incubations;
  final List<Egg> eggs;
  final List<Chick> chicks;

  _ExportData({
    required this.birds,
    required this.pairs,
    required this.incubations,
    required this.eggs,
    required this.chicks,
  });
}
