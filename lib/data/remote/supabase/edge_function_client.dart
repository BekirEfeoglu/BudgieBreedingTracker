import 'dart:convert';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Result of an Edge Function invocation.
class EdgeFunctionResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  const EdgeFunctionResult({required this.success, this.data, this.error});

  factory EdgeFunctionResult.fromResponse(FunctionResponse response) {
    if (response.status >= 200 && response.status < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return EdgeFunctionResult(success: true, data: body);
      }
      if (body is String) {
        try {
          final parsed = json.decode(body) as Map<String, dynamic>;
          return EdgeFunctionResult(success: true, data: parsed);
        } catch (_) {
          return EdgeFunctionResult(success: true, data: {'response': body});
        }
      }
      return const EdgeFunctionResult(success: true, data: {});
    }
    return EdgeFunctionResult(
      success: false,
      error: 'Status ${response.status}: ${response.data}',
    );
  }

  factory EdgeFunctionResult.failure(String error) =>
      EdgeFunctionResult(success: false, error: error);
}

/// Client for invoking Supabase Edge Functions.
///
/// Includes per-function rate limiting to prevent abuse of expensive
/// server-side operations (genetics calculation, report generation, etc.).
class EdgeFunctionClient {
  final SupabaseClient _client;
  static const _tag = '[EdgeFunctionClient]';

  /// Minimum interval between calls to the same Edge Function.
  static const _defaultCooldown = Duration(seconds: 10);

  /// Edge Functions exempt from rate limiting (need rapid sequential calls).
  static const _rateLimitExempt = {'mfa-lockout', 'send-push'};

  /// Per-function last invocation timestamps for rate limiting.
  final Map<String, DateTime> _lastInvocationAt = {};

  EdgeFunctionClient(this._client);

  /// Invoke an Edge Function by name.
  ///
  /// Automatically includes the current user's JWT in the Authorization
  /// header for authenticated access. Custom [headers] are merged on top.
  Future<EdgeFunctionResult> invoke(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      // Enforce per-function rate limiting (skip for exempt functions)
      final lastCall = _lastInvocationAt[functionName];
      if (!_rateLimitExempt.contains(functionName) &&
          lastCall != null &&
          DateTime.now().difference(lastCall) < _defaultCooldown) {
        AppLogger.warning('$_tag Rate limited: $functionName');
        return EdgeFunctionResult.failure(
          'Rate limited: please wait before retrying',
        );
      }

      AppLogger.info('$_tag Invoking: $functionName');

      // Proactively refresh session if token is expired or about to expire.
      // BUG in supabase-dart: _handleTokenChanged updates realtime.setAuth()
      // but does NOT call functions.setAuth(), so the FunctionsClient keeps
      // the stale token in its _headers after a token refresh.
      // Workaround: always pass a fresh Authorization header explicitly.
      final session = _client.auth.currentSession;
      if (session?.expiresAt != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          session!.expiresAt! * 1000,
        );
        if (expiresAt.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
          AppLogger.info('$_tag Refreshing expired session before $functionName');
          await _client.auth.refreshSession();
        }
      }

      // Get the LATEST access token (after potential refresh) and pass it
      // explicitly — custom headers override FunctionsClient._headers.
      final accessToken = _client.auth.currentSession?.accessToken;
      if (accessToken == null) {
        AppLogger.warning('$_tag No authenticated session for $functionName');
        return EdgeFunctionResult.failure('No authenticated session');
      }

      final authHeaders = <String, String>{
        'Authorization': 'Bearer $accessToken',
        ...?headers,
      };

      final response = await _client.functions.invoke(
        functionName,
        body: body,
        headers: authHeaders,
      );

      final result = EdgeFunctionResult.fromResponse(response);

      _lastInvocationAt[functionName] = DateTime.now();

      if (result.success) {
        AppLogger.info('$_tag $functionName completed successfully');
      } else {
        AppLogger.warning('$_tag $functionName failed: ${result.error}');
      }

      return result;
    } on FunctionException catch (e, st) {
      if (e.status == 404 && functionName == 'system-health') {
        AppLogger.warning(
          '$_tag $functionName not deployed (404), treating as unavailable',
        );
      } else {
        AppLogger.error('$_tag Error invoking $functionName', e, st);
        Sentry.captureException(e, stackTrace: st);
      }
      return EdgeFunctionResult.failure(e.toString());
    } catch (e, st) {
      AppLogger.error('$_tag Error invoking $functionName', e, st);
      Sentry.captureException(e, stackTrace: st);
      return EdgeFunctionResult.failure(e.toString());
    }
  }

  /// Invoke the genetics calculation Edge Function.
  Future<EdgeFunctionResult> calculateGenetics({
    required List<String> fatherMutations,
    required List<String> motherMutations,
  }) {
    return invoke(
      'calculate-genetics',
      body: {
        'father_mutations': fatherMutations,
        'mother_mutations': motherMutations,
      },
    );
  }

  /// Invoke the report generation Edge Function.
  ///
  /// The Edge Function extracts the user ID from the JWT token
  /// (server-side) to prevent IDOR attacks. Do NOT send userId in body.
  Future<EdgeFunctionResult> generateReport({
    required String reportType,
    Map<String, dynamic>? options,
  }) {
    return invoke(
      'generate-report',
      body: {
        'report_type': reportType,
        if (options != null) 'options': options,
      },
    );
  }

  /// Invoke the system health check Edge Function.
  Future<EdgeFunctionResult> checkSystemHealth() {
    return invoke('system-health');
  }

  /// Invoke the image safety scan Edge Function.
  ///
  /// Sends a base64-encoded image to a server-side vision API for content
  /// safety analysis. Returns `{ "safe": true/false, "reason": "..." }`.
  /// Falls back to safe (allowed) if the edge function is unavailable.
  Future<EdgeFunctionResult> scanImageSafety({
    required String imageBase64,
    required String mimeType,
  }) {
    return invoke(
      'scan-image-safety',
      body: {'image_base64': imageBase64, 'mime_type': mimeType},
    );
  }

  /// Send a push notification via FCM to one or more users.
  ///
  /// Resolves FCM tokens server-side from [userIds] and delivers
  /// push notifications through Firebase Cloud Messaging.
  /// Returns `{ success: N, failure: N, results: [...] }`.
  Future<EdgeFunctionResult> sendPush({
    List<String>? userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return invoke(
      'send-push',
      body: {
        if (userIds != null) 'userIds': userIds,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      },
    );
  }

  /// Check if the current user is locked out of MFA verification.
  ///
  /// Returns `{ locked: bool, remaining_seconds: int }`.
  Future<EdgeFunctionResult> checkMfaLockout() {
    return invoke('mfa-lockout', body: {'action': 'check'});
  }

  /// Record a failed MFA verification attempt.
  ///
  /// Increments server-side counter and triggers lockout at 5 attempts.
  Future<EdgeFunctionResult> recordMfaFailure() {
    return invoke('mfa-lockout', body: {'action': 'record-failure'});
  }

  /// Reset MFA lockout state after successful verification.
  Future<EdgeFunctionResult> resetMfaLockout() {
    return invoke('mfa-lockout', body: {'action': 'reset'});
  }
}
