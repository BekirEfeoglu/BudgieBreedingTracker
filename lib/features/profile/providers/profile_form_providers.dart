import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/sentry_error_filter.dart';
import '../../../data/remote/api/remote_source_providers.dart';
import '../../../data/remote/storage/storage_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_providers.dart';

// ---------------------------------------------------------------------------
// Avatar Upload
// ---------------------------------------------------------------------------

class AvatarUploadState {
  final bool isUploading;
  final String? error;
  final bool isSuccess;

  const AvatarUploadState({
    this.isUploading = false,
    this.error,
    this.isSuccess = false,
  });

  AvatarUploadState copyWith({
    bool? isUploading,
    String? error,
    bool? isSuccess,
  }) => AvatarUploadState(
    isUploading: isUploading ?? this.isUploading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

class AvatarUploadNotifier extends Notifier<AvatarUploadState>
    with SentryErrorFilter {
  @override
  AvatarUploadState build() => const AvatarUploadState();

  /// Upload an avatar image file.
  Future<void> uploadAvatar(XFile file) async {
    state = state.copyWith(isUploading: true, error: null, isSuccess: false);
    try {
      final userId = ref.read(currentUserIdProvider);
      final storageService = ref.read(storageServiceProvider);
      final profileRepo = ref.read(profileRepositoryProvider);

      // Upload to Supabase Storage
      final avatarUrl = await storageService.uploadAvatar(
        userId: userId,
        file: file,
      );

      // Update profile with new avatar URL
      final profile = await profileRepo.getById(userId);
      if (profile != null) {
        await profileRepo.save(profile.copyWith(avatarUrl: avatarUrl));
      }

      // Invalidate community profile cache so updated avatar shows immediately
      ref.read(communityProfileCacheProvider).invalidate(userId);

      state = state.copyWith(isUploading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('[AvatarUpload] Failed to upload avatar', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Remove the current avatar.
  Future<void> removeAvatar() async {
    state = state.copyWith(isUploading: true, error: null, isSuccess: false);
    try {
      final userId = ref.read(currentUserIdProvider);
      final storageService = ref.read(storageServiceProvider);
      final profileRepo = ref.read(profileRepositoryProvider);

      // Delete from storage
      await storageService.deleteAvatar(userId: userId);

      // Clear avatar URL on profile
      final profile = await profileRepo.getById(userId);
      if (profile != null) {
        await profileRepo.save(profile.copyWith(avatarUrl: null));
      }

      // Invalidate community profile cache so removed avatar reflects immediately
      ref.read(communityProfileCacheProvider).invalidate(userId);

      state = state.copyWith(isUploading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('[AvatarUpload] Failed to remove avatar', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  void reset() => state = const AvatarUploadState();
}

final avatarUploadStateProvider =
    NotifierProvider<AvatarUploadNotifier, AvatarUploadState>(
      AvatarUploadNotifier.new,
    );

// ---------------------------------------------------------------------------
// Password Change
// ---------------------------------------------------------------------------

class PasswordChangeState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const PasswordChangeState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  PasswordChangeState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) => PasswordChangeState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

class PasswordChangeNotifier extends Notifier<PasswordChangeState>
    with SentryErrorFilter {
  @override
  PasswordChangeState build() => const PasswordChangeState();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final authActions = ref.read(authActionsProvider);
      await authActions.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      AppLogger.warning('[PasswordChange] AuthException: ${e.message}');
      final msg = e.message.toLowerCase();
      // Error keys are localized by the consuming widget via .tr()
      final errorKey = msg.contains('invalid') || msg.contains('credentials')
          ? 'profile.password_incorrect'
          : 'profile.password_change_error';
      state = state.copyWith(isLoading: false, error: errorKey);
    } catch (e, st) {
      AppLogger.error('[PasswordChange] Failed to change password', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'profile.password_change_error');
    }
  }

  void reset() => state = const PasswordChangeState();
}

final passwordChangeStateProvider =
    NotifierProvider<PasswordChangeNotifier, PasswordChangeState>(
      PasswordChangeNotifier.new,
    );
