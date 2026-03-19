import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/remote/storage/storage_service.dart';
import '../../../data/remote/supabase/supabase_client.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';
import 'community_feed_providers.dart';
import 'community_moderation_providers.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CreatePostState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const CreatePostState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  CreatePostState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return CreatePostState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState();

  Future<void> createPost({
    required String content,
    CommunityPostType postType = CommunityPostType.general,
    String? title,
    List<String> tags = const [],
    List<XFile> images = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') {
        state = state.copyWith(
          isLoading: false,
          error: 'community.not_authenticated'.tr(),
        );
        return;
      }

      // Content moderation check (Apple Guideline 1.2)
      final moderationService = ref.read(contentModerationServiceProvider);
      final textToCheck = [
        if (title != null && title.trim().isNotEmpty) title.trim(),
        content.trim(),
      ].join(' ');
      final modResult = await moderationService.checkText(textToCheck);
      if (!modResult.isAllowed) {
        state = state.copyWith(
          isLoading: false,
          error: ContentModerationService.localizedError(
              modResult.rejectionReason),
        );
        return;
      }

      final postId = const Uuid().v4();
      final imageUrls = <String>[];

      // Upload images
      if (images.isNotEmpty) {
        final client = ref.read(supabaseClientProvider);
        final storageService = StorageService(client);
        for (final image in images) {
          final url = await storageService.uploadCommunityPhoto(
            userId: userId,
            postId: postId,
            file: image,
          );
          imageUrls.add(url);
        }
      }

      final data = <String, dynamic>{
        'id': postId,
        'user_id': userId,
        'content': content.trim(),
        'post_type': postType.toJson(),
        'is_deleted': false,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (tags.isNotEmpty) 'tags': tags,
        if (imageUrls.isNotEmpty) 'image_url': imageUrls.first,
        if (imageUrls.length > 1) 'images': imageUrls,
      };

      final repo = ref.read(communityPostRepositoryProvider);
      await repo.create(data);

      ref.read(communityFeedProvider.notifier).refresh();

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('CreatePostNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const CreatePostState();
}

final createPostProvider =
    NotifierProvider<CreatePostNotifier, CreatePostState>(
        CreatePostNotifier.new);
