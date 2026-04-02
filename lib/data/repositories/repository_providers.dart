import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/api/remote_source_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/profile_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_metadata_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_reminder_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_schedule_repository.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_post_cache.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_post_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_comment_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_social_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/feedback_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';

/// Riverpod providers for all repositories.
///
/// Each repository receives its DAO, remote source, and sync DAO via
/// dependency injection from other providers.

final birdRepositoryProvider = Provider<BirdRepository>((ref) {
  return BirdRepository(
    localDao: ref.watch(birdsDaoProvider),
    remoteSource: ref.watch(birdRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final eggRepositoryProvider = Provider<EggRepository>((ref) {
  return EggRepository(
    localDao: ref.watch(eggsDaoProvider),
    remoteSource: ref.watch(eggRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
    incubationsDao: ref.watch(incubationsDaoProvider),
    clutchesDao: ref.watch(clutchesDaoProvider),
  );
});

final chickRepositoryProvider = Provider<ChickRepository>((ref) {
  return ChickRepository(
    localDao: ref.watch(chicksDaoProvider),
    remoteSource: ref.watch(chickRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
    eggsDao: ref.watch(eggsDaoProvider),
    clutchesDao: ref.watch(clutchesDaoProvider),
  );
});

final incubationRepositoryProvider = Provider<IncubationRepository>((ref) {
  return IncubationRepository(
    localDao: ref.watch(incubationsDaoProvider),
    remoteSource: ref.watch(incubationRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final breedingPairRepositoryProvider = Provider<BreedingPairRepository>((ref) {
  return BreedingPairRepository(
    localDao: ref.watch(breedingPairsDaoProvider),
    remoteSource: ref.watch(breedingPairRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final healthRecordRepositoryProvider = Provider<HealthRecordRepository>((ref) {
  return HealthRecordRepository(
    localDao: ref.watch(healthRecordsDaoProvider),
    remoteSource: ref.watch(healthRecordRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final growthMeasurementRepositoryProvider =
    Provider<GrowthMeasurementRepository>((ref) {
      return GrowthMeasurementRepository(
        localDao: ref.watch(growthMeasurementsDaoProvider),
        remoteSource: ref.watch(growthMeasurementRemoteSourceProvider),
        syncDao: ref.watch(syncMetadataDaoProvider),
      );
    });

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    localDao: ref.watch(eventsDaoProvider),
    remoteSource: ref.watch(eventRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    localDao: ref.watch(notificationsDaoProvider),
    remoteSource: ref.watch(notificationRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    localDao: ref.watch(profilesDaoProvider),
    remoteSource: ref.watch(profileRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final syncMetadataRepositoryProvider = Provider<SyncMetadataRepository>((ref) {
  return SyncMetadataRepository(localDao: ref.watch(syncMetadataDaoProvider));
});

final clutchRepositoryProvider = Provider<ClutchRepository>((ref) {
  return ClutchRepository(
    localDao: ref.watch(clutchesDaoProvider),
    remoteSource: ref.watch(clutchRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final nestRepositoryProvider = Provider<NestRepository>((ref) {
  return NestRepository(
    localDao: ref.watch(nestsDaoProvider),
    remoteSource: ref.watch(nestRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepository(
    localDao: ref.watch(photosDaoProvider),
    remoteSource: ref.watch(photoRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

final eventReminderRepositoryProvider = Provider<EventReminderRepository>((
  ref,
) {
  return EventReminderRepository(
    localDao: ref.watch(eventRemindersDaoProvider),
    remoteSource: ref.watch(eventReminderRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
    eventsDao: ref.watch(eventsDaoProvider),
  );
});

final notificationScheduleRepositoryProvider =
    Provider<NotificationScheduleRepository>((ref) {
      return NotificationScheduleRepository(
        localDao: ref.watch(notificationSchedulesDaoProvider),
        remoteSource: ref.watch(notificationScheduleRemoteSourceProvider),
        syncDao: ref.watch(syncMetadataDaoProvider),
      );
    });

final communityPostCacheProvider = Provider<CommunityPostCache>((ref) {
  return CommunityPostCache();
});

final communityPostRepositoryProvider = Provider<CommunityPostRepository>((
  ref,
) {
  return CommunityPostRepository(
    postSource: ref.watch(communityPostRemoteSourceProvider),
    socialSource: ref.watch(communitySocialRemoteSourceProvider),
    cache: ref.watch(communityPostCacheProvider),
  );
});

final communityCommentRepositoryProvider = Provider<CommunityCommentRepository>(
  (ref) {
    return CommunityCommentRepository(
      commentSource: ref.watch(communityCommentRemoteSourceProvider),
      socialSource: ref.watch(communitySocialRemoteSourceProvider),
    );
  },
);

final communitySocialRepositoryProvider = Provider<CommunitySocialRepository>((
  ref,
) {
  return CommunitySocialRepository(
    source: ref.watch(communitySocialRemoteSourceProvider),
  );
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(
    remoteSource: ref.watch(feedbackRemoteSourceProvider),
  );
});

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(
    listingSource: ref.watch(marketplaceListingRemoteSourceProvider),
    favoriteSource: ref.watch(marketplaceFavoriteRemoteSourceProvider),
  );
});
