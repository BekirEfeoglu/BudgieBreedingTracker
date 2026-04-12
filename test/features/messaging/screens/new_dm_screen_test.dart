@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/screens/new_dm_screen.dart';

import '../../../helpers/test_localization.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository mockRepo;

  setUp(() {
    mockRepo = MockMessagingRepository();
  });

  Widget buildSubject({
    MessagingFormNotifier Function()? notifierFactory,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        messagingRepositoryProvider.overrideWithValue(mockRepo),
        if (notifierFactory != null)
          messagingFormStateProvider.overrideWith(notifierFactory),
      ],
      child: const MaterialApp(
        home: NewDmScreen(),
      ),
    );
  }

  group('NewDmScreen', () {
    testWidgets('renders search field and title', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n('messaging.direct_message')), findsOneWidget);
      expect(find.byIcon(LucideIcons.search), findsOneWidget);
    });

    testWidgets('search field has autofocus', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('shows no results when query has 2+ chars but no matches',
        (tester) async {
      when(() => mockRepo.searchProfiles(
            any(),
            excludeUserId: any(named: 'excludeUserId'),
          )).thenAnswer((_) async => []);

      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextField), 'ab');
      // Wait for debounce timer and search
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text(l10n('common.no_results')), findsOneWidget);
    });

    testWidgets('shows search results when query matches users',
        (tester) async {
      when(() => mockRepo.searchProfiles(
            any(),
            excludeUserId: any(named: 'excludeUserId'),
          )).thenAnswer((_) async => [
            {
              'id': 'user-2',
              'display_name': 'John Doe',
              'avatar_url': null,
            },
          ]);

      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextField), 'john');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);
    });

    testWidgets('does not search when query is less than 2 characters',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepo.searchProfiles(
            any(),
            excludeUserId: any(named: 'excludeUserId'),
          ));
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      when(() => mockRepo.searchProfiles(
            any(),
            excludeUserId: any(named: 'excludeUserId'),
          )).thenAnswer((_) async => []);

      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      // Initially no clear button
      expect(find.byIcon(LucideIcons.x), findsNothing);

      await tester.enterText(find.byType(TextField), 'test');
      // Pump past the debounce timer so it completes
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('shows loading indicator during search', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();

      when(() => mockRepo.searchProfiles(
            any(),
            excludeUserId: any(named: 'excludeUserId'),
          )).thenAnswer((_) => completer.future);

      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextField), 'test');
      // Advance past debounce timer
      await tester.pump(const Duration(milliseconds: 350));
      // One more frame for setState
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid pending timer warnings
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });
}

class _FakeMessagingFormNotifier extends MessagingFormNotifier {
  @override
  MessagingFormState build() => const MessagingFormState();

  @override
  Future<String?> startDirectConversation({
    required String userId1,
    required String userId2,
  }) async {
    return null;
  }

  @override
  void reset() {}
}
