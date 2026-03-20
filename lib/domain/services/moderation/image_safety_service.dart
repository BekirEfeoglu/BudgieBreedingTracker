import 'dart:convert';
import 'dart:typed_data';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';

/// Result of an image safety scan.
class ImageSafetyResult {
  final bool isSafe;
  final String? rejectionReason;

  /// When `true`, the image was allowed but server-side scanning was
  /// unavailable. The image should be flagged for manual review.
  final bool needsReview;

  const ImageSafetyResult({
    required this.isSafe,
    this.rejectionReason,
    this.needsReview = false,
  });

  const ImageSafetyResult.safe()
    : isSafe = true,
      rejectionReason = null,
      needsReview = false;
  const ImageSafetyResult.unsafe(String reason)
    : isSafe = false,
      rejectionReason = reason,
      needsReview = false;

  /// Image is allowed but should be queued for manual review because
  /// the server-side safety scan could not be performed.
  const ImageSafetyResult.pendingReview()
    : isSafe = true,
      rejectionReason = null,
      needsReview = true;
}

/// Service that checks images for objectionable content before upload.
///
/// Uses a server-side Edge Function (`scan-image-safety`) that delegates
/// to a vision API (e.g. Google Cloud Vision SafeSearch, AWS Rekognition).
///
/// Fail-open: if the edge function is unavailable, uploads are allowed.
/// Apple App Store Guideline 1.2 requires UGC content filtering.
class ImageSafetyService {
  final EdgeFunctionClient? _edgeFunctionClient;
  static const _tag = '[ImageSafety]';

  /// Maximum image size to scan (2 MB base64). Larger images skip scanning.
  static const _maxScanSizeBytes = 2 * 1024 * 1024;

  const ImageSafetyService({EdgeFunctionClient? edgeFunctionClient})
    : _edgeFunctionClient = edgeFunctionClient;

  /// Scans image bytes for objectionable content.
  ///
  /// Returns [ImageSafetyResult.safe] if the image passes or scanning
  /// is unavailable (fail-open). Returns [ImageSafetyResult.unsafe] with
  /// a reason if the image is flagged.
  Future<ImageSafetyResult> scanImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (_edgeFunctionClient == null) {
      // No edge function client — flag for manual review instead of
      // silently allowing.
      return const ImageSafetyResult.pendingReview();
    }

    // Large images cannot be sent to the edge function due to payload limits.
    // Flag for manual review instead of silently allowing.
    if (bytes.length > _maxScanSizeBytes) {
      AppLogger.info(
        '$_tag Image too large for scanning (${bytes.length} bytes), '
        'flagging for review',
      );
      return const ImageSafetyResult.pendingReview();
    }

    try {
      final base64Image = base64Encode(bytes);

      final result = await _edgeFunctionClient.scanImageSafety(
        imageBase64: base64Image,
        mimeType: mimeType,
      );

      if (!result.success) {
        // Edge function unavailable — flag for manual review.
        AppLogger.warning(
          '$_tag Edge function unavailable, flagging for review',
        );
        return const ImageSafetyResult.pendingReview();
      }

      final isSafe = result.data?['safe'] as bool? ?? true;
      if (!isSafe) {
        final reason = result.data?['reason'] as String? ?? 'image_flagged';
        AppLogger.info('$_tag Image flagged: $reason');
        return ImageSafetyResult.unsafe(reason);
      }

      return const ImageSafetyResult.safe();
    } catch (e, st) {
      // On error, allow upload but flag for manual review.
      AppLogger.error('$_tag Image safety scan failed', e, st);
      return const ImageSafetyResult.pendingReview();
    }
  }
}
