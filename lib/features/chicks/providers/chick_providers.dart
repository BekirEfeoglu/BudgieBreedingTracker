import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';

part 'chick_filter_sort.dart';

typedef ChickParentsInfo = ({
  String? maleName,
  String? femaleName,
  String? maleId,
  String? femaleId,
});

/// All chicks for a user (live stream).
final chicksStreamProvider = StreamProvider.family<List<Chick>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(chickRepositoryProvider);
  return repo.watchAll(userId);
});

/// Single chick by ID (live stream).
final chickByIdProvider = StreamProvider.family<Chick?, String>((ref, id) {
  final repo = ref.watch(chickRepositoryProvider);
  return repo.watchById(id);
});

/// Parent bird info for a chick (looked up via egg → incubation → breeding pair).
/// Takes the chick's eggId and returns parent names.
final chickParentsProvider = FutureProvider.family<ChickParentsInfo?, String?>((
  ref,
  eggId,
) async {
  if (eggId == null) return null;

  try {
    final eggRepo = ref.read(eggRepositoryProvider);
    final egg = await eggRepo.getById(eggId);
    if (egg == null || egg.incubationId == null) return null;

    final incubationRepo = ref.read(incubationRepositoryProvider);
    final incubation = await incubationRepo.getById(egg.incubationId!);
    if (incubation == null || incubation.breedingPairId == null) return null;

    final pairRepo = ref.read(breedingPairRepositoryProvider);
    final pair = await pairRepo.getById(incubation.breedingPairId!);
    if (pair == null) return null;

    final birdRepo = ref.read(birdRepositoryProvider);
    String? maleName;
    String? femaleName;

    if (pair.maleId != null) {
      final male = await birdRepo.getById(pair.maleId!);
      maleName = male?.name ?? male?.ringNumber;
    }
    if (pair.femaleId != null) {
      final female = await birdRepo.getById(pair.femaleId!);
      femaleName = female?.name ?? female?.ringNumber;
    }

    return (
      maleName: maleName,
      femaleName: femaleName,
      maleId: pair.maleId,
      femaleId: pair.femaleId,
    );
  } catch (e) {
    AppLogger.error('Failed to load chick parents', e);
    return null;
  }
});

/// Batched parent lookup map keyed by eggId.
///
/// Avoids per-card chained lookups in list/grid screens.
final chickParentsByEggProvider =
    FutureProvider.family<Map<String, ChickParentsInfo>, String>((
      ref,
      userId,
    ) async {
      try {
        final eggRepo = ref.read(eggRepositoryProvider);
        final incubationRepo = ref.read(incubationRepositoryProvider);
        final pairRepo = ref.read(breedingPairRepositoryProvider);
        final birdRepo = ref.read(birdRepositoryProvider);

        final (eggs, incubations, pairs, birds) = await (
          eggRepo.getAll(userId),
          incubationRepo.getAll(userId),
          pairRepo.getAll(userId),
          birdRepo.getAll(userId),
        ).wait;

        final incubationById = {for (final inc in incubations) inc.id: inc};
        final pairById = {for (final pair in pairs) pair.id: pair};
        final birdById = {for (final bird in birds) bird.id: bird};

        final result = <String, ChickParentsInfo>{};
        for (final egg in eggs) {
          final incubationId = egg.incubationId;
          if (incubationId == null) continue;

          final pairId = incubationById[incubationId]?.breedingPairId;
          if (pairId == null) continue;

          final pair = pairById[pairId];
          if (pair == null) continue;

          final male = pair.maleId != null ? birdById[pair.maleId!] : null;
          final female = pair.femaleId != null
              ? birdById[pair.femaleId!]
              : null;

          result[egg.id] = (
            maleName: male?.name ?? male?.ringNumber,
            femaleName: female?.name ?? female?.ringNumber,
            maleId: pair.maleId,
            femaleId: pair.femaleId,
          );
        }
        return result;
      } catch (e, st) {
        AppLogger.error('Failed to batch load chick parents', e, st);
        return {};
      }
    });

