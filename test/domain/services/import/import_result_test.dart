import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/import/import_result.dart';

void main() {
  group('ImportResult', () {
    test('stores all import summary fields', () {
      const result = ImportResult(
        totalRows: 25,
        importedCount: 19,
        skippedCount: 6,
        errors: ['row 4 invalid date', 'row 18 missing ring number'],
      );

      expect(result.totalRows, 25);
      expect(result.importedCount, 19);
      expect(result.skippedCount, 6);
      expect(result.errors, [
        'row 4 invalid date',
        'row 18 missing ring number',
      ]);
    });
  });
}
