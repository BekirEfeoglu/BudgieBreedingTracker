import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // Set when the session needs a fresh TOTP challenge before the password
  // update can proceed (MFA-enrolled, but the password reauth above reset
  // the session to AAL1). The UI must show an MFA challenge for this
  // factor, then call `completeAfterMfaChallenge`/`cancelMfaChallenge`.
  final String? mfaFactorId;

  const PasswordChangeState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.mfaFactorId,
  });

  PasswordChangeState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? mfaFactorId,
  }) => PasswordChangeState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
    mfaFactorId: mfaFactorId,
  );
}

class PasswordChangeNotifier extends Notifier<PasswordChangeState>
    with SentryErrorFilter {
  @override
  PasswordChangeState build() => const PasswordChangeState();

  // Held only in-memory for the duration of an MFA-challenge round trip;
  // never persisted. Cleared as soon as it's consumed or the challenge is
  // cancelled.
  String? _pendingNewPassword;

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
    } on MfaAssuranceRequiredException {
      final factorId = await _enrolledFactorId();
      if (factorId == null) {
        // Shouldn't happen — the exception only fires when a verified
        // factor exists — but fail with a visible error instead of
        // silently doing nothing if the factor list is empty by the time
        // we check.
        AppLogger.warning(
          '[PasswordChange] MFA required but no enrolled factor found',
        );
        state = state.copyWith(
          isLoading: false,
          error: 'profile.password_change_error',
        );
        return;
      }
      _pendingNewPassword = newPassword;
      state = state.copyWith(isLoading: false, mfaFactorId: factorId);
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

  Future<String?> _enrolledFactorId() async {
    final factors = await ref.read(twoFactorServiceProvider).getFactors();
    for (final factor in factors) {
      if (factor.status == FactorStatus.verified) return factor.id;
    }
    return null;
  }

  /// Completes the password change after the caller has verified an MFA
  /// challenge for `state.mfaFactorId` (via `showMfaChallengeDialog`).
  Future<void> completeAfterMfaChallenge() async {
    final newPassword = _pendingNewPassword;
    if (newPassword == null) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final authActions = ref.read(authActionsProvider);
      await authActions.changePasswordForVerifiedSession(
        newPassword: newPassword,
      );
      _pendingNewPassword = null;
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error(
        '[PasswordChange] Failed to complete after MFA challenge',
        e,
        st,
      );
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'profile.password_change_error',
      );
    }
  }

  /// Call when the user dismisses the MFA challenge dialog without
  /// completing it.
  void cancelMfaChallenge() {
    _pendingNewPassword = null;
    state = state.copyWith(mfaFactorId: null);
  }

  void reset() {
    _pendingNewPassword = null;
    state = const PasswordChangeState();
  }
}

final passwordChangeStateProvider =
    NotifierProvider<PasswordChangeNotifier, PasswordChangeState>(
      PasswordChangeNotifier.new,
    );