/// Filtered chicks based on the current filter selection.
final filteredChicksProvider = Provider.family<List<Chick>, List<Chick>>((
  ref,
  chicks,
) {
  final filter = ref.watch(chickFilterProvider);
  return switch (filter) {
    ChickFilter.all => chicks,
    ChickFilter.healthy =>
      chicks.where((c) => c.healthStatus == ChickHealthStatus.healthy).toList(),
    ChickFilter.sick =>
      chicks.where((c) => c.healthStatus == ChickHealthStatus.sick).toList(),
    ChickFilter.deceased =>
      chicks
          .where((c) => c.healthStatus == ChickHealthStatus.deceased)
          .toList(),
    ChickFilter.unweaned =>
      chicks.where((c) => !c.isWeaned && c.birdId == null).toList(),
    ChickFilter.newborn =>
      chicks
          .where((c) => c.developmentStage == DevelopmentStage.newborn)
          .toList(),
    ChickFilter.nestling =>
      chicks
          .where((c) => c.developmentStage == DevelopmentStage.nestling)
          .toList(),
    ChickFilter.fledgling =>
      chicks
          .where((c) => c.developmentStage == DevelopmentStage.fledgling)
          .toList(),
    ChickFilter.juvenile =>
      chicks
          .where((c) => c.developmentStage == DevelopmentStage.juvenile)
          .toList(),
  };
});

/// Searched, filtered and sorted chicks.
final searchedAndFilteredChicksProvider =
    Provider.family<List<Chick>, List<Chick>>((ref, chicks) {
      final filtered = ref.watch(filteredChicksProvider(chicks));
      final query = ref.watch(chickSearchQueryProvider).toLowerCase().trim();
      final sort = ref.watch(chickSortProvider);

      List<Chick> result;
      if (query.isEmpty) {
        result = List.of(filtered);
      } else {
        result = filtered.where((chick) {
          final nameMatch = chick.name?.toLowerCase().contains(query) ?? false;
          final ringMatch =
              chick.ringNumber?.toLowerCase().contains(query) ?? false;
          return nameMatch || ringMatch;
        }).toList();
      }

      result.sort(
        (a, b) => switch (sort) {
          ChickSort.newest => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
          ChickSort.oldest => (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          ),
          ChickSort.nameAsc => (a.name ?? '').toLowerCase().compareTo(
            (b.name ?? '').toLowerCase(),
          ),
          ChickSort.nameDesc => (b.name ?? '').toLowerCase().compareTo(
            (a.name ?? '').toLowerCase(),
          ),
          ChickSort.ageYoungest => (b.hatchDate ?? DateTime(0)).compareTo(
            a.hatchDate ?? DateTime(0),
          ),
          ChickSort.ageOldest => (a.hatchDate ?? DateTime(0)).compareTo(
            b.hatchDate ?? DateTime(0),
          ),
        },
      );

      return result;
    });

/// Notifier for marking banding as complete.
class BandingActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Marks a chick as banded: updates chick, completes event, cancels notifications.
  Future<void> markBandingComplete(String chickId) async {
    state = const AsyncLoading();
    try {
      final chickRepo = ref.read(chickRepositoryProvider);
      final eventRepo = ref.read(eventRepositoryProvider);
      final scheduler = ref.read(notificationSchedulerProvider);

      // 1. Update chick with bandingDate
      final chick = await chickRepo.getById(chickId);
      if (chick == null) {
        state = AsyncError('Chick not found', StackTrace.current);
        return;
      }
      await chickRepo.save(
        chick.copyWith(bandingDate: DateTime.now(), updatedAt: DateTime.now()),
      );

      // 2. Complete banding event (filtered at DB level)
      final bandingEvents = await eventRepo.getActiveByChickAndType(
        chickId,
        EventType.banding,
      );
      for (final event in bandingEvents) {
        await eventRepo.save(
          event.copyWith(
            status: EventStatus.completed,
            updatedAt: DateTime.now(),
          ),
        );
      }

      // 3. Cancel remaining banding notifications
      await scheduler.cancelBandingReminders(chickId);

      state = const AsyncData(null);
    } catch (e, st) {
      AppLogger.error('BandingActionNotifier', e, st);
      state = AsyncError(e, st);
    }
  }
}

final bandingActionProvider =
    NotifierProvider<BandingActionNotifier, AsyncValue<void>>(
      BandingActionNotifier.new,
    );
