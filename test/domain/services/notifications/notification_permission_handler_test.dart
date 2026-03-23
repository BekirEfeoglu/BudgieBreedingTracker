import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_permission_handler.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIOSPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

/// Concrete class that mixes in [NotificationPermissionHandler] for testing.
class _TestPermissionHandler with NotificationPermissionHandler {
  _TestPermissionHandler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  FlutterLocalNotificationsPlugin get plugin => _plugin;
}

void main() {
  group('NotificationPermissionHandler.requestPermission', () {
    late _MockPlugin mockPlugin;
    late _TestPermissionHandler handler;

    setUp(() {
      mockPlugin = _MockPlugin();
      handler = _TestPermissionHandler(mockPlugin);
    });

    group('iOS platform', () {
      test('returns true when iOS permission is granted', () async {
        final mockIOS = _MockIOSPlugin();
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(mockIOS);
        when(
          () => mockIOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ),
        ).thenAnswer((_) async => true);

        final result = await handler.requestPermission();

        expect(result, isTrue);
        verify(
          () => mockIOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ),
        ).called(1);
      });

      test('returns false when iOS permission is denied', () async {
        final mockIOS = _MockIOSPlugin();
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(mockIOS);
        when(
          () => mockIOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ),
        ).thenAnswer((_) async => false);

        final result = await handler.requestPermission();

        expect(result, isFalse);
      });

      test('returns false when iOS permission returns null', () async {
        final mockIOS = _MockIOSPlugin();
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(mockIOS);
        when(
          () => mockIOS.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ),
        ).thenAnswer((_) async => null);

        final result = await handler.requestPermission();

        expect(result, isFalse);
      });
    });

    group('Android platform', () {
      test('falls through to requestAndroidPermission when no iOS impl',
          () async {
        final mockAndroid = _MockAndroidPlugin();
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(null);
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(mockAndroid);
        when(
          () => mockAndroid.requestNotificationsPermission(),
        ).thenAnswer((_) async => true);

        final result = await handler.requestPermission();

        expect(result, isTrue);
        verify(() => mockAndroid.requestNotificationsPermission()).called(1);
      });
    });
  });

  group('NotificationPermissionHandler.requestAndroidPermission', () {
    late _MockPlugin mockPlugin;
    late _TestPermissionHandler handler;

    setUp(() {
      mockPlugin = _MockPlugin();
      handler = _TestPermissionHandler(mockPlugin);
    });

    test('returns true when no Android implementation (non-Android platform)',
        () async {
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      final result = await handler.requestAndroidPermission();

      expect(result, isTrue);
    });

    test('returns true when Android permission is granted', () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);

      final result = await handler.requestAndroidPermission();

      expect(result, isTrue);
    });

    test('returns false when Android permission is denied', () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.requestNotificationsPermission(),
      ).thenAnswer((_) async => false);

      final result = await handler.requestAndroidPermission();

      expect(result, isFalse);
    });

    test('returns false when Android permission returns null', () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.requestNotificationsPermission(),
      ).thenAnswer((_) async => null);

      final result = await handler.requestAndroidPermission();

      expect(result, isFalse);
    });
  });

  group('NotificationPermissionHandler.checkExactAlarmPermission', () {
    late _MockPlugin mockPlugin;
    late _TestPermissionHandler handler;

    setUp(() {
      mockPlugin = _MockPlugin();
      handler = _TestPermissionHandler(mockPlugin);
    });

    test('returns true when no Android implementation (non-Android platform)',
        () async {
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      final result = await handler.checkExactAlarmPermission();

      expect(result, isTrue);
    });

    test('returns true when exact alarms are allowed', () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);

      final result = await handler.checkExactAlarmPermission();

      expect(result, isTrue);
    });

    test('returns false when exact alarms are not allowed', () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);

      final result = await handler.checkExactAlarmPermission();

      expect(result, isFalse);
    });

    test('returns true when canScheduleExactNotifications returns null',
        () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.canScheduleExactNotifications(),
      ).thenAnswer((_) async => null);

      final result = await handler.checkExactAlarmPermission();

      expect(result, isTrue);
    });
  });

  group('NotificationPermissionHandler.resolveExactAlarmPermission', () {
    late _MockPlugin mockPlugin;
    late _TestPermissionHandler handler;

    setUp(() {
      mockPlugin = _MockPlugin();
      handler = _TestPermissionHandler(mockPlugin);
    });

    test('returns cached result on subsequent calls without forceRefresh',
        () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);

      // First call populates cache
      final result1 = await handler.resolveExactAlarmPermission();
      expect(result1, isTrue);

      // Second call should use cache — not call the plugin again
      final result2 = await handler.resolveExactAlarmPermission();
      expect(result2, isTrue);

      verify(() => mockAndroid.canScheduleExactNotifications()).called(1);
    });

    test('refreshes cache when forceRefresh is true', () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);

      // First call: allowed
      when(
        () => mockAndroid.canScheduleExactNotifications(),
      ).thenAnswer((_) async => true);
      final result1 = await handler.resolveExactAlarmPermission();
      expect(result1, isTrue);

      // Second call with forceRefresh: denied
      when(
        () => mockAndroid.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);
      final result2 = await handler.resolveExactAlarmPermission(
        forceRefresh: true,
      );
      expect(result2, isFalse);

      verify(() => mockAndroid.canScheduleExactNotifications()).called(2);
    });

    test('returns true for non-Android platform and caches result', () async {
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);

      final result1 = await handler.resolveExactAlarmPermission();
      expect(result1, isTrue);

      // Subsequent call should use cache
      final result2 = await handler.resolveExactAlarmPermission();
      expect(result2, isTrue);
    });

    test('caches false when exact alarms are denied', () async {
      final mockAndroid = _MockAndroidPlugin();
      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(mockAndroid);
      when(
        () => mockAndroid.canScheduleExactNotifications(),
      ).thenAnswer((_) async => false);

      final result1 = await handler.resolveExactAlarmPermission();
      expect(result1, isFalse);

      // Cached — no extra plugin call
      final result2 = await handler.resolveExactAlarmPermission();
      expect(result2, isFalse);

      verify(() => mockAndroid.canScheduleExactNotifications()).called(1);
    });
  });
}
