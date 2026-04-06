@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/screens/group_form_screen.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject({
    MessagingFormNotifier Function()? notifierFactory,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        if (notifierFactory != null)
          messagingFormStateProvider.overrideWith(notifierFactory),
      ],
      child: const MaterialApp(
        home: GroupFormScreen(),
      ),
    );
  }

  group('GroupFormScreen', () {
    testWidgets('renders form with group name field and create button',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text(l10n('messaging.new_group')), findsOneWidget);
      expect(find.text(l10n('messaging.group_name')), findsOneWidget);
      expect(find.text(l10n('messaging.create_group')), findsOneWidget);
      expect(find.text(l10n('messaging.select_members')), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      // Tap create button without entering name
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('messaging.group_name_required')),
        findsOneWidget,
      );
    });

    testWidgets('shows loading state on PrimaryButton', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          notifierFactory: () =>
              _FakeMessagingFormNotifier(isLoading: true),
        ),
        settle: false,
      );
      await tester.pump();

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.isLoading, isTrue);
    });

    testWidgets('accepts text input in group name field', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextFormField), 'My Budgie Group');
      await tester.pumpAndSettle();

      expect(find.text('My Budgie Group'), findsOneWidget);
    });

    testWidgets('does not show validation error with valid name',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextFormField), 'Valid Group');
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('messaging.group_name_required')),
        findsNothing,
      );
    });
  });
}

class _FakeMessagingFormNotifier extends MessagingFormNotifier {
  final bool isLoading;

  _FakeMessagingFormNotifier({this.isLoading = false});

  @override
  MessagingFormState build() => MessagingFormState(isLoading: isLoading);

  @override
  Future<String?> createGroupConversation({
    required String creatorId,
    required String name,
    required List<String> participantIds,
    String? imageUrl,
  }) async {
    return null;
  }

  @override
  void reset() {}
}
