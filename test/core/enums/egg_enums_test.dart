import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';

void main() {
  group('EggStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in EggStatus.values) {
        expect(EggStatus.fromJson(value.toJson()), value);
      }
    });

    test('has expected 9 values', () {
      expect(EggStatus.values.length, 9);
    });

    test('contains all expected statuses', () {
      final names = EggStatus.values.map((e) => e.name).toSet();
      expect(
        names,
        containsAll([
          'unknown',
          'laid',
          'fertile',
          'infertile',
          'hatched',
          'empty',
          'damaged',
          'discarded',
          'incubating',
        ]),
      );
    });
  });
}
