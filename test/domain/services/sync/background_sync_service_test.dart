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
      final telemetry = <({String name, Map<String, Object?> data})>[];

      final result = await BackgroundSyncService.runPushOnly(
        enabled: true,
        userId: 'user-1',
        pushChanges: (userId) async {
          pushedUsers.add(userId);
          return true;
        },
        telemetrySink: (name, data) {
          telemetry.add((name: name, data: data));
        },
      );

      expect(result, isTrue);
      expect(pushedUsers, ['user-1']);
      expect(telemetry.single.name, 'background_sync_run');
      expect(telemetry.single.data['success'], isTrue);
      expect(telemetry.single.data['durationMs'], isA<int>());
      expect(telemetry.single.data['taskBudgetSeconds'], 30);
    });

    test('returns false when push fails', () async {
      final telemetry = <({String name, Map<String, Object?> data})>[];

      final result = await BackgroundSyncService.runPushOnly(
        enabled: true,
        userId: 'user-1',
        pushChanges: (_) async => false,
        telemetrySink: (name, data) {
          telemetry.add((name: name, data: data));
        },
      );

      expect(result, isFalse);
      expect(telemetry.single.name, 'background_sync_run');
      expect(telemetry.single.data['success'], isFalse);
      expect(telemetry.single.data['taskBudgetSeconds'], 30);
    });

    test('emits skip telemetry when disabled', () async {
      final telemetry = <({String name, Map<String, Object?> data})>[];

      final result = await BackgroundSyncService.runPushOnly(
        enabled: false,
        userId: 'user-1',
        pushChanges: (_) async => true,
        telemetrySink: (name, data) {
          telemetry.add((name: name, data: data));
        },
      );

      expect(result, isTrue);
      expect(telemetry.single.name, 'background_sync_skipped');
      expect(telemetry.single.data['enabled'], isFalse);
      expect(telemetry.single.data['signedIn'], isTrue);
      expect(telemetry.single.data['taskBudgetSeconds'], 30);
    });
  });
}
