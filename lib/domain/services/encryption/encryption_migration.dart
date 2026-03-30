part of 'encryption_service.dart';

// ---------------------------------------------------------------------------
// Batch re-encryption, payload audit, and Sentry reporting helpers.
// These are extension methods on [EncryptionService] accessible within
// the library via the `part` directive.
// ---------------------------------------------------------------------------

/// Heuristic check: encrypted values are Base64-encoded and at least
/// 17 bytes decoded (IV + 1 byte cipher minimum). Plain text ring
/// numbers like "TR-2024-001" are much shorter when decoded and
/// typically fail Base64 decoding altogether.
bool looksLikeEncrypted(String value) {
  if (value.isEmpty) return false;
  try {
    final decoded = base64Decode(value);
    return decoded.length >= 17; // IV(16) + at least 1 byte ciphertext
  } catch (_) {
    return false;
  }
}

extension EncryptionMigration on EncryptionService {
  /// Audits a list of encrypted payloads and returns format statistics.
  ///
  /// Inspects each value's magic prefix to classify it as `current`
  /// (BBTENC1! authenticated), `legacy` (IV+ciphertext only), or `invalid`.
  /// No decryption is performed — this is a cheap, read-only scan.
  ({int current, int legacy, int invalid}) auditPayloads(
    List<String> encryptedValues,
  ) {
    var current = 0;
    var legacy = 0;
    var invalid = 0;
    for (final value in encryptedValues) {
      if (value.isEmpty) {
        invalid++;
        continue;
      }
      try {
        final combined = base64Decode(value);
        if (_hasMagicPrefix(combined)) {
          current++;
        } else {
          legacy++;
        }
      } catch (_) {
        invalid++;
      }
    }
    return (current: current, legacy: legacy, invalid: invalid);
  }

  /// Maximum number of payloads to re-encrypt in a single batch call.
  ///
  /// Prevents sync timeout when migrating large datasets. Callers should
  /// invoke [batchReEncrypt] repeatedly until no more legacy payloads remain.
  static const int _batchChunkSize = 50;

  /// Re-encrypts a batch of values, upgrading legacy and pre-separation
  /// payloads to the current derived-key authenticated format.
  ///
  /// Processes at most [_batchChunkSize] legacy payloads per call to
  /// prevent sync timeout on large datasets. Returns a map of
  /// `id → reEncryptedValue` for values that were successfully upgraded.
  /// Entries that are already current-format or that fail decryption
  /// are omitted from the result.
  ///
  /// Use [auditPayloads] first to estimate the total batch size.
  Future<Map<String, String>> batchReEncrypt(
    Map<String, String> idToCipherText,
  ) async {
    final results = <String, String>{};
    var processed = 0;
    for (final entry in idToCipherText.entries) {
      if (!needsReEncryption(entry.value)) continue;
      if (processed >= _batchChunkSize) {
        AppLogger.info(
          'Batch re-encryption: chunk limit reached ($_batchChunkSize), '
          '${idToCipherText.length - results.length} remaining',
        );
        break;
      }
      final upgraded = await reEncrypt(entry.value);
      if (upgraded != null) {
        results[entry.key] = upgraded;
      }
      processed++;
    }
    if (results.isNotEmpty) {
      AppLogger.info(
        'Batch re-encryption: ${results.length}/${idToCipherText.length} '
        'payloads upgraded to current format',
      );
    }
    return results;
  }

  /// Audits encrypted payloads and reports format distribution to Sentry.
  ///
  /// Sends a Sentry event only when legacy or invalid payloads are found,
  /// to avoid noise from healthy states. Returns the audit result for
  /// callers that need it (e.g., SyncOrchestrator migration step).
  ({int current, int legacy, int invalid}) auditAndReport(
    List<String> encryptedValues, {
    String source = 'unknown',
  }) {
    final result = auditPayloads(encryptedValues);
    if (result.legacy > 0 || result.invalid > 0) {
      Sentry.captureMessage(
        'Encryption payload audit: ${result.legacy} legacy, '
        '${result.invalid} invalid out of ${encryptedValues.length} total',
        level: SentryLevel.info,
        params: [
          'current:${result.current}',
          'legacy:${result.legacy}',
          'invalid:${result.invalid}',
          'source:$source',
        ],
      );
      AppLogger.info(
        '[EncryptionMigration] Audit ($source): '
        '${result.current} current, ${result.legacy} legacy, '
        '${result.invalid} invalid',
      );
    }
    return result;
  }
}
