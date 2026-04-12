import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';

void main() {
  group('PhotoEntityType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in PhotoEntityType.values) {
        expect(PhotoEntityType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(PhotoEntityType.fromJson('invalid'), PhotoEntityType.unknown);
      expect(PhotoEntityType.fromJson(''), PhotoEntityType.unknown);
      expect(PhotoEntityType.fromJson('photo'), PhotoEntityType.unknown);
    });

    test('has expected value count', () {
      expect(PhotoEntityType.values.length, 5);
    });
  });
}
