import 'package:supabase_flutter/supabase_flutter.dart';

const nativeGoogleSignInNotConfiguredMessage = 'Google sign-in not configured';
const nativeGoogleSignInFailedMessage = 'Google sign-in failed';
const nativeGoogleNoIdTokenMessage = 'No ID Token found for Google Sign In.';
const nativeGoogleNoAccessTokenMessage =
    'No Access Token found for Google Sign In.';

bool shouldFallbackToBrowserGoogleOAuth(AuthException error) {
  return error.message == nativeGoogleSignInNotConfiguredMessage ||
      error.message == nativeGoogleSignInFailedMessage ||
      error.message == nativeGoogleNoIdTokenMessage ||
      error.message == nativeGoogleNoAccessTokenMessage;
}

bool shouldUseNativeGoogleSignIn({required bool isAndroid}) {
  return !isAndroid;
}

LaunchMode resolveOAuthLaunchMode({required bool isAndroid}) {
  if (isAndroid) return LaunchMode.externalApplication;
  return LaunchMode.inAppBrowserView;
}

/// Android Credential Manager can report OAuth client configuration failures
/// as a cancellation, so native Android cancellation is treated as a
/// recoverable native-flow failure and falls back to browser OAuth.
bool shouldTreatNativeGoogleCancelAsUnavailable({
  required bool isAndroid,
  String? description,
  Object? details,
}) {
  if (!isAndroid) return false;

  final message = [
    if (description != null) description,
    if (details != null) details.toString(),
  ].join(' ').toLowerCase();

  if (message.contains('user canceled') ||
      message.contains('user cancelled') ||
      message.contains('canceled by user') ||
      message.contains('cancelled by user')) {
    return false;
  }

  return true;
}
