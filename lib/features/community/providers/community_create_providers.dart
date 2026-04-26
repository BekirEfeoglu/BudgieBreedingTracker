import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/community_post_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';
import 'community_feed_providers.dart';
import '../../../domain/services/moderation/moderation_providers.dart';

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

  CreatePostState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
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
  /// Minimum interval between post creations to prevent spam.
  static const _postCooldown = Duration(seconds: 30);
  DateTime? _lastPostAt;

  @override
  CreatePostState build() => const CreatePostState();

  Future<void> createPost({
    required String content,
    CommunityPostType postType = CommunityPostType.general,
    String? title,
    List<String> tags = const [],
    List<XFile> images = const [],
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    final imageUrls = <String>[];

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') {
        state = state.copyWith(
          isLoading: false,
          error: 'community.not_authenticated'.tr(),
        );
        return;
      }

      // Client-side throttle — prevent rapid post creation
      final now = DateTime.now();
      if (_lastPostAt != null && now.difference(_lastPostAt!) < _postCooldown) {
        state = state.copyWith(
          isLoading: false,
          error: 'community.post_cooldown'.tr(),
        );
        return;
      }

      // Content length validation (server-consistent limits)
      const maxTitleLength = 200;
      const maxContentLength = 5000;
      if (title != null && title.trim().length > maxTitleLength) {
        state = state.copyWith(
          isLoading: false,
          error: 'community.content_too_long'.tr(),
        );
        return;
      }
      if (content.trim().length > maxContentLength) {
        state = state.copyWith(
          isLoading: false,
          error: 'community.content_too_long'.tr(),
        );
        return;
      }

      // Server-side guard: account age, rate limit, spam dedup
      final contentHash = md5.convert(utf8.encode(content.trim())).toString();
      final repo = ref.read(communityPostRepositoryProvider);
      try {
        final guardResult = await repo.checkPostAllowed(contentHash);
        if (guardResult['allowed'] != true) {
          final reason = guardResult['reason'] as String? ?? 'unknown';
          state = state.copyWith(
            isLoading: false,
            error: 'community.post_guard_$reason'.tr(),
          );
          return;
        }
      } catch (e, st) {
        // Non-fatal: if guard RPC fails (e.g. offline), allow post through
        // — client-side throttle and moderation still apply.
        AppLogger.warning('Community post guard RPC failed, continuing: $e');
        Sentry.captureException(e, stackTrace: st);
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
            modResult.rejectionReason,
          ),
        );
        return;
      }
      final postId = const Uuid().v7();

      // Scan every image before any upload so a later rejection cannot leave
      // already-uploaded storage files without a post record.
      if (images.isNotEmpty) {
        final imageSafety = ref.read(imageSafetyServiceProvider);

        for (final image in images) {
          final bytes = await image.readAsBytes();
          final mimeType = _getMimeType(image.name);
          final safetyResult = await imageSafety.scanImage(
            bytes: bytes,
            mimeType: mimeType,
          );
          if (!safetyResult.isSafe) {
            state = state.copyWith(
              isLoading: false,
              error: 'community.image_rejected'.tr(),
            );
            return;
          }
        }

        for (final image in images) {
          final url = await repo.uploadPhoto(
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
        'content_hash': contentHash,
        'post_type': postType.toJson(),
        'is_deleted': false,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (tags.isNotEmpty) 'tags': tags,
        if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
      };

      await repo.create(data);

      ref.read(communityFeedProvider.notifier).refresh();
      _lastPostAt = DateTime.now();

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      if (imageUrls.isNotEmpty) {
        final repo = ref.read(communityPostRepositoryProvider);
        await _deleteUploadedImages(repo, imageUrls);
      }
      AppLogger.error('CreatePostNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const CreatePostState();
}

final createPostProvider =
    NotifierProvider<CreatePostNotifier, CreatePostState>(
      CreatePostNotifier.new,
    );

Future<void> _deleteUploadedImages(
  CommunityPostRepository repo,
  List<String> imageUrls,
) async {
  for (final url in imageUrls) {
    try {
      await repo.deleteUploadedPhoto(url);
    } catch (e, st) {
      AppLogger.warning('Failed to clean up community image upload: $e');
      Sentry.captureException(e, stackTrace: st);
    }
  }
}

String _getMimeType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'application/octet-stream',
  };
}
