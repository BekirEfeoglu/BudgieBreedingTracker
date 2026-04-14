import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/messaging_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/moderation/moderation_providers.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';

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
  }) =>
      MessagingFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isSuccess: isSuccess ?? this.isSuccess,
        resultConversationId:
            resultConversationId ?? this.resultConversationId,
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
  }) async {
    try {
      // Client-side throttle — prevent rapid-fire messages
      final now = DateTime.now();
      if (_lastSentAt != null && now.difference(_lastSentAt!) < _sendCooldown) {
        state = state.copyWith(
          error: 'messaging.send_cooldown'.tr(),
        );
        return;
      }

      // Content length validation
      final trimmedContent = content?.trim();
      if (trimmedContent != null && trimmedContent.length > _maxContentLength) {
        state = state.copyWith(
          error: 'community.content_too_long'.tr(),
        );
        return;
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
          return;
        }
      }

      final repo = ref.read(messagingRepositoryProvider);
      await repo.sendMessage({
        'id': const Uuid().v4(),
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
      _lastSentAt = DateTime.now();
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> startDirectConversation({
    required String userId1,
    required String userId2,
  }) async {
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
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<String?> createGroupConversation({
    required String creatorId,
    required String name,
    required List<String> participantIds,
    String? imageUrl,
  }) async {
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
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> leaveGroup(String conversationId, String userId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      await repo.leaveConversation(conversationId, userId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
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
}

final messagingFormStateProvider =
    NotifierProvider<MessagingFormNotifier, MessagingFormState>(
  MessagingFormNotifier.new,
);
