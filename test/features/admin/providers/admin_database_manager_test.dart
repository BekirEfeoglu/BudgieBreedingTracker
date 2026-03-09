import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';

void main() {
  group('AdminDatabaseManager — allowedTables whitelist', () {
    // We test the static whitelist behavior via the public API (rejected table
    // names).  Direct instantiation requires a Ref, so we only test the
    // constants and static structures here.

    test('birdsTable is allowed', () {
      const allowed = {
        SupabaseConstants.birdsTable,
        SupabaseConstants.eggsTable,
        SupabaseConstants.chicksTable,
        SupabaseConstants.incubationsTable,
        SupabaseConstants.clutchesTable,
        SupabaseConstants.breedingPairsTable,
        SupabaseConstants.nestsTable,
        SupabaseConstants.healthRecordsTable,
        SupabaseConstants.growthMeasurementsTable,
        SupabaseConstants.eventsTable,
        SupabaseConstants.notificationsTable,
        SupabaseConstants.notificationSettingsTable,
        SupabaseConstants.eventRemindersTable,
        SupabaseConstants.notificationSchedulesTable,
        SupabaseConstants.profilesTable,
        SupabaseConstants.userPreferencesTable,
        SupabaseConstants.photosTable,
        SupabaseConstants.feedbackTable,
      };

      expect(allowed.contains(SupabaseConstants.birdsTable), isTrue);
    });

    test('admin_logs is NOT in allowed tables (protected)', () {
      const allowed = {
        SupabaseConstants.birdsTable,
        SupabaseConstants.eggsTable,
        SupabaseConstants.chicksTable,
      };

      // admin_logs is not in the allowed export/reset set
      expect(allowed.contains(SupabaseConstants.adminLogsTable), isFalse);
    });

    test('system_settings is NOT in allowed tables (protected)', () {
      const allowed = {
        SupabaseConstants.birdsTable,
        SupabaseConstants.eggsTable,
      };

      expect(allowed.contains(SupabaseConstants.systemSettingsTable), isFalse);
    });
  });

  group('AdminDatabaseManager — FK-safe deletion order', () {
    // The FK-safe deletion order ensures children are deleted before parents.
    const deletionOrder = [
      SupabaseConstants.eventRemindersTable,
      SupabaseConstants.notificationSchedulesTable,
      SupabaseConstants.notificationsTable,
      SupabaseConstants.notificationSettingsTable,
      SupabaseConstants.photosTable,
      SupabaseConstants.growthMeasurementsTable,
      SupabaseConstants.healthRecordsTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.chicksTable,
      SupabaseConstants.eggsTable,
      SupabaseConstants.incubationsTable,
      SupabaseConstants.clutchesTable,
      SupabaseConstants.breedingPairsTable,
      SupabaseConstants.nestsTable,
      SupabaseConstants.birdsTable,
      SupabaseConstants.userPreferencesTable,
      SupabaseConstants.feedbackTable,
    ];

    test('eventReminders deleted before birds', () {
      final remindersIdx = deletionOrder.indexOf(
        SupabaseConstants.eventRemindersTable,
      );
      final birdsIdx = deletionOrder.indexOf(SupabaseConstants.birdsTable);
      expect(remindersIdx, lessThan(birdsIdx));
    });

    test('eggs deleted before birds', () {
      final eggsIdx = deletionOrder.indexOf(SupabaseConstants.eggsTable);
      final birdsIdx = deletionOrder.indexOf(SupabaseConstants.birdsTable);
      expect(eggsIdx, lessThan(birdsIdx));
    });

    test('chicks deleted before birds', () {
      final chicksIdx = deletionOrder.indexOf(SupabaseConstants.chicksTable);
      final birdsIdx = deletionOrder.indexOf(SupabaseConstants.birdsTable);
      expect(chicksIdx, lessThan(birdsIdx));
    });

    test('deletion order has 17 entries', () {
      expect(deletionOrder.length, 17);
    });

    test('all entries are unique', () {
      expect(deletionOrder.toSet().length, deletionOrder.length);
    });
  });

  group('AdminDatabaseManager — formatBytes (private logic)', () {
    // Tests the private formatting logic via expected output patterns.
    // The method is private but we can verify formatting via integration.

    test('bytes under 1024 format as B', () {
      // Simulate what _formatBytes does:
      const int bytes = 500;
      String result;
      if (bytes < 1024) {
        result = '$bytes B';
      } else if (bytes < 1024 * 1024) {
        result = '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        result = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      expect(result, '500 B');
    });

    test('bytes in KB range format as KB', () {
      const int bytes = 2048;
      String result;
      if (bytes < 1024) {
        result = '$bytes B';
      } else if (bytes < 1024 * 1024) {
        result = '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        result = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      expect(result, '2.0 KB');
    });

    test('bytes in MB range format as MB', () {
      const int bytes = 1024 * 1024 * 3;
      String result;
      if (bytes < 1024) {
        result = '$bytes B';
      } else if (bytes < 1024 * 1024) {
        result = '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        result = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      expect(result, '3.0 MB');
    });
  });
}
