import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/auth/recovery_code_service.dart';

void main() {
  group('RecoveryCodeService.normalize', () {
    test('strips separators and uppercases (mirrors the SQL normalize)', () {
      expect(RecoveryCodeService.normalize('abcde-fghij'), 'ABCDEFGHIJ');
      expect(RecoveryCodeService.normalize('  ab cd '), 'ABCD');
      expect(RecoveryCodeService.normalize('AB-CD_EF.GH'), 'ABCDEFGH');
    });

    test('is idempotent on already-normalized input', () {
      const normalized = 'ABCDEFGHIJ';
      expect(RecoveryCodeService.normalize(normalized), normalized);
    });

    test('returns empty for punctuation-only input', () {
      expect(RecoveryCodeService.normalize('---'), '');
    });
  });

  group('RecoveryCodeService constants', () {
    test('issues 10 codes per generation', () {
      expect(RecoveryCodeService.codeCount, 10);
    });
  });
}
