/// Strength level of a password.
enum PasswordStrength {
  weak,
  fair,
  good,
  strong;

  /// Localization key for UI display.
  String get labelKey => switch (this) {
    PasswordStrength.weak => 'auth.password_weak',
    PasswordStrength.fair => 'auth.password_fair',
    PasswordStrength.good => 'auth.password_good',
    PasswordStrength.strong => 'auth.password_strong',
  };

  /// Value from 0.0 to 1.0 for progress indicator.
  double get progressValue => switch (this) {
    PasswordStrength.weak => 0.25,
    PasswordStrength.fair => 0.50,
    PasswordStrength.good => 0.75,
    PasswordStrength.strong => 1.0,
  };
}

/// Result of a password validation check.
class PasswordValidationResult {
  final bool hasMinLength;
  final bool isWithinMaxLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordValidationResult({
    required this.hasMinLength,
    this.isWithinMaxLength = true,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  /// Whether all rules pass.
  bool get isValid =>
      hasMinLength &&
      isWithinMaxLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialChar;

  /// Number of passing rules (0-5, excludes maxLength which is a guard).
  int get passedCount => [
    hasMinLength,
    hasUppercase,
    hasLowercase,
    hasDigit,
    hasSpecialChar,
  ].where((v) => v).length;
}

/// Validates passwords and evaluates strength.
///
/// Rules: min 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char.
abstract class PasswordPolicy {
  static const int minLength = 8;

  /// Maximum password length to prevent bcrypt DoS (very long strings).
  static const int maxLength = 128;

  /// Validate a password against all rules.
  static PasswordValidationResult validate(String password) {
    return PasswordValidationResult(
      hasMinLength: password.length >= minLength,
      isWithinMaxLength: password.length <= maxLength,
      hasUppercase: password.contains(RegExp(r'[A-Z]')),
      hasLowercase: password.contains(RegExp(r'[a-z]')),
      hasDigit: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(
        RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?/~`]'),
      ),
    );
  }

  /// Get the overall strength of a password.
  static PasswordStrength getStrength(String password) {
    final result = validate(password);
    return switch (result.passedCount) {
      <= 1 => PasswordStrength.weak,
      2 => PasswordStrength.fair,
      3 || 4 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }
}
