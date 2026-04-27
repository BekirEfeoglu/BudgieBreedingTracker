part of 'auth_actions.dart';

/// Maps Supabase [AuthException] messages to localized translation keys.
///
/// Supabase returns English error messages; this converts them to
/// user-friendly localized strings via easy_localization keys.
///
/// gotrue-dart wraps ALL HTTP-level failures as [AuthRetryableFetchException]
/// with statusCode == null (no statusCode passed). API errors (4xx) have a
/// non-null statusCode. 5xx server errors also have a statusCode string.
/// Therefore, statusCode == null is the most reliable indicator of a
/// network-level failure (SocketException, HandshakeException, DNS, TLS, etc.)
/// regardless of platform (iOS / Android).
String mapAuthError(AuthException e) {
  final msg = e.message.toLowerCase();

  // Auth-specific errors (check BEFORE network, they always have a statusCode)
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials')) {
    return 'auth.error_invalid_credentials'.tr();
  }
  if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
    return 'auth.error_email_not_confirmed'.tr();
  }
  if (msg.contains('rate limit') || msg.contains('too many requests')) {
    return 'auth.error_too_many_requests'.tr();
  }
  if (msg.contains('already registered') ||
      msg.contains('user already registered')) {
    // Return generic message to prevent user enumeration attacks.
    // Attacker should not learn whether an email is registered.
    return 'auth.error_registration_failed'.tr();
  }
  if (msg.contains('weak password') || msg.contains('password should be')) {
    return 'auth.error_weak_password'.tr();
  }
  if (msg.contains('anonymous') &&
      (msg.contains('disabled') || msg.contains('not allowed'))) {
    return 'auth.error_anonymous_disabled'.tr();
  }
  if (msg.contains('signups not allowed') ||
      msg.contains('sign up not allowed') ||
      msg.contains('signup is disabled')) {
    return 'auth.error_anonymous_disabled'.tr();
  }
  if (msg.contains('not configured') ||
      msg.contains('google sign-in failed') ||
      msg.contains('apple sign-in failed')) {
    return 'auth.error_oauth_unavailable'.tr();
  }

  // Network / connectivity errors.
  // Primary heuristic: gotrue sets statusCode = null for all network-level
  // failures (fetch.dart catch block → AuthRetryableFetchException without
  // statusCode). API and server errors always have a non-null statusCode.
  final isNetworkByStatusCode = e.statusCode == null;

  // Secondary heuristic: message pattern matching for common dart:io errors.
  // iOS typically raises HandshakeException, OS Error, errno messages.
  // Android typically raises SocketException. Both are wrapped by gotrue.
  final isNetworkByMessage =
      msg.contains('network') ||
      msg.contains('connection') ||
      msg.contains('socket') ||
      msg.contains('timeout') ||
      msg.contains('host lookup') ||
      msg.contains('failed to connect') ||
      msg.contains('handshake') || // iOS TLS/SSL failures
      msg.contains('tls') || // TLS-level errors
      msg.contains('certificate') || // Certificate validation failures
      msg.contains('os error') || // dart:io OS-level errors (iOS)
      msg.contains('no route') || // No route to host
      msg.contains('unreachable') || // Network unreachable
      msg.contains('errno') || // Low-level errno messages
      msg.contains('clientexception') || // dart:io ClientException
      msg.contains('connection refused'); // Connection refused errors

  if (isNetworkByStatusCode || isNetworkByMessage) {
    return 'auth.error_network'.tr();
  }

  // 5xx server errors have a statusCode but indicate backend unavailability.
  final statusCode = int.tryParse(e.statusCode ?? '');
  if (statusCode != null && statusCode >= 500) {
    return 'auth.error_service_unavailable'.tr();
  }

  return 'auth.error_unknown'.tr();
}

bool isInvalidCredentialsAuthError(Object error) {
  if (error is! AuthException) return false;
  final msg = error.message.toLowerCase();
  return msg.contains('invalid') || msg.contains('credentials');
}
