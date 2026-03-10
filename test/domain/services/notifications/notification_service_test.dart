import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

const _timezoneChannel = MethodChannel('flutter_timezone');

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _FakeNotificationDetails extends Fake implements NotificationDetails {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(_FakeNotificationDetails());
    registerFallbackValue(tz.TZDateTime.utc(2026));
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
  });

  group('NotificationService.payloadToRoute', () {
    test('maps known payload types to expected routes', () {
      expect(
        NotificationService.payloadToRoute('breeding:abc'),
        '/breeding/abc',
      );
      expect(
        NotificationService.payloadToRoute('incubation:abc'),
        '/breeding/abc',
      );
      expect(NotificationService.payloadToRoute('bird:abc'), '/birds/abc');
      expect(NotificationService.payloadToRoute('chick:abc'), '/chicks/abc');
      expect(
        NotificationService.payloadToRoute('chick_care:abc'),
        '/chicks/abc',
      );
      expect(NotificationService.payloadToRoute('egg:abc'), '/breeding');
      expect(
        NotificationService.payloadToRoute('egg_turning:abc'),
        '/breeding',
      );
      expect(
        NotificationService.payloadToRoute('health_check:abc'),
        '/health-records/abc',
      );
      expect(NotificationService.payloadToRoute('event:any'), '/calendar');
      expect(
        NotificationService.payloadToRoute('event_reminder:any'),
        '/calendar',
      );
      expect(NotificationService.payloadToRoute('calendar:any'), '/calendar');
      expect(
        NotificationService.payloadToRoute('notification:any'),
        '/notifications',
      );
    });

    test('returns null for null, malformed or unknown payloads', () {
      expect(NotificationService.payloadToRoute(null), isNull);
      expect(NotificationService.payloadToRoute('invalid'), isNull);
      expect(NotificationService.payloadToRoute('a:b:c'), isNull);
      expect(NotificationService.payloadToRoute('unknown:id'), isNull);
    });
  });

  group('NotificationService.cancelByIdRange', () {
    test('cancels only notifications within the specified range', () async {
      const eggTurningBase = 100000;
      const incubationBase = 200000;

      expect(
        150000 >= eggTurningBase && 150000 < eggTurningBase + 100000,
        isTrue,
      );
      expect(
        250000 >= eggTurningBase && 250000 < eggTurningBase + 100000,
        isFalse,
      );
      expect(
        100000 >= eggTurningBase && 100000 < eggTurningBase + 100000,
        isTrue,
      );
      expect(
        200000 >= eggTurningBase && 200000 < eggTurningBase + 100000,
        isFalse,
      );
      expect(
        200000 >= incubationBase && 200000 < incubationBase + 100000,
        isTrue,
      );
    });
  });

  group('NotificationService lifecycle', () {
    test('isInitialized is false before init', () {
      final service = NotificationService();
      expect(service.isInitialized, isFalse);
    });

    test('showNotification throws StateError before init', () {
      final service = NotificationService();
      expect(
        () => service.showNotification(id: 1, title: 'Test', body: 'Body'),
        throwsStateError,
      );
    });

    test('scheduleNotification throws StateError before init', () {
      final service = NotificationService();
      expect(
        () => service.scheduleNotification(
          id: 1,
          title: 'Test',
          body: 'Body',
          scheduledDate: DateTime.now().add(const Duration(hours: 1)),
        ),
        throwsStateError,
      );
    });

    test('updateSoundAndVibration updates preferences', () {
      final service = NotificationService();

      service.updateSoundAndVibration(
        soundEnabled: false,
        vibrationEnabled: false,
      );
      service.updateSoundAndVibration(
        soundEnabled: true,
        vibrationEnabled: true,
      );
    });
  });

  group('NotificationService channel constants', () {
    test('channel IDs have expected values', () {
      expect(NotificationService.eggTurningChannelId, 'egg_turning');
      expect(NotificationService.incubationChannelId, 'incubation');
      expect(NotificationService.chickCareChannelId, 'chick_care');
      expect(NotificationService.healthCheckChannelId, 'health_check');
    });
  });

  group('NotificationService.init (DI)', () {
    late _MockPlugin mockPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = _MockPlugin();
      service = NotificationService(plugin: mockPlugin);

      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, null);
    });

    test('initializes with valid timezone', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') return 'Europe/Istanbul';
            return null;
          });

      await service.init();

      expect(service.isInitialized, isTrue);
      verify(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).called(1);
    });

    test('initializes with UTC fallback when timezone fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') {
              throw PlatformException(code: 'ERROR', message: 'Not available');
            }
            return null;
          });

      await service.init();

      expect(service.isInitialized, isTrue);
      expect(tz.local.name, 'UTC');
    });

    test('init is idempotent — second call is no-op', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') return 'UTC';
            return null;
          });

      await service.init();
      await service.init();

      verify(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).called(1);
    });
  });

  group('NotificationService show/schedule/cancel (DI)', () {
    late _MockPlugin mockPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = _MockPlugin();
      service = NotificationService(plugin: mockPlugin);

      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async => true);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') return 'UTC';
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, null);
    });

    test('showNotification calls plugin.show with correct params', () async {
      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.init();
      await service.showNotification(
        id: 42,
        title: 'Test Title',
        body: 'Test Body',
        payload: 'bird:abc',
      );

      verify(
        () => mockPlugin.show(
          id: 42,
          title: 'Test Title',
          body: 'Test Body',
          notificationDetails: any(named: 'notificationDetails'),
          payload: 'bird:abc',
        ),
      ).called(1);
    });

    test('scheduleNotification calls plugin.zonedSchedule', () async {
      when(
        () => mockPlugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.init();
      final future = DateTime.now().add(const Duration(hours: 2));
      await service.scheduleNotification(
        id: 99,
        title: 'Scheduled',
        body: 'Later',
        scheduledDate: future,
        channelId: 'egg_turning',
        payload: 'egg:xyz',
      );

      verify(
        () => mockPlugin.zonedSchedule(
          id: 99,
          title: 'Scheduled',
          body: 'Later',
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'egg:xyz',
        ),
      ).called(1);
    });

    test('cancel calls plugin.cancel with correct id', () async {
      when(
        () => mockPlugin.cancel(id: any(named: 'id')),
      ).thenAnswer((_) async {});

      await service.init();
      await service.cancel(123);

      verify(() => mockPlugin.cancel(id: 123)).called(1);
    });

    test('cancelAll calls plugin.cancelAll', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});

      await service.init();
      await service.cancelAll();

      verify(() => mockPlugin.cancelAll()).called(1);
    });

    test(
      'cancelByIdRange cancels only matching pending notifications',
      () async {
        when(() => mockPlugin.pendingNotificationRequests()).thenAnswer(
          (_) async => [
            const PendingNotificationRequest(100000, 'a', 'b', null),
            const PendingNotificationRequest(150000, 'c', 'd', null),
            const PendingNotificationRequest(200000, 'e', 'f', null),
          ],
        );
        when(
          () => mockPlugin.cancel(id: any(named: 'id')),
        ).thenAnswer((_) async {});

        await service.init();
        final cancelled = await service.cancelByIdRange(100000, 200000);

        expect(cancelled, 2);
        verify(() => mockPlugin.cancel(id: 100000)).called(1);
        verify(() => mockPlugin.cancel(id: 150000)).called(1);
        verifyNever(() => mockPlugin.cancel(id: 200000));
      },
    );

    test('cancelByIdRange returns 0 when no pending notifications', () async {
      when(
        () => mockPlugin.pendingNotificationRequests(),
      ).thenAnswer((_) async => []);

      await service.init();
      final cancelled = await service.cancelByIdRange(100000, 200000);

      expect(cancelled, 0);
      verifyNever(() => mockPlugin.cancel(id: any(named: 'id')));
    });

    test('cancelByIdRange returns 0 when no IDs match range', () async {
      when(() => mockPlugin.pendingNotificationRequests()).thenAnswer(
        (_) async => [
          const PendingNotificationRequest(50000, 'a', 'b', null),
          const PendingNotificationRequest(300000, 'c', 'd', null),
        ],
      );

      await service.init();
      final cancelled = await service.cancelByIdRange(100000, 200000);

      expect(cancelled, 0);
      verifyNever(() => mockPlugin.cancel(id: any(named: 'id')));
    });

    test('onNotificationTap callback is invoked on tap', () async {
      String? receivedPayload;
      service.onNotificationTap = (payload) => receivedPayload = payload;

      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
          onDidReceiveBackgroundNotificationResponse: any(
            named: 'onDidReceiveBackgroundNotificationResponse',
          ),
        ),
      ).thenAnswer((invocation) async {
        // Capture the callback and simulate a tap
        final callback =
            invocation.namedArguments[const Symbol(
                  'onDidReceiveNotificationResponse',
                )]
                as DidReceiveNotificationResponseCallback;
        callback(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'chick:test-id',
          ),
        );
        return true;
      });

      await service.init();

      expect(receivedPayload, 'chick:test-id');
    });
  });

  group('FlutterTimezone integration (v5 TimezoneInfo)', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, null);
    });

    test('getLocalTimezone returns TimezoneInfo with identifier', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') return 'Europe/Istanbul';
            return null;
          });

      final info = await FlutterTimezone.getLocalTimezone();
      expect(info.identifier, 'Europe/Istanbul');

      final location = tz.getLocation(info.identifier);
      expect(location.name, 'Europe/Istanbul');
    });

    test('getLocalTimezone with localized name returns both fields', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') {
              return {
                'identifier': 'America/New_York',
                'localizedName': 'Eastern Standard Time',
                'locale': 'en_US',
              };
            }
            return null;
          });

      final info = await FlutterTimezone.getLocalTimezone();
      expect(info.identifier, 'America/New_York');
      expect(info.localizedName, isNotNull);
      expect(info.localizedName!.name, 'Eastern Standard Time');
    });

    test('timezone identifier resolves to valid tz.Location', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') return 'Asia/Tokyo';
            return null;
          });

      final info = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(info.identifier);
      tz.setLocalLocation(location);

      expect(tz.local.name, 'Asia/Tokyo');
    });
  });

  group('Android permission methods', () {
    late _MockPlugin mockPlugin;
    late NotificationService service;

    setUp(() {
      mockPlugin = _MockPlugin();
      service = NotificationService(plugin: mockPlugin);
    });

    group('requestAndroidPermission', () {
      test(
        'returns true when no Android implementation (non-Android)',
        () async {
          when(
            () => mockPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >(),
          ).thenReturn(null);

          final result = await service.requestAndroidPermission();

          expect(result, isTrue);
        },
      );

      test('returns true when permission is granted', () async {
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

        final result = await service.requestAndroidPermission();

        expect(result, isTrue);
      });

      test('returns false when permission is denied', () async {
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

        final result = await service.requestAndroidPermission();

        expect(result, isFalse);
      });

      test('returns false when permission returns null', () async {
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

        final result = await service.requestAndroidPermission();

        expect(result, isFalse);
      });
    });

    group('checkExactAlarmPermission', () {
      test(
        'returns true when no Android implementation (non-Android)',
        () async {
          when(
            () => mockPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >(),
          ).thenReturn(null);

          final result = await service.checkExactAlarmPermission();

          expect(result, isTrue);
        },
      );

      test('returns true when exact alarms allowed', () async {
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

        final result = await service.checkExactAlarmPermission();

        expect(result, isTrue);
      });

      test('returns false when exact alarms not allowed', () async {
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

        final result = await service.checkExactAlarmPermission();

        expect(result, isFalse);
      });

      test(
        'returns true when canScheduleExactNotifications returns null',
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

          final result = await service.checkExactAlarmPermission();

          expect(result, isTrue);
        },
      );
    });
  });
}
