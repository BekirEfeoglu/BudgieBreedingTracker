import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/screens/calendar_screen.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

class _MockAdService extends Mock implements AdService {
  @override
  Future<void> ensureSdkInitialized() async {}
}

/// Minimal asset loader that returns empty translations so context.locale
/// is available in tests without loading actual translation assets.
class _MockAssetLoader extends AssetLoader {
  const _MockAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createSubject({
    required Stream<List<Event>> eventsStream,
    AdService? adService,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const _MockAssetLoader(),
      child: ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          eventsStreamProvider('test-user').overrideWith((_) => eventsStream),
          // AppBar action providers
          unreadNotificationsProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          userProfileProvider.overrideWith((_) => Stream.value(null)),
          currentUserProvider.overrideWith((_) => null),
          adServiceProvider.overrideWithValue(adService ?? _MockAdService()),
          effectivePremiumProvider.overrideWithValue(false),
          // Override realtime provider to avoid Supabase client in tests
          eventRealtimeSyncProvider('test-user').overrideWith((_) {}),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ),
    );
  }

  group('CalendarScreen', () {
    testWidgets('shows loading indicator while events are loading', (
      tester,
    ) async {
      final controller = StreamController<List<Event>>();
      addTearDown(controller.close);

      await tester.pumpWidget(createSubject(eventsStream: controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(eventsStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows AppBar with calendar title', (tester) async {
      final controller = StreamController<List<Event>>();
      addTearDown(controller.close);

      await tester.pumpWidget(createSubject(eventsStream: controller.stream));
      await tester.pump();

      expect(find.text(l10n('calendar.title')), findsOneWidget);
    });

    testWidgets('shows view mode segmented button in AppBar', (tester) async {
      final controller = StreamController<List<Event>>();
      addTearDown(controller.close);

      await tester.pumpWidget(createSubject(eventsStream: controller.stream));
      await tester.pump();

      expect(find.byType(SegmentedButton<CalendarViewMode>), findsOneWidget);
    });

    testWidgets('shows event filter segmented button in AppBar', (
      tester,
    ) async {
      final controller = StreamController<List<Event>>();
      addTearDown(controller.close);

      await tester.pumpWidget(createSubject(eventsStream: controller.stream));
      await tester.pump();

      expect(find.byType(SegmentedButton<CalendarEventFilter>), findsOneWidget);
    });

    testWidgets('shows FAB when events load', (tester) async {
      await tester.pumpWidget(createSubject(eventsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders calendar grid in month view when data loads', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(eventsStream: Stream.value([])));

      await tester.pumpAndSettle();

      // CalendarGrid renders inside CustomScrollView in month view
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows today button in AppBar actions', (tester) async {
      final controller = StreamController<List<Event>>();
      addTearDown(controller.close);

      await tester.pumpWidget(createSubject(eventsStream: controller.stream));
      await tester.pump();

      // Today button (calendarCheck icon) is an IconButton in AppBar
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('has RefreshIndicator wrapping content', (tester) async {
      await tester.pumpWidget(createSubject(eventsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('week and day views expose visible period navigation', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(eventsStream: Stream.value([])));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarScreen)),
      );
      container
          .read(calendarViewProvider.notifier)
          .setViewMode(CalendarViewMode.week);
      await tester.pumpAndSettle();

      expect(find.byTooltip(l10n('calendar.previous_week')), findsOneWidget);
      expect(find.byTooltip(l10n('calendar.next_week')), findsOneWidget);
      final weekDate = container.read(selectedDateProvider);
      await tester.tap(find.byTooltip(l10n('calendar.next_week')));
      await tester.pumpAndSettle();
      expect(
        container.read(selectedDateProvider),
        DateTime(weekDate.year, weekDate.month, weekDate.day + 7),
      );

      container
          .read(calendarViewProvider.notifier)
          .setViewMode(CalendarViewMode.day);
      await tester.pumpAndSettle();

      expect(find.byTooltip(l10n('calendar.previous_day')), findsOneWidget);
      expect(find.byTooltip(l10n('calendar.next_day')), findsOneWidget);
    });

    testWidgets('rapid double-tap on an event requests one interstitial ad', (
      tester,
    ) async {
      final now = DateTime.now();
      final event = Event(
        id: 'event-1',
        title: 'Kontrol',
        eventDate: DateTime(now.year, now.month, now.day, 10),
        type: EventType.health,
        userId: 'test-user',
      );
      final adService = _MockAdService();
      when(
        () =>
            adService.showInterstitialAd(onAdClosed: any(named: 'onAdClosed')),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createSubject(
          eventsStream: Stream.value([event]),
          adService: adService,
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(EventCard),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(EventCard));
      await tester.tap(find.byType(EventCard));
      await tester.pump();

      verify(
        () =>
            adService.showInterstitialAd(onAdClosed: any(named: 'onAdClosed')),
      ).called(1);
    });

    testWidgets('AppBar title is calendar.title', (tester) async {
      await tester.pumpWidget(createSubject(eventsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.text(l10n('calendar.title')), findsOneWidget);
    });

    testWidgets('does not overflow on small screens', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSubject(eventsStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<CalendarViewMode>), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: exception is FlutterError ? exception.toStringDeep() : null,
      );
    });
  });
}
