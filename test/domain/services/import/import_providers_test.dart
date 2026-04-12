import 'dart:typed_data';

import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/import/import_providers.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

Uint8List _buildBirdWorkbookBytes() {
  final excel = Excel.createExcel();
  final sheet = excel['Kuslar'];
  sheet.appendRow(
    [
      'Ad',
      'Halka No',
      'Cinsiyet',
      'Tur',
      'Durum',
      'Dogum Tarihi',
      'Renk',
      'Kafes',
      'Notlar',
    ].map(TextCellValue.new).toList(),
  );
  sheet.appendRow(
    [
      'Mavi',
      'TR-1',
      'Erkek',
      'Budgie',
      'Alive',
      '01.01.2025',
      '',
      'A1',
      '',
    ].map(TextCellValue.new).toList(),
  );
  return Uint8List.fromList(excel.save()!);
}

void main() {
  late MockBirdRepository birdRepo;
  late MockBreedingPairRepository breedingRepo;
  late MockEggRepository eggRepo;
  late MockChickRepository chickRepo;
  late MockHealthRecordRepository healthRepo;

  setUpAll(() {
    registerFallbackValue(createTestBird());
  });

  setUp(() {
    birdRepo = MockBirdRepository();
    breedingRepo = MockBreedingPairRepository();
    eggRepo = MockEggRepository();
    chickRepo = MockChickRepository();
    healthRepo = MockHealthRecordRepository();

    when(() => birdRepo.save(any())).thenAnswer((_) async {});
  });

  test('dataImportServiceProvider uses overridden repositories', () async {
    final container = ProviderContainer(
      overrides: [
        birdRepositoryProvider.overrideWithValue(birdRepo),
        breedingPairRepositoryProvider.overrideWithValue(breedingRepo),
        eggRepositoryProvider.overrideWithValue(eggRepo),
        chickRepositoryProvider.overrideWithValue(chickRepo),
        healthRecordRepositoryProvider.overrideWithValue(healthRepo),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(dataImportServiceProvider);
    final result = await service.importBirdsFromExcel(
      bytes: _buildBirdWorkbookBytes(),
      userId: 'user-1',
    );

    expect(result.importedCount, 1);
    verify(() => birdRepo.save(any())).called(1);
  });
}
