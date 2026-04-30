import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/maintenance_mode_provider.dart';

void main() {
  group('parseMaintenanceModeValue', () {
    test('parses boolean values', () {
      expect(parseMaintenanceModeValue(true), isTrue);
      expect(parseMaintenanceModeValue(false), isFalse);
    });

    test('parses string values', () {
      expect(parseMaintenanceModeValue('true'), isTrue);
      expect(parseMaintenanceModeValue('TRUE'), isTrue);
      expect(parseMaintenanceModeValue('false'), isFalse);
    });

    test('defaults unknown values to false', () {
      expect(parseMaintenanceModeValue(null), isFalse);
      expect(parseMaintenanceModeValue(1), isFalse);
    });
  });
}
