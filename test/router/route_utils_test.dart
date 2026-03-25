import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/router/route_utils.dart';

void main() {
  group('isValidRouteId', () {
    group('valid UUIDs', () {
      test('accepts standard UUID v4 lowercase', () {
        expect(isValidRouteId('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      });

      test('accepts UUID v4 with uppercase characters', () {
        expect(isValidRouteId('550E8400-E29B-41D4-A716-446655440000'), isTrue);
      });

      test('accepts UUID v4 with mixed case', () {
        expect(isValidRouteId('550e8400-E29B-41d4-a716-446655440000'), isTrue);
      });

      test('accepts all-zero UUID', () {
        expect(isValidRouteId('00000000-0000-0000-0000-000000000000'), isTrue);
      });

      test('accepts all-f UUID', () {
        expect(isValidRouteId('ffffffff-ffff-ffff-ffff-ffffffffffff'), isTrue);
      });

      test('accepts multiple distinct valid UUIDs', () {
        const uuids = [
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          '12345678-1234-1234-1234-123456789abc',
          'deadbeef-dead-beef-dead-beefdeadbeef',
        ];
        for (final uuid in uuids) {
          expect(isValidRouteId(uuid), isTrue, reason: 'Failed for: $uuid');
        }
      });
    });

    group('null and empty', () {
      test('rejects null', () {
        expect(isValidRouteId(null), isFalse);
      });

      test('rejects empty string', () {
        expect(isValidRouteId(''), isFalse);
      });

      test('rejects whitespace-only string', () {
        expect(isValidRouteId('   '), isFalse);
      });
    });

    group('non-UUID strings', () {
      test('rejects plain word', () {
        expect(isValidRouteId('hello'), isFalse);
      });

      test('rejects numeric string', () {
        expect(isValidRouteId('123'), isFalse);
      });

      test('rejects common route names', () {
        expect(isValidRouteId('admin'), isFalse);
        expect(isValidRouteId('form'), isFalse);
        expect(isValidRouteId('settings'), isFalse);
      });

      test('rejects UUID without dashes', () {
        expect(
          isValidRouteId('550e8400e29b41d4a716446655440000'),
          isFalse,
        );
      });

      test('rejects UUID with extra dashes', () {
        expect(
          isValidRouteId('550e-8400-e29b-41d4-a716-446655440000'),
          isFalse,
        );
      });
    });

    group('SQL injection attempts', () {
      test('rejects single quote OR injection', () {
        expect(isValidRouteId("' OR 1=1 --"), isFalse);
      });

      test('rejects DROP TABLE injection', () {
        expect(isValidRouteId("'; DROP TABLE birds;--"), isFalse);
      });

      test('rejects UNION SELECT injection', () {
        expect(
          isValidRouteId("' UNION SELECT * FROM users --"),
          isFalse,
        );
      });

      test('rejects double-dash comment injection', () {
        expect(isValidRouteId('1 OR 1=1 --'), isFalse);
      });

      test('rejects semicolon-terminated injection', () {
        expect(isValidRouteId('1; SELECT * FROM birds'), isFalse);
      });
    });

    group('path traversal attempts', () {
      test('rejects unix path traversal', () {
        expect(isValidRouteId('../../../etc/passwd'), isFalse);
      });

      test('rejects URL-encoded path traversal', () {
        expect(isValidRouteId('..%2F..%2F'), isFalse);
      });

      test('rejects windows path traversal', () {
        expect(isValidRouteId('..\\..\\windows\\system32'), isFalse);
      });

      test('rejects absolute path', () {
        expect(isValidRouteId('/etc/passwd'), isFalse);
      });
    });

    group('URL-encoded attacks', () {
      test('rejects URL-encoded SQL injection', () {
        expect(isValidRouteId('%27%20OR%201%3D1'), isFalse);
      });

      test('rejects URL-encoded angle brackets (XSS)', () {
        expect(isValidRouteId('%3Cscript%3Ealert(1)%3C/script%3E'), isFalse);
      });

      test('rejects double-encoded traversal', () {
        expect(isValidRouteId('%252e%252e%252f'), isFalse);
      });
    });

    group('partial and malformed UUIDs', () {
      test('rejects UUID missing last section', () {
        expect(isValidRouteId('550e8400-e29b-41d4-a716'), isFalse);
      });

      test('rejects UUID missing first section', () {
        expect(isValidRouteId('-e29b-41d4-a716-446655440000'), isFalse);
      });

      test('rejects UUID with short section', () {
        expect(isValidRouteId('550e840-e29b-41d4-a716-446655440000'), isFalse);
      });

      test('rejects UUID with long section', () {
        expect(
          isValidRouteId('550e84000-e29b-41d4-a716-446655440000'),
          isFalse,
        );
      });

      test('rejects UUID with only dashes', () {
        expect(isValidRouteId('--------'), isFalse);
      });

      test('rejects UUID with extra trailing section', () {
        expect(
          isValidRouteId('550e8400-e29b-41d4-a716-446655440000-extra'),
          isFalse,
        );
      });
    });

    group('wrong character sets', () {
      test('rejects UUID with non-hex letter g', () {
        expect(isValidRouteId('g50e8400-e29b-41d4-a716-446655440000'), isFalse);
      });

      test('rejects UUID with non-hex letter z', () {
        expect(isValidRouteId('550e8400-e29b-41d4-a716-44665544000z'), isFalse);
      });

      test('rejects UUID with special characters', () {
        expect(isValidRouteId('550e8400-e29b-41d4-a716-44665544000!'), isFalse);
      });

      test('rejects UUID with spaces', () {
        expect(isValidRouteId('550e8400 e29b 41d4 a716 446655440000'), isFalse);
      });
    });

    group('very long strings', () {
      test('rejects extremely long string', () {
        final longString = 'a' * 10000;
        expect(isValidRouteId(longString), isFalse);
      });

      test('rejects valid UUID padded with extra characters', () {
        expect(
          isValidRouteId('550e8400-e29b-41d4-a716-446655440000xxxx'),
          isFalse,
        );
      });

      test('rejects valid UUID with leading characters', () {
        expect(
          isValidRouteId('xxxx550e8400-e29b-41d4-a716-446655440000'),
          isFalse,
        );
      });
    });

    group('unicode and special characters', () {
      test('rejects emoji string', () {
        expect(isValidRouteId('\u{1F600}\u{1F600}\u{1F600}'), isFalse);
      });

      test('rejects CJK characters', () {
        expect(isValidRouteId('\u4F60\u597D\u4E16\u754C'), isFalse);
      });

      test('rejects Arabic characters', () {
        expect(isValidRouteId('\u0645\u0631\u062D\u0628\u0627'), isFalse);
      });

      test('rejects null byte injection', () {
        expect(isValidRouteId('550e8400\x00e29b-41d4-a716-446655440000'), isFalse);
      });

      test('rejects newline injection', () {
        expect(isValidRouteId('550e8400\ne29b-41d4-a716-446655440000'), isFalse);
      });

      test('rejects HTML/script tag', () {
        expect(isValidRouteId('<script>alert(1)</script>'), isFalse);
      });
    });
  });
}
