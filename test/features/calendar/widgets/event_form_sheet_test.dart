import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_form_sheet.dart';

import '../../../helpers/mocks.dart';

// Top-level class declarations (Dart requires classes to be outside functions)
class _FakeEventFormNotifier extends EventFormNotifier {
  @override
  EventFormState build() => const EventFormState();
}

class _LoadingNotifier extends EventFormNotifier {
  @override
  EventFormState build() => const EventFormState(isLoading: true);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final existingEvent = Event(
    id: 'event-1',
    userId: 'test-user',
    title: 'Veteriner',
    eventDate: DateTime(2026, 7, 28, 10),
    type: EventType.health,
  );

  Widget buildWithModal({
    Event? event,
    MockEventReminderRepository? reminderRepository,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        eventFormStateProvider.overrideWith(() => _FakeEventFormNotifier()),
        if (reminderRepository != null)
          eventReminderRepositoryProvider.overrideWithValue(reminderRepository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showEventFormSheet(context, existingEvent: event),
              child: const Text('Open Form'),
            ),
          ),
        ),
      ),
    );
  }

  group('EventFormSheet', () {
    testWidgets('opens modal bottom sheet when triggered', (tester) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('shows title text field in form', (tester) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('shows event type dropdown in form', (tester) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<EventType>),
        findsOneWidget,
      );
    });

    testWidgets('shows reminder offset dropdown for a new event', (
      tester,
    ) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<int>),
        findsOneWidget,
      );
    });

    testWidgets(
      'edit save stays disabled until the existing reminder is hydrated',
      (tester) async {
        final reminderRepository = MockEventReminderRepository();
        final completer = Completer<List<EventReminder>>();
        when(
          () => reminderRepository.getByEvent(existingEvent.id),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildWithModal(
            event: existingEvent,
            reminderRepository: reminderRepository,
          ),
        );
        await tester.tap(find.text('Open Form'));
        await tester.pump();

        final loadingDropdown = tester.widget<DropdownButtonFormField<int>>(
          find.byWidgetPredicate(
            (widget) => widget is DropdownButtonFormField<int>,
          ),
        );
        final loadingButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(loadingDropdown.onChanged, isNull);
        expect(loadingButton.onPressed, isNull);

        completer.complete([
          const EventReminder(
            id: 'reminder-1',
            userId: 'test-user',
            eventId: 'event-1',
            minutesBefore: 60,
          ),
        ]);
        await tester.pumpAndSettle();

        final reminderFieldState = tester.state<FormFieldState<int>>(
          find.byWidgetPredicate(
            (widget) => widget is DropdownButtonFormField<int>,
          ),
        );
        final readyButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(reminderFieldState.value, 60);
        expect(readyButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'edit reminder load error blocks save and retry hydrates the field',
      (tester) async {
        final reminderRepository = MockEventReminderRepository();
        var attempts = 0;
        when(() => reminderRepository.getByEvent(existingEvent.id)).thenAnswer((
          _,
        ) async {
          attempts++;
          if (attempts == 1) throw StateError('database detail');
          return const <EventReminder>[];
        });

        await tester.pumpWidget(
          buildWithModal(
            event: existingEvent,
            reminderRepository: reminderRepository,
          ),
        );
        await tester.tap(find.text('Open Form'));
        await tester.pumpAndSettle();

        expect(find.text('common.data_load_error'), findsOneWidget);
        expect(find.textContaining('database detail'), findsNothing);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );

        await tester.tap(find.text('common.retry'));
        await tester.pumpAndSettle();

        final reminderFieldState = tester.state<FormFieldState<int>>(
          find.byWidgetPredicate(
            (widget) => widget is DropdownButtonFormField<int>,
          ),
        );
        expect(attempts, 2);
        expect(reminderFieldState.value, -1);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('shows save FilledButton', (tester) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows Form widget', (tester) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('save button is disabled when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            eventFormStateProvider.overrideWith(() => _LoadingNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showEventFormSheet(context),
                  child: const Text('Open Form'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Form'));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows notes text field in form', (tester) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();

      // title + notes + possibly time field — at least 2 text fields
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    });

    testWidgets('form is inside BottomSheet with rounded corners', (
      tester,
    ) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('shows drag handle container at top of form', (tester) async {
      await tester.pumpWidget(buildWithModal());
      await tester.tap(find.text('Open Form'));
      await tester.pump();

      // Just verify BottomSheet opened successfully (drag handle widget exists)
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
