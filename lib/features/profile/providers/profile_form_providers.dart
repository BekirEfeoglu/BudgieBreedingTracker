import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/sentry_error_filter.dart';
import '../../../data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';

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
    if (state.isUploading) return;
    state = state.copyWith(isUploading: true, error: null, isSuccess: false);
    try {
      final userId = ref.read(currentUserIdProvider);
      final profileRepo = ref.read(profileRepositoryProvider);

      await profileRepo.uploadAvatar(userId: userId, file: file);

      state = state.copyWith(isUploading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('[AvatarUpload] Failed to upload avatar', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  /// Remove the current avatar.
  Future<void> removeAvatar() async {
    if (state.isUploading) return;
    state = state.copyWith(isUploading: true, error: null, isSuccess: false);
    try {
      final userId = ref.read(currentUserIdProvider);
      final profileRepo = ref.read(profileRepositoryProvider);

      await profileRepo.removeAvatar(userId);

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
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final authActions = ref.read(authActionsProvider);
      await authActions.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      final isInvalidCredentials = isInvalidCredentialsAuthError(e);
      if (isInvalidCredentials) {
        AppLogger.warning('[PasswordChange] Invalid current password');
      } else {
        AppLogger.error('[PasswordChange] Failed to change password', e, st);
        reportIfUnexpected(e, st);
      }
      state = state.copyWith(
        isLoading: false,
        error: isInvalidCredentials
            ? 'profile.password_incorrect'
            : 'profile.password_change_error',
      );
    }
  }

  void reset() => state = const PasswordChangeState();
}

final passwordChangeStateProvider =
    NotifierProvider<PasswordChangeNotifier, PasswordChangeState>(
      PasswordChangeNotifier.new,
    );
