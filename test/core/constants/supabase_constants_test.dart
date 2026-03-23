import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';

void main() {
  group('SupabaseConstants', () {
    group('table constants', () {
      test('all core table constants are non-empty strings', () {
        final tables = [
          SupabaseConstants.birdsTable,
          SupabaseConstants.eggsTable,
          SupabaseConstants.chicksTable,
          SupabaseConstants.incubationsTable,
          SupabaseConstants.clutchesTable,
          SupabaseConstants.breedingPairsTable,
          SupabaseConstants.nestsTable,
          SupabaseConstants.eventsTable,
          SupabaseConstants.healthRecordsTable,
          SupabaseConstants.growthMeasurementsTable,
          SupabaseConstants.notificationsTable,
          SupabaseConstants.notificationSettingsTable,
          SupabaseConstants.profilesTable,
          SupabaseConstants.userPreferencesTable,
          SupabaseConstants.subscriptionPlansTable,
          SupabaseConstants.userSubscriptionsTable,
          SupabaseConstants.photosTable,
          SupabaseConstants.backupJobsTable,
          SupabaseConstants.adminLogsTable,
          SupabaseConstants.adminUsersTable,
          SupabaseConstants.securityEventsTable,
          SupabaseConstants.systemSettingsTable,
          SupabaseConstants.systemMetricsTable,
          SupabaseConstants.systemStatusTable,
          SupabaseConstants.systemAlertsTable,
          SupabaseConstants.userSessionsTable,
          SupabaseConstants.eventRemindersTable,
          SupabaseConstants.notificationSchedulesTable,
          SupabaseConstants.syncMetadataTable,
          SupabaseConstants.geneticsHistoryTable,
          SupabaseConstants.feedbackTable,
          SupabaseConstants.calendarTable,
        ];

        for (final table in tables) {
          expect(table, isNotEmpty, reason: 'Table constant must not be empty');
        }
      });

      test('all table names use snake_case format', () {
        final tables = [
          SupabaseConstants.birdsTable,
          SupabaseConstants.breedingPairsTable,
          SupabaseConstants.healthRecordsTable,
          SupabaseConstants.growthMeasurementsTable,
          SupabaseConstants.notificationSettingsTable,
          SupabaseConstants.userPreferencesTable,
          SupabaseConstants.subscriptionPlansTable,
          SupabaseConstants.userSubscriptionsTable,
          SupabaseConstants.backupJobsTable,
          SupabaseConstants.adminLogsTable,
          SupabaseConstants.eventRemindersTable,
          SupabaseConstants.notificationSchedulesTable,
          SupabaseConstants.syncMetadataTable,
          SupabaseConstants.geneticsHistoryTable,
        ];

        final snakeCasePattern = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
        for (final table in tables) {
          expect(
            snakeCasePattern.hasMatch(table),
            isTrue,
            reason: '"$table" should be snake_case',
          );
        }
      });

      test('table names are unique', () {
        final tables = [
          SupabaseConstants.birdsTable,
          SupabaseConstants.eggsTable,
          SupabaseConstants.chicksTable,
          SupabaseConstants.incubationsTable,
          SupabaseConstants.clutchesTable,
          SupabaseConstants.breedingPairsTable,
          SupabaseConstants.nestsTable,
          SupabaseConstants.eventsTable,
          SupabaseConstants.healthRecordsTable,
          SupabaseConstants.growthMeasurementsTable,
          SupabaseConstants.notificationsTable,
          SupabaseConstants.notificationSettingsTable,
          SupabaseConstants.profilesTable,
          SupabaseConstants.userPreferencesTable,
          SupabaseConstants.subscriptionPlansTable,
          SupabaseConstants.userSubscriptionsTable,
          SupabaseConstants.photosTable,
          SupabaseConstants.backupJobsTable,
          SupabaseConstants.adminLogsTable,
          SupabaseConstants.adminUsersTable,
          SupabaseConstants.securityEventsTable,
          SupabaseConstants.systemSettingsTable,
          SupabaseConstants.systemMetricsTable,
          SupabaseConstants.systemStatusTable,
          SupabaseConstants.systemAlertsTable,
          SupabaseConstants.userSessionsTable,
          SupabaseConstants.eventRemindersTable,
          SupabaseConstants.notificationSchedulesTable,
          SupabaseConstants.syncMetadataTable,
          SupabaseConstants.geneticsHistoryTable,
          SupabaseConstants.feedbackTable,
          SupabaseConstants.calendarTable,
          SupabaseConstants.deletedEggsTable,
          SupabaseConstants.eggArchivesTable,
          SupabaseConstants.eventTypesTable,
          SupabaseConstants.eventTemplatesTable,
          SupabaseConstants.adminSessionsTable,
          SupabaseConstants.adminRateLimitsTable,
          SupabaseConstants.backupSettingsTable,
        ];

        expect(tables.toSet().length, tables.length,
            reason: 'All table names must be unique');
      });
    });

    group('community table constants', () {
      test('all community tables are non-empty snake_case strings', () {
        final communityTables = [
          SupabaseConstants.communityPostsTable,
          SupabaseConstants.communityCommentsTable,
          SupabaseConstants.communityLikesTable,
          SupabaseConstants.communityBookmarksTable,
          SupabaseConstants.communityCommentLikesTable,
          SupabaseConstants.communityFollowsTable,
          SupabaseConstants.communityReportsTable,
          SupabaseConstants.communityBlocksTable,
          SupabaseConstants.communityEventsTable,
          SupabaseConstants.communityEventAttendeesTable,
          SupabaseConstants.communityPollsTable,
          SupabaseConstants.communityPollOptionsTable,
          SupabaseConstants.communityPollVotesTable,
          SupabaseConstants.communityStoriesTable,
          SupabaseConstants.communityStoryViewsTable,
        ];

        final snakeCasePattern = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
        for (final table in communityTables) {
          expect(table, isNotEmpty);
          expect(
            snakeCasePattern.hasMatch(table),
            isTrue,
            reason: '"$table" should be snake_case',
          );
        }
      });

      test('all community tables have community_ prefix', () {
        final communityTables = [
          SupabaseConstants.communityPostsTable,
          SupabaseConstants.communityCommentsTable,
          SupabaseConstants.communityLikesTable,
          SupabaseConstants.communityBookmarksTable,
          SupabaseConstants.communityCommentLikesTable,
          SupabaseConstants.communityFollowsTable,
          SupabaseConstants.communityReportsTable,
          SupabaseConstants.communityBlocksTable,
          SupabaseConstants.communityEventsTable,
          SupabaseConstants.communityEventAttendeesTable,
          SupabaseConstants.communityPollsTable,
          SupabaseConstants.communityPollOptionsTable,
          SupabaseConstants.communityPollVotesTable,
          SupabaseConstants.communityStoriesTable,
          SupabaseConstants.communityStoryViewsTable,
        ];

        for (final table in communityTables) {
          expect(table.startsWith('community_'), isTrue,
              reason: '"$table" should start with community_');
        }
      });
    });

    group('storage bucket constants', () {
      test('all bucket constants are non-empty strings', () {
        final buckets = [
          SupabaseConstants.birdPhotosBucket,
          SupabaseConstants.eggPhotosBucket,
          SupabaseConstants.chickPhotosBucket,
          SupabaseConstants.avatarsBucket,
          SupabaseConstants.backupsBucket,
          SupabaseConstants.communityPhotosBucket,
        ];

        for (final bucket in buckets) {
          expect(bucket, isNotEmpty,
              reason: 'Bucket constant must not be empty');
        }
      });

      test('bucket names use kebab-case format', () {
        final buckets = [
          SupabaseConstants.birdPhotosBucket,
          SupabaseConstants.eggPhotosBucket,
          SupabaseConstants.chickPhotosBucket,
          SupabaseConstants.avatarsBucket,
          SupabaseConstants.backupsBucket,
          SupabaseConstants.communityPhotosBucket,
        ];

        final kebabCasePattern = RegExp(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$');
        for (final bucket in buckets) {
          expect(
            kebabCasePattern.hasMatch(bucket),
            isTrue,
            reason: '"$bucket" should be kebab-case',
          );
        }
      });

      test('bucket names are unique', () {
        final buckets = [
          SupabaseConstants.birdPhotosBucket,
          SupabaseConstants.eggPhotosBucket,
          SupabaseConstants.chickPhotosBucket,
          SupabaseConstants.avatarsBucket,
          SupabaseConstants.backupsBucket,
          SupabaseConstants.communityPhotosBucket,
        ];

        expect(buckets.toSet().length, buckets.length,
            reason: 'All bucket names must be unique');
      });

      test('expected bucket values', () {
        expect(SupabaseConstants.birdPhotosBucket, 'bird-photos');
        expect(SupabaseConstants.eggPhotosBucket, 'egg-photos');
        expect(SupabaseConstants.chickPhotosBucket, 'chick-photos');
        expect(SupabaseConstants.avatarsBucket, 'avatars');
        expect(SupabaseConstants.backupsBucket, 'backups');
        expect(SupabaseConstants.communityPhotosBucket, 'community-photos');
      });
    });

    group('specific table values', () {
      test('core entity tables have expected names', () {
        expect(SupabaseConstants.birdsTable, 'birds');
        expect(SupabaseConstants.eggsTable, 'eggs');
        expect(SupabaseConstants.chicksTable, 'chicks');
        expect(SupabaseConstants.clutchesTable, 'clutches');
        expect(SupabaseConstants.nestsTable, 'nests');
        expect(SupabaseConstants.breedingPairsTable, 'breeding_pairs');
        expect(SupabaseConstants.incubationsTable, 'incubations');
        expect(SupabaseConstants.eventsTable, 'events');
        expect(SupabaseConstants.healthRecordsTable, 'health_records');
        expect(SupabaseConstants.profilesTable, 'profiles');
        expect(SupabaseConstants.photosTable, 'photos');
        expect(SupabaseConstants.feedbackTable, 'feedback');
        expect(SupabaseConstants.calendarTable, 'calendar');
      });

      test('community social tables have expected names', () {
        expect(SupabaseConstants.communityPostsTable, 'community_posts');
        expect(SupabaseConstants.communityCommentsTable, 'community_comments');
        expect(SupabaseConstants.communityLikesTable, 'community_likes');
        expect(SupabaseConstants.communityBookmarksTable,
            'community_bookmarks');
        expect(SupabaseConstants.communityCommentLikesTable,
            'community_comment_likes');
        expect(SupabaseConstants.communityFollowsTable, 'community_follows');
        expect(SupabaseConstants.communityReportsTable, 'community_reports');
        expect(SupabaseConstants.communityBlocksTable, 'community_blocks');
      });
    });

    group('archive table constants', () {
      test('all archive tables are non-empty', () {
        final archiveTables = [
          SupabaseConstants.archivedBirdsTable,
          SupabaseConstants.archivedBreedingPairsTable,
          SupabaseConstants.archivedClutchesTable,
          SupabaseConstants.archivedEggsTable,
          SupabaseConstants.archivedChicksTable,
          SupabaseConstants.archiveJobsTable,
          SupabaseConstants.archiveSettingsTable,
        ];

        for (final table in archiveTables) {
          expect(table, isNotEmpty);
        }
      });
    });

    group('push notification table constants', () {
      test('all push notification tables are non-empty', () {
        final pushTables = [
          SupabaseConstants.fcmTokensTable,
          SupabaseConstants.webPushSubscriptionsTable,
          SupabaseConstants.notificationHistoryTable,
          SupabaseConstants.notificationRateLimitsTable,
        ];

        for (final table in pushTables) {
          expect(table, isNotEmpty);
        }
      });
    });
  });
}
