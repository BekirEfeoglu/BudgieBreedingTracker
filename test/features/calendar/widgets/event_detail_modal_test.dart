import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_detail_modal.dart';

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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final activeEvent = Event(
    id: 'event-1',
    title: 'Veteriner Kontrolü',
    eventDate: DateTime(2024, 3, 15, 10, 30),
    type: EventType.health,
    userId: 'user-1',
    status: EventStatus.active,
    notes: 'Kanat muayenesi',
  );

  final completedEvent = activeEvent.copyWith(
    id: 'event-2',
    status: EventStatus.completed,
  );

  Widget buildWithModal({
    required Event event,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    ValueChanged<EventStatus>? onStatusChange,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const _MockAssetLoader(),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showEventDetailModal(
                context,
                event: event,
                onEdit: onEdit ?? () {},
                onDelete: onDelete ?? () {},
                onStatusChange: onStatusChange,
              ),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openModal(
    WidgetTester tester, {
    required Event event,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    ValueChanged<EventStatus>? onStatusChange,
  }) async {
    await tester.pumpWidget(
      buildWithModal(
        event: event,
        onEdit: onEdit,
        onDelete: onDelete,
        onStatusChange: onStatusChange,
      ),
    );
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();
  }

  group('EventDetailModal', () {
    testWidgets('shows event title after modal opens', (tester) async {
      await openModal(tester, event: activeEvent);
      expect(find.text('Veteriner Kontrolü'), findsOneWidget);
    });

    testWidgets('shows event notes when present', (tester) async {
      await openModal(tester, event: activeEvent);
      expect(find.text('Kanat muayenesi'), findsOneWidget);
    });

    testWidgets('shows edit button in modal', (tester) async {
      await openModal(tester, event: activeEvent);
      expect(
        find.widgetWithText(OutlinedButton, 'common.edit'),
        findsOneWidget,
      );
    });

    testWidgets('shows delete button in modal', (tester) async {
      await openModal(tester, event: activeEvent);
      expect(
        find.widgetWithText(FilledButton, 'common.delete'),
        findsOneWidget,
      );
    });

    testWidgets('shows status change buttons for active event', (tester) async {
      await openModal(tester, event: activeEvent, onStatusChange: (_) {});
      expect(
        find.widgetWithText(OutlinedButton, 'calendar.mark_completed'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'calendar.mark_cancelled'),
        findsOneWidget,
      );
    });

    testWidgets('no status change buttons for completed event', (tester) async {
      await openModal(tester, event: completedEvent, onStatusChange: (_) {});
      expect(
        find.widgetWithText(OutlinedButton, 'calendar.mark_completed'),
        findsNothing,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'calendar.mark_cancelled'),
        findsNothing,
      );
    });

    testWidgets('onEdit callback is invoked when edit button tapped', (
      tester,
    ) async {
      var editCalled = false;
      await openModal(
        tester,
        event: activeEvent,
        onEdit: () => editCalled = true,
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'common.edit'));
      await tester.pumpAndSettle();
      expect(editCalled, isTrue);
    });
  });
}
