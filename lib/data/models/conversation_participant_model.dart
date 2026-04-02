import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

part 'conversation_participant_model.freezed.dart';
part 'conversation_participant_model.g.dart';

@freezed
abstract class ConversationParticipant with _$ConversationParticipant {
  const ConversationParticipant._();

  const factory ConversationParticipant({
    required String conversationId,
    required String userId,
    @JsonKey(unknownEnumValue: ParticipantRole.unknown)
    @Default(ParticipantRole.member)
    ParticipantRole role,
    DateTime? joinedAt,
    DateTime? lastReadAt,
    @Default(false) bool isMuted,
    @Default(false) bool isLeft,
  }) = _ConversationParticipant;

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) =>
      _$ConversationParticipantFromJson(json);
}

extension ConversationParticipantX on ConversationParticipant {
  bool get isOwner => role == ParticipantRole.owner;
  bool get isAdmin =>
      role == ParticipantRole.admin || role == ParticipantRole.owner;
  bool get isActive => !isLeft;
}
