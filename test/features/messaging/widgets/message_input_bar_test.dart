@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/widgets/message_input_bar.dart';

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
        home: Scaffold(
          body: MessageInputBar(conversationId: 'conv-1'),
        ),
      ),
    );
  }

  group('MessageInputBar', () {
    testWidgets('renders text field with hint text', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text(l10n('messaging.type_message')),
        findsOneWidget,
      );
    });

    testWidgets('renders send button', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      expect(find.byIcon(LucideIcons.send), findsOneWidget);
    });

    testWidgets('renders attachment button', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    });

    testWidgets('send button is disabled when text is empty', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, LucideIcons.send),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('send button is enabled when text is entered', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pumpAndSettle();

      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, LucideIcons.send),
      );
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('text field clears after sending message', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pumpAndSettle();

      // Tap send
      await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.send));
      await tester.pumpAndSettle();

      // Text field should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('attachment button opens bottom sheet', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      // Bottom sheet should show attachment options
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.byIcon(LucideIcons.bird), findsOneWidget);
      expect(find.byIcon(LucideIcons.store), findsOneWidget);
      expect(
        find.text(l10n('messaging.attach_photo')),
        findsAtLeast(1),
      );
      expect(find.text(l10n('messaging.attach_bird')), findsOneWidget);
      expect(
        find.text(l10n('messaging.attach_listing')),
        findsOneWidget,
      );
    });

    testWidgets('send button is disabled for whitespace-only input',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      final sendButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, LucideIcons.send),
      );
      expect(sendButton.onPressed, isNull);
    });
  });
}

class _FakeMessagingFormNotifier extends MessagingFormNotifier {
  @override
  MessagingFormState build() => const MessagingFormState();

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType messageType = MessageType.text,
    String? imageUrl,
    String? referenceId,
    Map<String, dynamic>? referenceData,
  }) async {}

  @override
  void reset() {}
}
