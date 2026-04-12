import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/import/data_import_service.dart';

/// Provides the [DataImportService] for importing data from Excel files.
final dataImportServiceProvider = Provider<DataImportService>((ref) {
  return DataImportService(
    ref.watch(birdRepositoryProvider),
    ref.watch(breedingPairRepositoryProvider),
    ref.watch(eggRepositoryProvider),
    ref.watch(chickRepositoryProvider),
    ref.watch(healthRecordRepositoryProvider),
  );
});
