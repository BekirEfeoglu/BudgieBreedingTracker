import 'package:easy_localization/easy_localization.dart';

/// Formats a chick's age using localized strings.
///
/// When [short] is true, uses compact l10n keys (`_short` suffix) suitable
/// for list cards. When false, uses full-length keys for detail screens.
String formatChickAge(
  ({int weeks, int days, int totalDays}) age, {
  bool short = false,
}) {
  if (age.weeks > 0) {
    final key =
        short ? 'chicks.age_weeks_days_short' : 'chicks.age_weeks_days';
    return key.tr(args: [age.weeks.toString(), age.days.toString()]);
  }
  final key = short ? 'chicks.age_days_only_short' : 'chicks.age_days_only';
  return key.tr(args: [age.totalDays.toString()]);
}
