import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

// Re-export shared health record stream providers so existing imports work.
export 'package:budgie_breeding_tracker/data/providers/health_record_stream_providers.dart';

/// Filter enum for health record list.
enum HealthRecordFilter {
  all,
  checkup,
  illness,
  injury,
  vaccination,
  medication,
  death;

  String get label => switch (this) {
    HealthRecordFilter.all => 'common.all'.tr(),
    HealthRecordFilter.checkup => 'health_records.type_checkup'.tr(),
    HealthRecordFilter.illness => 'health_records.type_illness'.tr(),
    HealthRecordFilter.injury => 'health_records.type_injury'.tr(),
    HealthRecordFilter.vaccination => 'health_records.type_vaccination'.tr(),
    HealthRecordFilter.medication => 'health_records.type_medication'.tr(),
    HealthRecordFilter.death => 'health_records.type_death'.tr(),
  };

  /// Maps filter to HealthRecordType (null for 'all').
  HealthRecordType? get recordType => switch (this) {
    HealthRecordFilter.all => null,
    HealthRecordFilter.checkup => HealthRecordType.checkup,
    HealthRecordFilter.illness => HealthRecordType.illness,
    HealthRecordFilter.injury => HealthRecordType.injury,
    HealthRecordFilter.vaccination => HealthRecordType.vaccination,
    HealthRecordFilter.medication => HealthRecordType.medication,
    HealthRecordFilter.death => HealthRecordType.death,
  };
}

/// Filter state.
class HealthRecordFilterNotifier extends Notifier<HealthRecordFilter> {
  @override
  HealthRecordFilter build() => HealthRecordFilter.all;
}

final healthRecordFilterProvider =
    NotifierProvider<HealthRecordFilterNotifier, HealthRecordFilter>(
      HealthRecordFilterNotifier.new,
    );

/// Search query state.
class HealthRecordSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final healthRecordSearchQueryProvider =
    NotifierProvider<HealthRecordSearchQueryNotifier, String>(
      HealthRecordSearchQueryNotifier.new,
    );

/// Filtered health records.
final filteredHealthRecordsProvider =
    Provider.family<List<HealthRecord>, List<HealthRecord>>((ref, records) {
      final filter = ref.watch(healthRecordFilterProvider);
      if (filter == HealthRecordFilter.all) return records;
      return records.where((r) => r.type == filter.recordType).toList();
    });

/// Searched and filtered health records.
final searchedAndFilteredHealthRecordsProvider =
    Provider.family<List<HealthRecord>, List<HealthRecord>>((ref, records) {
      final filtered = ref.watch(filteredHealthRecordsProvider(records));
      final query = ref
          .watch(healthRecordSearchQueryProvider)
          .toLowerCase()
          .trim();
      if (query.isEmpty) return filtered;
      return filtered.where((r) {
        return r.title.toLowerCase().contains(query) ||
            (r.description?.toLowerCase().contains(query) ?? false) ||
            (r.veterinarian?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
