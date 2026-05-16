import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/background_sync_service.dart';

void main() {
  group('BackgroundSyncService.runPushOnly', () {
    test('does not push when disabled', () async {
      var calls = 0;

      final result = await BackgroundSyncService.runPushOnly(
        enabled: false,
        userId: 'user-1',
        pushChanges: (_) async {
          calls++;
          return true;
        },
      );

      expect(result, isTrue);
      expect(calls, 0);
    });

    test('does not push without authenticated user', () async {
      var calls = 0;

      final result = await BackgroundSyncService.runPushOnly(
        enabled: true,
        userId: 'anonymous',
        pushChanges: (_) async {
          calls++;
          return true;
        },
      );

      expect(result, isTrue);
      expect(calls, 0);
    });

    test('pushes pending changes when enabled and signed in', () async {
      final pushedUsers = <String>[];

      final result = await BackgroundSyncService.runPushOnly(
        enabled: true,
        userId: 'user-1',
        pushChanges: (userId) async {
          pushedUsers.add(userId);
          return true;
        },
      );

      expect(result, isTrue);
      expect(pushedUsers, ['user-1']);
    });

    test('returns false when push fails', () async {
      final result = await BackgroundSyncService.runPushOnly(
        enabled: true,
        userId: 'user-1',
        pushChanges: (_) async => false,
      );

      expect(result, isFalse);
    });
  });
}
