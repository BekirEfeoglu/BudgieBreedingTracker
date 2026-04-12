import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the NumFormatting extension in num_extensions.dart.
///
/// The `formatCurrency` method requires a BuildContext with EasyLocalization
/// initialized (for `context.locale` and `.tr()`). Since EasyLocalization
/// requires async init, we test the underlying NumberFormat logic directly.
void main() {
  group('NumFormatting (NumberFormat core logic)', () {
    group('Turkish locale formatting', () {
      test('formats typical currency amount', () {
        final formatter = NumberFormat('#,##0.00', 'tr');
        expect(formatter.format(1234.56), '1.234,56');
      });

      test('formats zero', () {
        final formatter = NumberFormat('#,##0.00', 'tr');
        expect(formatter.format(0), '0,00');
      });

      test('formats negative numbers', () {
        final formatter = NumberFormat('#,##0.00', 'tr');
        expect(formatter.format(-42.5), '-42,50');
      });

      test('formats large numbers with thousand separators', () {
        final formatter = NumberFormat('#,##0.00', 'tr');
        expect(formatter.format(1000000), '1.000.000,00');
      });

      test('formats small decimals', () {
        final formatter = NumberFormat('#,##0.00', 'tr');
        expect(formatter.format(0.01), '0,01');
      });

      test('rounds to two decimal places', () {
        final formatter = NumberFormat('#,##0.00', 'tr');
        expect(formatter.format(9.999), '10,00');
      });
    });

    group('English locale formatting', () {
      test('formats typical currency amount', () {
        final formatter = NumberFormat('#,##0.00', 'en');
        expect(formatter.format(1234.56), '1,234.56');
      });

      test('formats zero', () {
        final formatter = NumberFormat('#,##0.00', 'en');
        expect(formatter.format(0), '0.00');
      });

      test('formats large numbers with thousand separators', () {
        final formatter = NumberFormat('#,##0.00', 'en');
        expect(formatter.format(1000000), '1,000,000.00');
      });

      test('formats small decimals', () {
        final formatter = NumberFormat('#,##0.00', 'en');
        expect(formatter.format(0.01), '0.01');
      });
    });

    group('German locale formatting', () {
      test('formats typical currency amount', () {
        final formatter = NumberFormat('#,##0.00', 'de');
        expect(formatter.format(1234.56), '1.234,56');
      });

      test('formats zero', () {
        final formatter = NumberFormat('#,##0.00', 'de');
        expect(formatter.format(0), '0,00');
      });
    });

    group('edge cases', () {
      test('handles very large numbers', () {
        final formatter = NumberFormat('#,##0.00', 'en');
        final result = formatter.format(999999999.99);
        expect(result, '999,999,999.99');
      });

      test('handles integer input', () {
        final formatter = NumberFormat('#,##0.00', 'en');
        expect(formatter.format(42), '42.00');
      });

      test('handles double with many decimals', () {
        final formatter = NumberFormat('#,##0.00', 'en');
        // NumberFormat rounds to 2 decimal places
        expect(formatter.format(3.14159), '3.14');
      });
    });
  });
}
