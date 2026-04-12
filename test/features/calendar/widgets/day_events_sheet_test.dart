import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/day_events_sheet.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

class _MockAssetLoader extends AssetLoader {
  const _MockAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

class _FakeEventFormNotifier extends EventFormNotifier {
  @override
  EventFormState build() => const EventFormState();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final testDate = DateTime(2024, 3, 15);

  Event makeEvent(String id, String title) => Event(
    id: id,
    title: title,
    eventDate: testDate.copyWith(hour: 10),
    type: EventType.health,
    userId: 'user-1',
  );

  Widget buildSubject({List<Event> events = const []}) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const _MockAssetLoader(),
      child: ProviderScope(
        overrides: [
          eventFormStateProvider.overrideWith(() => _FakeEventFormNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DayEventsSheet(date: testDate, events: events),
          ),
        ),
      ),
    );
  }

  group('DayEventsSheet', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(DayEventsSheet), findsOneWidget);
    });

    testWidgets('shows drag handle container at top', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      // Drag handle is a Container(width:40, height:4)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows EmptyState when events list is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows EventCards when events are provided', (tester) async {
      final events = [makeEvent('e1', 'Muayene'), makeEvent('e2', 'Aşı')];
      await tester.pumpWidget(buildSubject(events: events));
      await tester.pump();
      expect(find.byType(EventCard), findsNWidgets(2));
    });

    testWidgets('shows event titles in the list', (tester) async {
      final events = [makeEvent('e1', 'Muayene')];
      await tester.pumpWidget(buildSubject(events: events));
      await tester.pump();
      expect(find.text('Muayene'), findsOneWidget);
    });

    testWidgets('shows add event IconButton', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('shows DraggableScrollableSheet', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });
  });
}
