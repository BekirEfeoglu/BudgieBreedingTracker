import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

/// Filter for offspring display.
enum OffspringFilter {
  all,
  male,
  female,
  alive,
  dead;

  String get label => switch (this) {
        OffspringFilter.all => 'common.all'.tr(),
        OffspringFilter.male => 'birds.male'.tr(),
        OffspringFilter.female => 'birds.female'.tr(),
        OffspringFilter.alive => 'birds.alive'.tr(),
        OffspringFilter.dead => 'birds.dead'.tr(),
      };
}

/// Notifier for offspring filter selection.
class OffspringFilterNotifier extends Notifier<OffspringFilter> {
  @override
  OffspringFilter build() => OffspringFilter.all;
}

/// Current offspring filter selection.
final offspringFilterProvider =
    NotifierProvider<OffspringFilterNotifier, OffspringFilter>(OffspringFilterNotifier.new);

/// Filters offspring birds by the selected filter.
List<Bird> filterOffspringBirds(List<Bird> birds, OffspringFilter filter) {
  return switch (filter) {
    OffspringFilter.all => birds,
    OffspringFilter.male =>
      birds.where((b) => b.gender == BirdGender.male).toList(),
    OffspringFilter.female =>
      birds.where((b) => b.gender == BirdGender.female).toList(),
    OffspringFilter.alive =>
      birds.where((b) => b.status == BirdStatus.alive).toList(),
    OffspringFilter.dead =>
      birds.where((b) => b.status == BirdStatus.dead).toList(),
  };
}

/// Filters offspring chicks by the selected filter.
List<Chick> filterOffspringChicks(List<Chick> chicks, OffspringFilter filter) {
  return switch (filter) {
    OffspringFilter.all => chicks,
    OffspringFilter.male =>
      chicks.where((c) => c.gender == BirdGender.male).toList(),
    OffspringFilter.female =>
      chicks.where((c) => c.gender == BirdGender.female).toList(),
    OffspringFilter.alive => chicks, // chicks don't have BirdStatus
    OffspringFilter.dead => const [],
  };
}
