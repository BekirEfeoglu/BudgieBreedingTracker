import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/messaging_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/message_model.dart';
import '../../../data/providers/edge_function_provider.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/moderation/moderation_providers.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';
import '../../../shared/providers/community.dart';
import 'messaging_realtime_providers.dart';

class MessagingFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? resultConversationId;

  const MessagingFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.resultConversationId,
  });

  MessagingFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? resultConversationId,
  }) => MessagingFormState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
    resultConversationId: resultConversationId ?? this.resultConversationId,
  );
}

class MessagingFormNotifier extends Notifier<MessagingFormState> {
  @override
  MessagingFormState build() => const MessagingFormState();

  /// Maximum allowed message content length.
  static const _maxContentLength = 2000;

  /// Minimum interval between messages to prevent spam.
  static const _sendCooldown = Duration(seconds: 2);
  DateTime? _lastSentAt;

  /// Whether a send would currently be rejected by the client-side cooldown.
  ///
  /// The photo-attachment path uploads to Storage BEFORE calling [sendMessage],
  /// so a cooldown-rejected send would orphan the uploaded object. Callers
  /// check this before uploading to avoid that orphan entirely.
  bool get isWithinSendCooldown {
    final last = _lastSentAt;
    return last != null && DateTime.now().difference(last) < _sendCooldown;
  }

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
    String? optimisticMessageId;
    try {
      // Client-side throttle — prevent rapid-fire messages
      final now = DateTime.now();
      if (_lastSentAt != null && now.difference(_lastSentAt!) < _sendCooldown) {
        state = state.copyWith(error: 'messaging.send_cooldown'.tr());
        return null;
      }

      // Content length validation
      final trimmedContent = content?.trim();
      if (trimmedContent != null && trimmedContent.length > _maxContentLength) {
        state = state.copyWith(error: 'community.content_too_long'.tr());
        return null;
      }

      // Content moderation check (Apple Guideline 1.2)
      if (trimmedContent != null && trimmedContent.isNotEmpty) {
        final moderationService = ref.read(contentModerationServiceProvider);
        final modResult = await moderationService.checkText(trimmedContent);
        if (!modResult.isAllowed) {
          state = state.copyWith(
            error: ContentModerationService.localizedError(
              modResult.rejectionReason,
            ),
          );
          return null;
        }
      }

      final messageId = clientMessageId ?? const Uuid().v7();
      optimisticMessageId = messageId;
      final optimisticMessage = Message(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        content: trimmedContent,
        messageType: messageType,
        imageUrl: imageUrl,
        referenceId: referenceId,
        referenceData: referenceData ?? const {},
        readBy: [senderId],
        deliveryStatus: MessageDeliveryStatus.sending,
        createdAt: DateTime.now().toUtc(),
      );
      ref
          .read(messagingRealtimeProvider.notifier)
          .addLocalMessage(optimisticMessage);

      final repo = ref.read(messagingRepositoryProvider);
      final sent = await repo.sendMessage({
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        if (senderAvatarUrl != null) 'sender_avatar_url': senderAvatarUrl,
        if (trimmedContent != null) 'content': trimmedContent,
        'message_type': messageType.toJson(),
        if (imageUrl != null) 'image_url': imageUrl,
        if (referenceId != null) 'reference_id': referenceId,
        if (referenceData != null) 'reference_data': referenceData,
        'read_by': [senderId],
      });
      final delivered = sent.copyWith(
        deliveryStatus: MessageDeliveryStatus.sent,
      );
      ref.read(messagingRealtimeProvider.notifier).addLocalMessage(delivered);
      _lastSentAt = DateTime.now();
      final pushFuture = ref
          .read(edgeFunctionClientProvider)
          .sendMessagePush(messageId: messageId);
      unawaited(
        pushFuture.then((result) {
          if (!result.success) {
            AppLogger.warning(
              'messaging: new-message push delivery was not accepted',
            );
          }
        }),
      );
      // Signal success so the input bar clears the field. Without this the
      // `isSuccess` flag stayed at its `false` default on the send path
      // (only conversation-creation methods set it), so the sent text was
      // never cleared and the user re-typed / double-posted.
      state = state.copyWith(isSuccess: true, error: null);
      // Return the persisted message so the input bar can optimistically
      // append it — the sender sees it immediately even when realtime is
      // gated off by rollout flags. The detail-screen merge dedupes by id.
      return delivered;
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      if (optimisticMessageId != null) {
        ref
            .read(messagingRealtimeProvider.notifier)
            .markLocalMessageFailed(optimisticMessageId);
      }
      state = state.copyWith(error: 'errors.unknown'.tr());
      return null;
    }
  }

  Future<String?> startDirectConversation({
    required String userId1,
    required String userId2,
  }) async {
    if (state.isLoading) return null;
    // Reject conversation creation if either party has blocked the other
    // locally. The server-side `block_user` table also rejects new DMs
    // both ways; this client-side guard avoids the round-trip and gives
    // the user a localized error instead of a generic 500.
    final blocked = ref.read(blockedUsersProvider);
    if (blocked.contains(userId2)) {
      state = state.copyWith(
        isLoading: false,
        error: 'messaging.user_blocked'.tr(),
      );
      return null;
    }
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final conversationId = await repo.getOrCreateDirectConversation(
        userId1: userId1,
        userId2: userId2,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        resultConversationId: conversationId,
      );
      return conversationId;
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
      return null;
    }
  }

  Future<String?> createGroupConversation({
    required String creatorId,
    required String name,
    required List<String> participantIds,
    String? imageUrl,
  }) async {
    if (state.isLoading) return null;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final conversationId = await repo.createGroupConversation(
        creatorId: creatorId,
        name: name,
        participantIds: participantIds,
        imageUrl: imageUrl,
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        resultConversationId: conversationId,
      );
      return conversationId;
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
      return null;
    }
  }

  Future<void> leaveGroup(String conversationId, String userId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.leaveConversation(conversationId, userId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  Future<void> addMember(String conversationId, String userId) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.addParticipant(conversationId, userId);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
    }
  }

  Future<void> toggleMute(
    String conversationId,
    String userId, {
    required bool muted,
  }) async {
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.muteConversation(conversationId, userId, muted: muted);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
    }
  }

  void reset() => state = const MessagingFormState();

  /// Clears just the error field so the UI (which surfaces send failures via a
  /// SnackBar) doesn't replay the same message when the listener re-fires for
  /// an unrelated state change.
  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(error: null);
  }
}

final messagingFormStateProvider =
    NotifierProvider<MessagingFormNotifier, MessagingFormState>(
      MessagingFormNotifier.new,
    );
