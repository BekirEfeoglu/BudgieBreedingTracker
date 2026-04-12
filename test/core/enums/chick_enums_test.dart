import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';

void main() {
  group('ChickHealthStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in ChickHealthStatus.values) {
        expect(ChickHealthStatus.fromJson(value.toJson()), value);
      }
    });

    test('has expected value count', () {
      expect(ChickHealthStatus.values.length, 4);
    });
  });

  group('DevelopmentStage', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in DevelopmentStage.values) {
        expect(DevelopmentStage.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(DevelopmentStage.fromJson('invalid'), DevelopmentStage.unknown);
      expect(DevelopmentStage.fromJson(''), DevelopmentStage.unknown);
    });

    test('has expected value count', () {
      expect(DevelopmentStage.values.length, 5);
    });
  });
}
