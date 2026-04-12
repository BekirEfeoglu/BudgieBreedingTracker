import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/migration_utils.dart';

void main() {
  group('assertSafeIdentifier', () {
    test('accepts valid lowercase identifiers', () {
      expect(() => assertSafeIdentifier('birds'), returnsNormally);
      expect(() => assertSafeIdentifier('breeding_pairs'), returnsNormally);
      expect(() => assertSafeIdentifier('user_id'), returnsNormally);
      expect(() => assertSafeIdentifier('a'), returnsNormally);
      expect(() => assertSafeIdentifier('_'), returnsNormally);
    });

    test('throws on SQL injection attempts', () {
      expect(
        () => assertSafeIdentifier("birds; DROP TABLE users"),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => assertSafeIdentifier("birds'--"),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => assertSafeIdentifier('birds OR 1=1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on uppercase characters', () {
      expect(
        () => assertSafeIdentifier('Birds'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => assertSafeIdentifier('BIRDS'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on digits', () {
      expect(
        () => assertSafeIdentifier('table1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on empty string', () {
      expect(
        () => assertSafeIdentifier(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on special characters', () {
      expect(
        () => assertSafeIdentifier('bird-name'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => assertSafeIdentifier('bird.name'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => assertSafeIdentifier('bird name'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('isSafeIdentifier', () {
    test('returns true for valid identifiers', () {
      expect(isSafeIdentifier('birds'), isTrue);
      expect(isSafeIdentifier('breeding_pairs'), isTrue);
      expect(isSafeIdentifier('user_id'), isTrue);
    });

    test('returns false for invalid identifiers', () {
      expect(isSafeIdentifier(''), isFalse);
      expect(isSafeIdentifier('Birds'), isFalse);
      expect(isSafeIdentifier('table1'), isFalse);
      expect(isSafeIdentifier("birds; DROP TABLE"), isFalse);
    });
  });
}
