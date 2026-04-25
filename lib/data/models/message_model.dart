import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class Message with _$Message {
  const Message._();

  @Assert(r"id != ''", 'Message.id must not be empty')
  @Assert(r"conversationId != ''", 'Message.conversationId must not be empty')
  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    @Default('') String senderName,
    String? senderAvatarUrl,
    String? content,
    @JsonKey(unknownEnumValue: MessageType.unknown)
    @Default(MessageType.text)
    MessageType messageType,
    String? imageUrl,
    String? referenceId,
    @Default({}) Map<String, dynamic> referenceData,
    @Default([]) List<String> readBy,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

extension MessageX on Message {
  bool get isText => messageType == MessageType.text;
  bool get isImage => messageType == MessageType.image;
  bool get isBirdCard => messageType == MessageType.birdCard;
  bool get isListingCard => messageType == MessageType.listingCard;
  bool isReadBy(String userId) => readBy.contains(userId);
}
