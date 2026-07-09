@Tags(['community'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';
import 'package:budgie_breeding_tracker/data/models/message_model.dart';
import 'package:budgie_breeding_tracker/data/providers/profile_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_providers.dart'
    show messageAttachmentsEnabledProvider;
import 'package:budgie_breeding_tracker/features/messaging/services/message_attachment_service.dart';
import 'package:budgie_breeding_tracker/features/messaging/widgets/message_input_bar.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject({
    MessagingFormNotifier Function()? notifierFactory,
    bool? attachmentsEnabled,
    MessageAttachmentService? attachmentService,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        if (attachmentsEnabled != null)
          messageAttachmentsEnabledProvider.overrideWithValue(
            attachmentsEnabled,
          ),
        // MessageInputBar now reads the current user's profile to pass
        // senderName into the message payload (audit M6). Override with
        // a fixed stream so tests stay self-contained.
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        if (notifierFactory != null)
          messagingFormStateProvider.overrideWith(notifierFactory),
        if (attachmentService != null)
          messageAttachmentServiceProvider.overrideWithValue(attachmentService),
      ],
      child: const MaterialApp(
        home: Scaffold(body: MessageInputBar(conversationId: 'conv-1')),
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
      expect(find.text(l10n('messaging.type_message')), findsOneWidget);
    });

    testWidgets('renders send button', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: _FakeMessagingFormNotifier.new),
      );

      expect(find.byIcon(LucideIcons.send), findsOneWidget);
    });

    testWidgets('renders attachment button when attachments flag is enabled', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          notifierFactory: _FakeMessagingFormNotifier.new,
          attachmentsEnabled: true,
        ),
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

    testWidgets('surfaces the error and preserves text when a send fails', (
      tester,
    ) async {
      final failing = _FailingMessagingFormNotifier();
      await pumpLocalizedApp(
        tester,
        buildSubject(notifierFactory: () => failing),
      );

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.send));
      await tester.pumpAndSettle();

      // The failure reason is shown with a retry action.
      expect(find.text('send failed'), findsOneWidget);
      expect(find.text(l10n('common.retry')), findsOneWidget);
      // The typed text is preserved so it can be retried.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Hello');
      expect(failing.sendCount, 1);

      // Tapping retry re-sends the preserved text.
      await tester.tap(find.text(l10n('common.retry')));
      await tester.pumpAndSettle();
      expect(failing.sendCount, 2);
    });

    testWidgets(
      'attachment button opens bottom sheet when attachments flag is enabled',
      (tester) async {
        await pumpLocalizedApp(
          tester,
          buildSubject(
            notifierFactory: _FakeMessagingFormNotifier.new,
            attachmentsEnabled: true,
          ),
        );

        await tester.tap(find.byIcon(LucideIcons.plus));
        await tester.pumpAndSettle();

        expect(find.byIcon(LucideIcons.image), findsOneWidget);
        expect(find.text(l10n('messaging.attach_photo')), findsAtLeast(1));
        expect(find.text(l10n('messaging.attach_bird')), findsNothing);
        expect(find.text(l10n('messaging.attach_listing')), findsNothing);
      },
    );

    testWidgets('photo attachment uploads and sends an image message', (
      tester,
    ) async {
      var pickCount = 0;
      String? uploadedUserId;
      String? uploadedConversationId;
      final attachmentService = MessageAttachmentService(
        pickPhoto: (_) async {
          pickCount++;
          return XFile.fromData(Uint8List(128), name: 'dm.jpg');
        },
        uploadPhoto:
            ({required userId, required conversationId, required file}) async {
              uploadedUserId = userId;
              uploadedConversationId = conversationId;
              return 'https://cdn.example.com/message-photo.jpg';
            },
      );
      final recorder = _RecordingMessagingFormNotifier();

      await pumpLocalizedApp(
        tester,
        buildSubject(
          notifierFactory: () => recorder,
          attachmentsEnabled: true,
          attachmentService: attachmentService,
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ListTile, l10n('messaging.attach_photo')),
      );
      await tester.pumpAndSettle();

      expect(pickCount, 1);
      expect(uploadedUserId, 'test-user');
      expect(uploadedConversationId, 'conv-1');
      expect(recorder.sendCount, 1);
      expect(recorder.lastMessageType, MessageType.image);
      expect(
        recorder.lastImageUrl,
        'https://cdn.example.com/message-photo.jpg',
      );
    });

    testWidgets('photo attachment upload failure shows localized error', (
      tester,
    ) async {
      final attachmentService = MessageAttachmentService(
        pickPhoto: (_) async {
          return XFile.fromData(Uint8List(128), name: 'dm.jpg');
        },
        uploadPhoto:
            ({required userId, required conversationId, required file}) async {
              throw Exception('upload failed');
            },
      );
      final recorder = _RecordingMessagingFormNotifier();

      await pumpLocalizedApp(
        tester,
        buildSubject(
          notifierFactory: () => recorder,
          attachmentsEnabled: true,
          attachmentService: attachmentService,
        ),
      );

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ListTile, l10n('messaging.attach_photo')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('messaging.attachment_upload_failed')),
        findsOneWidget,
      );
      expect(recorder.sendCount, 0);
    });

    testWidgets('send button is disabled for whitespace-only input', (
      tester,
    ) async {
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

class _RecordingMessagingFormNotifier extends _FakeMessagingFormNotifier {
  int sendCount = 0;
  MessageType? lastMessageType;
  String? lastImageUrl;

  @override
  Future<Message?> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType messageType = MessageType.text,
    String? imageUrl,
    String? referenceId,
    Map<String, dynamic>? referenceData,
    String? clientMessageId,
  }) {
    sendCount++;
    lastMessageType = messageType;
    lastImageUrl = imageUrl;
    return super.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      content: content,
      messageType: messageType,
      imageUrl: imageUrl,
      referenceId: referenceId,
      referenceData: referenceData,
      clientMessageId: clientMessageId,
    );
  }
}

class _FakeMessagingFormNotifier extends MessagingFormNotifier {
  @override
  MessagingFormState build() => const MessagingFormState();

  @override
  Future<Message?> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType messageType = MessageType.text,
    String? imageUrl,
    String? referenceId,
    Map<String, dynamic>? referenceData,
    String? clientMessageId,
  }) async {
    // The input bar clears the controller (and optimistically appends) only
    // when sendMessage returns a non-null persisted message; the fake mirrors
    // that success contract.
    state = state.copyWith(isLoading: false, isSuccess: true, error: null);
    return Message(
      id: 'fake-msg',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
    );
  }

  @override
  void reset() {}
}

/// Always fails: returns null and sets a fixed error, so the input bar keeps
/// the typed text and surfaces the failure via SnackBar.
class _FailingMessagingFormNotifier extends MessagingFormNotifier {
  int sendCount = 0;

  @override
  MessagingFormState build() => const MessagingFormState();

  @override
  Future<Message?> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType messageType = MessageType.text,
    String? imageUrl,
    String? referenceId,
    Map<String, dynamic>? referenceData,
    String? clientMessageId,
  }) async {
    sendCount++;
    state = state.copyWith(error: 'send failed', isSuccess: false);
    return null;
  }

  @override
  void reset() {}
}
