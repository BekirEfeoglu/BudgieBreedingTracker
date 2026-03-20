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
class EdgeFunctionClient {
  final SupabaseClient _client;
  static const _tag = '[EdgeFunctionClient]';

  const EdgeFunctionClient(this._client);

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
      AppLogger.info('$_tag Invoking: $functionName');

      // Auto-include JWT for authenticated Edge Function calls
      final mergedHeaders = <String, String>{};
      final accessToken = _client.auth.currentSession?.accessToken;
      if (accessToken != null) {
        mergedHeaders['Authorization'] = 'Bearer $accessToken';
      }
      if (headers != null) mergedHeaders.addAll(headers);

      final response = await _client.functions.invoke(
        functionName,
        body: body,
        headers: mergedHeaders.isNotEmpty ? mergedHeaders : null,
      );

      final result = EdgeFunctionResult.fromResponse(response);

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
  Future<EdgeFunctionResult> generateReport({
    required String userId,
    required String reportType,
    Map<String, dynamic>? options,
  }) {
    return invoke(
      'generate-report',
      body: {
        'user_id': userId,
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
}
