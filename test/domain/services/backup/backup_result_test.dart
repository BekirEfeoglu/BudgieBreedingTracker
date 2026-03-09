import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/backup/backup_result.dart';

void main() {
  group('BackupResult', () {
    test('success factory populates success fields', () {
      final before = DateTime.now();
      final result = BackupResult.success(
        filePath: '/tmp/backup.json',
        recordCount: 42,
      );
      final after = DateTime.now();

      expect(result.success, isTrue);
      expect(result.filePath, '/tmp/backup.json');
      expect(result.recordCount, 42);
      expect(result.error, isNull);
      expect(result.timestamp.isBefore(before), isFalse);
      expect(result.timestamp.isAfter(after), isFalse);
    });

    test('failure factory populates error fields', () {
      final before = DateTime.now();
      final result = BackupResult.failure('disk full');
      final after = DateTime.now();

      expect(result.success, isFalse);
      expect(result.error, 'disk full');
      expect(result.filePath, isNull);
      expect(result.recordCount, 0);
      expect(result.timestamp.isBefore(before), isFalse);
      expect(result.timestamp.isAfter(after), isFalse);
    });
  });
}
