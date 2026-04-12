import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';

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

/// All health records for a user (live stream).
final healthRecordsStreamProvider =
    StreamProvider.family<List<HealthRecord>, String>((ref, userId) {
      final repo = ref.watch(healthRecordRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Single health record by id (live stream).
final healthRecordByIdProvider = StreamProvider.family<HealthRecord?, String>((
  ref,
  id,
) {
  final repo = ref.watch(healthRecordRepositoryProvider);
  return repo.watchById(id);
});

/// Count of non-deleted health records for a user (lightweight SQL COUNT).
final healthRecordCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(healthRecordsDaoProvider).watchCount(userId);
});

/// Health records for a specific bird (live stream).
final healthRecordsByBirdProvider =
    StreamProvider.family<List<HealthRecord>, String>((ref, birdId) {
      final repo = ref.watch(healthRecordRepositoryProvider);
      return repo.watchByBird(birdId);
    });

/// Animal info record for cache lookups.
typedef AnimalInfo = ({String name, String? ringNumber, bool isChick});

/// Pre-built cache mapping entity IDs to display info.
/// Watches reactive streams - auto-updates when birds/chicks change.
/// O(1) lookup, no additional repository queries.
final animalNameCacheProvider =
    Provider.family<Map<String, AnimalInfo>, String>((ref, userId) {
      final birds = ref.watch(birdsStreamProvider(userId)).value ?? [];
      final chicks = ref.watch(chicksStreamProvider(userId)).value ?? [];

      final cache = <String, AnimalInfo>{};

      for (final bird in birds) {
        cache[bird.id] = (
          name: bird.name,
          ringNumber: bird.ringNumber,
          isChick: false,
        );
      }

      for (final chick in chicks) {
        cache[chick.id] = (
          name: chick.name ?? chick.id.substring(0, 6),
          ringNumber: chick.ringNumber,
          isChick: true,
        );
      }

      return cache;
    });

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
