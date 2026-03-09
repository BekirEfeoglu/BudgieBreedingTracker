import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_comment_model.freezed.dart';
part 'community_comment_model.g.dart';

@freezed
abstract class CommunityComment with _$CommunityComment {
  const CommunityComment._();

  const factory CommunityComment({
    required String id,
    required String postId,
    required String userId,
    @Default('') String username,
    String? avatarUrl,
    required String content,
    @Default(0) int likeCount,
    @JsonKey(includeFromJson: false) @Default(false) bool isLikedByMe,
    DateTime? createdAt,
  }) = _CommunityComment;

  factory CommunityComment.fromJson(Map<String, dynamic> json) =>
      _$CommunityCommentFromJson(json);
}
