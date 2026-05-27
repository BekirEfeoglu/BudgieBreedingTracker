import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/health_record_stream_providers.dart';

/// Timeline categories displayed on a bird profile.
enum BirdTimelineEventType {
  birth,
  registered,
  status,
  breeding,
  egg,
  chick,
  health,
}

/// Read-only view model for one event in a bird's life timeline.
class BirdTimelineEvent {
  final BirdTimelineEventType type;
  final DateTime date;
  final String titleKey;
  final String? title;
  final Map<String, String> namedArgs;
  final String iconAsset;

  const BirdTimelineEvent({
    required this.type,
    required this.date,
    required this.titleKey,
    required this.iconAsset,
    this.title,
    this.namedArgs = const {},
  });
}

/// Timeline events for a bird, built from existing offline-first streams.
///
/// autoDispose: family keyed on a Freezed `Bird` value object. Even though
/// Freezed implements value-equality, every edit produces a non-equal
/// instance — so each edit installs a new family entry while the old one
/// keeps 5 stream subscriptions alive. autoDispose drops the stale entry
/// once the previous Bird value is no longer watched.
final birdTimelineProvider = Provider.autoDispose.family<List<BirdTimelineEvent>, Bird>((
  ref,
  bird,
) {
  final breedingPairs =
      ref.watch(breedingPairsStreamProvider(bird.userId)).value ??
      <BreedingPair>[];
  final incubations =
      ref.watch(allIncubationsStreamProvider(bird.userId)).value ??
      <Incubation>[];
  final eggs = ref.watch(eggsStreamProvider(bird.userId)).value ?? <Egg>[];
  final chicks =
      ref.watch(chicksStreamProvider(bird.userId)).value ?? <Chick>[];
  final healthRecords =
      ref.watch(healthRecordsByBirdProvider(bird.id)).value ?? <HealthRecord>[];

  return buildBirdTimelineEvents(
    bird: bird,
    breedingPairs: breedingPairs,
    incubations: incubations,
    eggs: eggs,
    chicks: chicks,
    healthRecords: healthRecords,
  );
});

/// Pure builder kept testable without Riverpod.
List<BirdTimelineEvent> buildBirdTimelineEvents({
  required Bird bird,
  List<BreedingPair> breedingPairs = const [],
  List<Incubation> incubations = const [],
  List<Egg> eggs = const [],
  List<Chick> chicks = const [],
  List<HealthRecord> healthRecords = const [],
}) {
  final events = <BirdTimelineEvent>[];

  if (bird.birthDate case final birthDate?) {
    events.add(
      BirdTimelineEvent(
        type: BirdTimelineEventType.birth,
        date: birthDate,
        titleKey: 'birds.timeline_birth',
        iconAsset: AppIcons.chick,
      ),
    );
  }

  if (bird.createdAt case final createdAt?) {
    events.add(
      BirdTimelineEvent(
        type: BirdTimelineEventType.registered,
        date: createdAt,
        titleKey: 'birds.timeline_registered',
        iconAsset: AppIcons.bird,
      ),
    );
  }

  final statusDate = switch (bird.status) {
    BirdStatus.dead => bird.deathDate,
    BirdStatus.sold || BirdStatus.gifted => bird.soldDate,
    BirdStatus.alive || BirdStatus.unknown => null,
  };
  final statusTitleKey = switch (bird.status) {
    BirdStatus.dead => 'birds.timeline_deceased',
    BirdStatus.sold => 'birds.timeline_sold',
    BirdStatus.gifted => 'birds.timeline_gifted',
    BirdStatus.alive || BirdStatus.unknown => null,
  };
  if (statusDate != null && statusTitleKey != null) {
    events.add(
      BirdTimelineEvent(
        type: BirdTimelineEventType.status,
        date: statusDate,
        titleKey: statusTitleKey,
        iconAsset: bird.status == BirdStatus.dead
            ? AppIcons.statusDead
            : AppIcons.statusSold,
      ),
    );
  }

  final relevantPairs = breedingPairs
      .where((pair) => pair.maleId == bird.id || pair.femaleId == bird.id)
      .toList();
  final relevantPairIds = relevantPairs.map((pair) => pair.id).toSet();

  for (final pair in relevantPairs) {
    final date = pair.pairingDate ?? pair.createdAt;
    if (date == null) continue;
    events.add(
      BirdTimelineEvent(
        type: BirdTimelineEventType.breeding,
        date: date,
        titleKey: 'birds.timeline_breeding_started',
        iconAsset: AppIcons.pair,
      ),
    );
  }

  final relevantIncubationIds = incubations
      .where(
        (incubation) =>
            incubation.breedingPairId != null &&
            relevantPairIds.contains(incubation.breedingPairId),
      )
      .map((incubation) => incubation.id)
      .toSet();

  for (final incubationId in relevantIncubationIds) {
    final incubationEggs = eggs
        .where((egg) => egg.incubationId == incubationId)
        .toList();
    if (incubationEggs.isEmpty) continue;
    incubationEggs.sort((a, b) => a.layDate.compareTo(b.layDate));
    events.add(
      BirdTimelineEvent(
        type: BirdTimelineEventType.egg,
        date: incubationEggs.first.layDate,
        titleKey: 'birds.timeline_eggs_laid',
        namedArgs: {'count': '${incubationEggs.length}'},
        iconAsset: AppIcons.egg,
      ),
    );
  }

  for (final chick in chicks.where((chick) => chick.birdId == bird.id)) {
    final date = chick.hatchDate ?? chick.createdAt;
    if (date == null) continue;
    events.add(
      BirdTimelineEvent(
        type: BirdTimelineEventType.chick,
        date: date,
        titleKey: 'birds.timeline_chick_origin',
        iconAsset: AppIcons.chick,
      ),
    );
  }

  for (final record in healthRecords.where(
    (record) => record.birdId == bird.id,
  )) {
    events.add(
      BirdTimelineEvent(
        type: BirdTimelineEventType.health,
        date: record.date,
        titleKey: 'birds.timeline_health_record',
        title: record.title,
        iconAsset: AppIcons.health,
      ),
    );
  }

  events.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.type.index.compareTo(b.type.index);
  });
  return events;
}
