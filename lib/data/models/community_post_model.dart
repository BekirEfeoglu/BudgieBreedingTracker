import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';

part 'community_post_model.freezed.dart';
part 'community_post_model.g.dart';

@freezed
abstract class CommunityPost with _$CommunityPost {
  const CommunityPost._();

  const factory CommunityPost({
    required String id,
    required String userId,
    @Default('') String username,
    String? avatarUrl,
    @JsonKey(unknownEnumValue: CommunityPostType.unknown)
    @Default(CommunityPostType.general)
    CommunityPostType postType,
    String? title,
    @Default('') String content,
    String? imageUrl,
    @Default([]) List<String> imageUrls,
    String? birdId,
    String? birdName,
    @Default([]) List<String> mutationTags,
    @Default([]) List<String> tags,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @JsonKey(includeFromJson: false) @Default(false) bool isLikedByMe,
    @JsonKey(includeFromJson: false) @Default(false) bool isBookmarkedByMe,
    @JsonKey(includeFromJson: false) @Default(false) bool isFollowingAuthor,
    @Default(false) bool isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CommunityPost;

  factory CommunityPost.fromJson(Map<String, dynamic> json) =>
      _$CommunityPostFromJson(json);
}

extension CommunityPostX on CommunityPost {
  List<String> get allImageUrls =>
      [if (imageUrl != null) imageUrl!, ...imageUrls];

  String? get primaryImageUrl =>
      allImageUrls.isNotEmpty ? allImageUrls.first : null;
}
