@Tags(['e2e'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';
import 'package:budgie_breeding_tracker/domain/services/import/import_result.dart';
import 'package:budgie_breeding_tracker/domain/services/import/import_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/export_providers.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Backup & Export Flow E2E', () {
    test(
      'GIVEN backup screen WHEN backup is triggered THEN createBackup is called and backup metadata is available',
      () async {
        final mockBackupService = MockBackupService();
        when(() => mockBackupService.createBackup('test-user')).thenAnswer(
          (_) async => BackupResult.success(
            filePath: 'C:/tmp/backup.json',
            recordCount: 12,
          ),
        );

        final container = createTestContainer(
          overrides: [
            backupServiceProvider.overrideWithValue(mockBackupService),
          ],
        );
        addTearDown(container.dispose);

        final result = await container
            .read(backupServiceProvider)
            .createBackup('test-user');

        expect(result.success, isTrue);
        expect(result.filePath, contains('backup'));
        expect(result.recordCount, 12);
        verify(() => mockBackupService.createBackup('test-user')).called(1);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN existing backup file WHEN restore import is confirmed THEN DataImportService processes rows and returns import summary',
      () async {
        final mockImportService = MockDataImportService();
        final bytes = Uint8List.fromList([1, 2, 3, 4]);

        when(
          () => mockImportService.importAllFromExcel(
            bytes: bytes,
            userId: 'test-user',
          ),
        ).thenAnswer(
          (_) async => const <String, ImportResult>{
            'birds': ImportResult(
              totalRows: 2,
              importedCount: 2,
              skippedCount: 0,
              errors: [],
            ),
          },
        );

        final container = createTestContainer(
          overrides: [
            dataImportServiceProvider.overrideWithValue(mockImportService),
          ],
        );
        addTearDown(container.dispose);

        final result = await container
            .read(dataImportServiceProvider)
            .importAllFromExcel(bytes: bytes, userId: 'test-user');

        expect(result['birds']?.importedCount, 2);
        verify(
          () => mockImportService.importAllFromExcel(
            bytes: bytes,
            userId: 'test-user',
          ),
        ).called(1);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN export settings WHEN PDF report is generated THEN PdfExportService.generateFullReport returns bytes ready for sharing',
      () async {
        final mockPdfExportService = MockPdfExportService();
        const birds = <Bird>[];
        const pairs = <BreedingPair>[];
        const eggs = <Egg>[];
        const chicks = <Chick>[];
        when(
          () => mockPdfExportService.generateFullReport(
            birds: birds,
            pairs: pairs,
            eggs: eggs,
            chicks: chicks,
          ),
        ).thenAnswer((_) async => Uint8List.fromList([10, 20, 30]));

        final container = createTestContainer(
          overrides: [
            pdfExportServiceProvider.overrideWithValue(mockPdfExportService),
          ],
        );
        addTearDown(container.dispose);

        final bytes = await container
            .read(pdfExportServiceProvider)
            .generateFullReport(
              birds: birds,
              pairs: pairs,
              eggs: eggs,
              chicks: chicks,
            );

        expect(bytes, isNotEmpty);
        verify(
          () => mockPdfExportService.generateFullReport(
            birds: birds,
            pairs: pairs,
            eggs: eggs,
            chicks: chicks,
          ),
        ).called(1);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN export settings WHEN Excel export is requested THEN ExcelExportService.exportAll returns xlsx bytes',
      () async {
        final mockExcelExportService = MockExcelExportService();
        const birds = <Bird>[];
        const pairs = <BreedingPair>[];
        const eggs = <Egg>[];
        const chicks = <Chick>[];
        when(
          () => mockExcelExportService.exportAll(
            birds: birds,
            pairs: pairs,
            eggs: eggs,
            chicks: chicks,
          ),
        ).thenAnswer((_) async => Uint8List.fromList([1, 99, 5]));

        final container = createTestContainer(
          overrides: [
            excelExportServiceProvider.overrideWithValue(
              mockExcelExportService,
            ),
          ],
        );
        addTearDown(container.dispose);

        final bytes = await container
            .read(excelExportServiceProvider)
            .exportAll(birds: birds, pairs: pairs, eggs: eggs, chicks: chicks);

        expect(bytes, isNotEmpty);
        verify(
          () => mockExcelExportService.exportAll(
            birds: birds,
            pairs: pairs,
            eggs: eggs,
            chicks: chicks,
          ),
        ).called(1);
      },
      timeout: e2eTimeout,
    );
  });
}
