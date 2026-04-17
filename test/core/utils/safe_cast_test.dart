import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/utils/safe_cast.dart';

void main() {
  group('safeString', () {
    test('returns value for valid non-empty String', () {
      expect(safeString({'k': 'hello'}, 'k'), 'hello');
    });

    test('returns null for missing key', () {
      expect(safeString({'a': 'x'}, 'b'), isNull);
    });

    test('returns null when map is null', () {
      expect(safeString(null, 'k'), isNull);
    });

    test('returns null for empty and whitespace-only values', () {
      expect(safeString({'k': ''}, 'k'), isNull);
      expect(safeString({'k': '   '}, 'k'), isNull);
    });

    test('returns null when value is not a String', () {
      expect(safeString({'k': 42}, 'k'), isNull);
      expect(safeString({'k': true}, 'k'), isNull);
      expect(safeString({'k': <String, dynamic>{}}, 'k'), isNull);
      expect(safeString({'k': const []}, 'k'), isNull);
      expect(safeString({'k': null}, 'k'), isNull);
    });
  });

  group('safeMap', () {
    test('returns typed map for Map<String, dynamic> value', () {
      final result = safeMap({'data': {'a': 1}}, 'data');
      expect(result, {'a': 1});
    });

    test('converts Map<dynamic, dynamic>', () {
      final raw = <dynamic, dynamic>{'a': 1};
      final result = safeMap({'data': raw}, 'data');
      expect(result, isA<Map<String, dynamic>>());
      expect(result!['a'], 1);
    });

    test('returns null for non-Map value', () {
      expect(safeMap({'data': 'str'}, 'data'), isNull);
      expect(safeMap({'data': 1}, 'data'), isNull);
      expect(safeMap({'data': const []}, 'data'), isNull);
    });

    test('returns null for null map or missing key', () {
      expect(safeMap(null, 'data'), isNull);
      expect(safeMap({}, 'data'), isNull);
    });
  });

  group('safeList', () {
    test('returns the list when present', () {
      expect(safeList({'items': [1, 2]}, 'items'), [1, 2]);
    });

    test('returns empty list for missing key or non-list value', () {
      expect(safeList({}, 'items'), isEmpty);
      expect(safeList({'items': 'not-a-list'}, 'items'), isEmpty);
      expect(safeList(null, 'items'), isEmpty);
    });
  });

  group('asStringMap', () {
    test('returns Map<String, dynamic> unchanged', () {
      final m = <String, dynamic>{'a': 1};
      expect(asStringMap(m), same(m));
    });

    test('converts Map<dynamic, dynamic>', () {
      final result = asStringMap(<dynamic, dynamic>{'a': 1});
      expect(result, isA<Map<String, dynamic>>());
      expect(result!['a'], 1);
    });

    test('returns null for non-Map input', () {
      expect(asStringMap(null), isNull);
      expect(asStringMap('str'), isNull);
      expect(asStringMap(42), isNull);
      expect(asStringMap(const []), isNull);
    });
  });
}
