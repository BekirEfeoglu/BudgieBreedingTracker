import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';

void main() {
  group('ConflictType', () {
    test('toJson returns enum name', () {
      expect(ConflictType.serverWins.toJson(), 'serverWins');
      expect(ConflictType.orphanDeleted.toJson(), 'orphanDeleted');
    });

    test('fromJson returns correct value', () {
      expect(ConflictType.fromJson('serverWins'), ConflictType.serverWins);
      expect(
        ConflictType.fromJson('orphanDeleted'),
        ConflictType.orphanDeleted,
      );
    });

    test('fromJson returns unknown for invalid value', () {
      expect(ConflictType.fromJson('invalid'), ConflictType.unknown);
      expect(ConflictType.fromJson(''), ConflictType.unknown);
    });
  });
}
