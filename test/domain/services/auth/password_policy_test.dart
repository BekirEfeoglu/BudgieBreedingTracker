import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/auth/password_policy.dart';

void main() {
  group('PasswordPolicy.validate', () {
    test('detects all rule failures for weak password', () {
      final result = PasswordPolicy.validate('abc');

      expect(result.hasMinLength, isFalse);
      expect(result.hasUppercase, isFalse);
      expect(result.hasLowercase, isTrue);
      expect(result.hasDigit, isFalse);
      expect(result.hasSpecialChar, isFalse);
      expect(result.isValid, isFalse);
      expect(result.passedCount, 1);
    });

    test('passes all rules for strong password', () {
      final result = PasswordPolicy.validate('Abcdef1!');

      expect(result.hasMinLength, isTrue);
      expect(result.isWithinMaxLength, isTrue);
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isTrue);
      expect(result.hasDigit, isTrue);
      expect(result.hasSpecialChar, isTrue);
      expect(result.isValid, isTrue);
      expect(result.passedCount, 5);
    });

    test('rejects password exceeding max length', () {
      final longPassword = 'Aa1!' + 'x' * 125; // 129 chars
      final result = PasswordPolicy.validate(longPassword);

      expect(result.hasMinLength, isTrue);
      expect(result.isWithinMaxLength, isFalse);
      expect(result.isValid, isFalse);
      // passedCount still counts the 5 character-type rules
      expect(result.passedCount, 5);
    });

    test('accepts password at exactly max length', () {
      final maxPassword = 'Aa1!' + 'x' * 124; // 128 chars
      final result = PasswordPolicy.validate(maxPassword);

      expect(result.hasMinLength, isTrue);
      expect(result.isWithinMaxLength, isTrue);
      expect(result.isValid, isTrue);
    });
  });

  group('PasswordPolicy.getStrength', () {
    test('maps low passing rule counts to weak/fair', () {
      expect(PasswordPolicy.getStrength('abc'), PasswordStrength.weak);
      expect(PasswordPolicy.getStrength('abcdefgh'), PasswordStrength.fair);
    });

    test('maps medium and high rule counts to good/strong', () {
      expect(PasswordPolicy.getStrength('Abcdefgh'), PasswordStrength.good);
      expect(PasswordPolicy.getStrength('Abcdef1!'), PasswordStrength.strong);
    });
  });

  group('PasswordStrength metadata', () {
    test('has expected progress values', () {
      expect(PasswordStrength.weak.progressValue, 0.25);
      expect(PasswordStrength.fair.progressValue, 0.50);
      expect(PasswordStrength.good.progressValue, 0.75);
      expect(PasswordStrength.strong.progressValue, 1.0);
    });

    test('has localization label keys', () {
      expect(PasswordStrength.weak.labelKey, 'auth.password_weak');
      expect(PasswordStrength.fair.labelKey, 'auth.password_fair');
      expect(PasswordStrength.good.labelKey, 'auth.password_good');
      expect(PasswordStrength.strong.labelKey, 'auth.password_strong');
    });
  });
}
