import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/data/remote/api/bird_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/egg_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/chick_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/incubation_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/breeding_pair_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/health_record_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/growth_measurement_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/profile_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/clutch_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/nest_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/photo_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_reminder_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_schedule_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_profile_cache.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_post_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_comment_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_social_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';
import 'marketplace_listing_remote_source.dart';
import 'marketplace_favorite_remote_source.dart';

/// Riverpod providers for all Supabase remote data sources.

final birdRemoteSourceProvider = Provider<BirdRemoteSource>((ref) {
  return BirdRemoteSource(ref.watch(supabaseClientProvider));
});

final eggRemoteSourceProvider = Provider<EggRemoteSource>((ref) {
  return EggRemoteSource(ref.watch(supabaseClientProvider));
});

final chickRemoteSourceProvider = Provider<ChickRemoteSource>((ref) {
  return ChickRemoteSource(ref.watch(supabaseClientProvider));
});

final incubationRemoteSourceProvider = Provider<IncubationRemoteSource>((ref) {
  return IncubationRemoteSource(ref.watch(supabaseClientProvider));
});

final breedingPairRemoteSourceProvider = Provider<BreedingPairRemoteSource>((
  ref,
) {
  return BreedingPairRemoteSource(ref.watch(supabaseClientProvider));
});

final healthRecordRemoteSourceProvider = Provider<HealthRecordRemoteSource>((
  ref,
) {
  return HealthRecordRemoteSource(ref.watch(supabaseClientProvider));
});

final growthMeasurementRemoteSourceProvider =
    Provider<GrowthMeasurementRemoteSource>((ref) {
      return GrowthMeasurementRemoteSource(ref.watch(supabaseClientProvider));
    });

final eventRemoteSourceProvider = Provider<EventRemoteSource>((ref) {
  return EventRemoteSource(ref.watch(supabaseClientProvider));
});

final notificationRemoteSourceProvider = Provider<NotificationRemoteSource>((
  ref,
) {
  return NotificationRemoteSource(ref.watch(supabaseClientProvider));
});

final profileRemoteSourceProvider = Provider<ProfileRemoteSource>((ref) {
  return ProfileRemoteSource(ref.watch(supabaseClientProvider));
});

final clutchRemoteSourceProvider = Provider<ClutchRemoteSource>((ref) {
  return ClutchRemoteSource(ref.watch(supabaseClientProvider));
});

final nestRemoteSourceProvider = Provider<NestRemoteSource>((ref) {
  return NestRemoteSource(ref.watch(supabaseClientProvider));
});

final photoRemoteSourceProvider = Provider<PhotoRemoteSource>((ref) {
  return PhotoRemoteSource(ref.watch(supabaseClientProvider));
});

final eventReminderRemoteSourceProvider = Provider<EventReminderRemoteSource>((
  ref,
) {
  return EventReminderRemoteSource(ref.watch(supabaseClientProvider));
});

final notificationScheduleRemoteSourceProvider =
    Provider<NotificationScheduleRemoteSource>((ref) {
      return NotificationScheduleRemoteSource(
        ref.watch(supabaseClientProvider),
      );
    });

final communityProfileCacheProvider = Provider<CommunityProfileCache>((ref) {
  return CommunityProfileCache(ref.watch(supabaseClientProvider));
});

final communityPostRemoteSourceProvider = Provider<CommunityPostRemoteSource>((
  ref,
) {
  return CommunityPostRemoteSource(
    ref.watch(supabaseClientProvider),
    ref.watch(communityProfileCacheProvider),
  );
});

final communityCommentRemoteSourceProvider =
    Provider<CommunityCommentRemoteSource>((ref) {
      return CommunityCommentRemoteSource(
        ref.watch(supabaseClientProvider),
        ref.watch(communityProfileCacheProvider),
      );
    });

final communitySocialRemoteSourceProvider =
    Provider<CommunitySocialRemoteSource>((ref) {
      return CommunitySocialRemoteSource(ref.watch(supabaseClientProvider));
    });

final feedbackRemoteSourceProvider = Provider<FeedbackRemoteSource>((ref) {
  return FeedbackRemoteSource(ref.watch(supabaseClientProvider));
});

final marketplaceListingRemoteSourceProvider =
    Provider<MarketplaceListingRemoteSource>((ref) {
  return MarketplaceListingRemoteSource(
    ref.watch(supabaseClientProvider),
  );
});

final marketplaceFavoriteRemoteSourceProvider =
    Provider<MarketplaceFavoriteRemoteSource>((ref) {
  return MarketplaceFavoriteRemoteSource(
    ref.watch(supabaseClientProvider),
  );
});
