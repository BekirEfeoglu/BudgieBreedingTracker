import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

extension NumFormatting on num {
  /// Formats a numeric value as locale-aware currency.
  ///
  /// Uses the current locale from easy_localization to pick the correct
  /// thousand separator and decimal separator (e.g. "1.234,56" for Turkish,
  /// "1,234.56" for English). The currency symbol comes from the
  /// `settings.currency_symbol` localization key.
  String formatCurrency(BuildContext context) {
    final locale = context.locale.toString();
    final formatter = NumberFormat('#,##0.00', locale);
    final symbol = 'settings.currency_symbol'.tr();
    return '${formatter.format(this)} $symbol';
  }
}
