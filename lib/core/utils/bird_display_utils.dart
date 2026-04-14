import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

/// Returns the localized display label for a [Species].
String speciesLabel(Species species) => switch (species) {
  Species.budgie => 'birds.budgie'.tr(),
  Species.canary => 'birds.canary'.tr(),
  Species.cockatiel => 'birds.cockatiel'.tr(),
  Species.finch => 'birds.finch'.tr(),
  Species.other => 'birds.other_species'.tr(),
  Species.unknown => 'common.unknown'.tr(),
};

/// Returns the localized long age format for bird detail screen.
/// Example: "2 yıl 3 ay", "5 ay 12 gün", "10 gün"
String formatBirdAge(({int years, int months, int days}) age) {
  if (age.years > 0) {
    return 'birds.age_years_months'.tr(
      namedArgs: {
        'years': age.years.toString(),
        'months': age.months.toString(),
      },
    );
  }
  if (age.months > 0) {
    return 'birds.age_months_days'.tr(
      namedArgs: {'months': age.months.toString(), 'days': age.days.toString()},
    );
  }
  return 'birds.age_days'.tr(namedArgs: {'days': age.days.toString()});
}

/// Returns the localized short age format for bird cards.
/// Example: "2y 3a", "5a 12g", "10g"
String formatBirdAgeShort(({int years, int months, int days}) age) {
  if (age.years > 0) {
    return 'birds.age_short_ym'.tr(
      namedArgs: {
        'years': age.years.toString(),
        'months': age.months.toString(),
      },
    );
  }
  if (age.months > 0) {
    return 'birds.age_short_md'.tr(
      namedArgs: {'months': age.months.toString(), 'days': age.days.toString()},
    );
  }
  return 'birds.age_short_d'.tr(namedArgs: {'days': age.days.toString()});
}
