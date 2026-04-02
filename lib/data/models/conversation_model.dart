import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
abstract class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    required String id,
    @JsonKey(unknownEnumValue: ConversationType.unknown)
    @Default(ConversationType.direct)
    ConversationType type,
    String? name,
    String? imageUrl,
    required String creatorId,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    String? lastMessageUserId,
    @Default(0) int participantCount,
    @JsonKey(includeFromJson: false) @Default(0) int unreadCount,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}

extension ConversationX on Conversation {
  bool get isGroup => type == ConversationType.group;
  bool get isDirect => type == ConversationType.direct;
  bool get hasUnread => unreadCount > 0;
}
