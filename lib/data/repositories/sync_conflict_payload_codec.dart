import 'dart:convert';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

/// Sanitized conflict-payload codec failure.
///
/// The exception deliberately carries no original payload/error so callers can
/// log or report its code without leaking user fields to logs or Sentry.
class SyncConflictPayloadException implements Exception {
  const SyncConflictPayloadException(this.code);

  final String code;

  @override
  String toString() => 'SyncConflictPayloadException($code)';
}

/// Versioned, authenticated encryption codec for conflict snapshots.
class SyncConflictPayloadCodec {
  SyncConflictPayloadCodec(this._encryptionService);

  final EncryptionService _encryptionService;

  static const int currentVersion = 1;

  /// Per-snapshot plaintext envelope cap. With local+server snapshots and the
  /// 30-day retention policy, this bounds conflict-history storage growth
  /// while remaining well above normal entity payload sizes.
  static const int maxSnapshotBytes = 64 * 1024;

  Future<String> encode({
    required String tableName,
    required String recordId,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      _validatePayloadIdentity(
        payload: payload,
        recordId: recordId,
        userId: userId,
      );
      final plainText = jsonEncode({
        'version': currentVersion,
        'table_name': tableName,
        'record_id': recordId,
        'user_id': userId,
        'payload': payload,
      });
      if (utf8.encode(plainText).length > maxSnapshotBytes) {
        throw const SyncConflictPayloadException('payload_too_large');
      }
      return await _encryptionService.encrypt(plainText);
    } on SyncConflictPayloadException {
      rethrow;
    } catch (_) {
      throw const SyncConflictPayloadException('payload_encode_failed');
    }
  }

  Future<Map<String, dynamic>> decode({
    required String encryptedPayload,
    required int payloadVersion,
    required String tableName,
    required String recordId,
    required String userId,
  }) async {
    try {
      if (payloadVersion != currentVersion) {
        throw const SyncConflictPayloadException('unsupported_payload_version');
      }
      final plainText = await _encryptionService.decrypt(encryptedPayload);
      if (utf8.encode(plainText).length > maxSnapshotBytes) {
        throw const SyncConflictPayloadException('payload_too_large');
      }
      final decoded = jsonDecode(plainText);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != currentVersion ||
          decoded['table_name'] != tableName ||
          decoded['record_id'] != recordId ||
          decoded['user_id'] != userId ||
          decoded['payload'] is! Map<String, dynamic>) {
        throw const SyncConflictPayloadException('payload_identity_mismatch');
      }
      final payload = Map<String, dynamic>.from(
        decoded['payload'] as Map<String, dynamic>,
      );
      _validatePayloadIdentity(
        payload: payload,
        recordId: recordId,
        userId: userId,
      );
      return payload;
    } on SyncConflictPayloadException {
      rethrow;
    } catch (_) {
      throw const SyncConflictPayloadException('payload_decode_failed');
    }
  }

  void _validatePayloadIdentity({
    required Map<String, dynamic> payload,
    required String recordId,
    required String userId,
  }) {
    if (payload[SupabaseConstants.colId] != recordId ||
        payload[SupabaseConstants.colUserId] != userId) {
      throw const SyncConflictPayloadException('payload_identity_mismatch');
    }
  }
}
