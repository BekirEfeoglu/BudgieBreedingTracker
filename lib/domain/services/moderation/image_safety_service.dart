import 'dart:convert';
import 'dart:typed_data';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';

/// Result of an image safety scan.
class ImageSafetyResult {
  final bool isSafe;
  final String? rejectionReason;

  const ImageSafetyResult({
    required this.isSafe,
    this.rejectionReason,
  });

  const ImageSafetyResult.safe()
    : isSafe = true,
      rejectionReason = null;
  const ImageSafetyResult.unsafe(String reason)
    : isSafe = false,
      rejectionReason = reason;
}

/// Service that checks images for objectionable content before upload.
///
/// Uses a server-side Edge Function (`scan-image-safety`) that delegates
/// to a vision API (e.g. Google Cloud Vision SafeSearch, AWS Rekognition).
///
/// Fail-closed: if the edge function is unavailable, uploads are rejected.
/// Apple App Store Guideline 1.2 requires UGC content filtering.
class ImageSafetyService {
  final EdgeFunctionClient? _edgeFunctionClient;
  static const _tag = '[ImageSafety]';

  /// Maximum image size to scan (2 MB base64). Larger images are rejected.
  static const _maxScanSizeBytes = 2 * 1024 * 1024;

  const ImageSafetyService({EdgeFunctionClient? edgeFunctionClient})
    : _edgeFunctionClient = edgeFunctionClient;

  /// Scans image bytes for objectionable content.
  ///
  /// Returns [ImageSafetyResult.safe] if the image passes scanning.
  /// Returns [ImageSafetyResult.unsafe] with a reason if the image is
  /// flagged or scanning is unavailable (fail-closed for App Store compliance).
  Future<ImageSafetyResult> scanImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (_edgeFunctionClient == null) {
      // Fail-closed: reject when image safety scanning is unavailable
      // to prevent potentially objectionable content from being uploaded.
      AppLogger.warning(
        '$_tag Edge function client unavailable, rejecting image upload',
      );
      return const ImageSafetyResult.unsafe('safety_scan_unavailable');
    }

    // Large images cannot be sent to the edge function due to payload limits.
    // Reject to prevent bypassing safety checks with oversized images.
    if (bytes.length > _maxScanSizeBytes) {
      AppLogger.warning(
        '$_tag Image too large for scanning (${bytes.length} bytes), '
        'rejecting upload',
      );
      return const ImageSafetyResult.unsafe('image_too_large');
    }

    try {
      final base64Image = base64Encode(bytes);

      final result = await _edgeFunctionClient.scanImageSafety(
        imageBase64: base64Image,
        mimeType: mimeType,
      );

      if (!result.success) {
        // Edge function unavailable — fail-closed.
        AppLogger.warning(
          '$_tag Edge function unavailable, rejecting image upload',
        );
        return const ImageSafetyResult.unsafe('safety_scan_unavailable');
      }

      final isSafe = result.data?['safe'] as bool? ?? true;
      if (!isSafe) {
        final reason = result.data?['reason'] as String? ?? 'image_flagged';
        AppLogger.info('$_tag Image flagged: $reason');
        return ImageSafetyResult.unsafe(reason);
      }

      return const ImageSafetyResult.safe();
    } catch (e, st) {
      // On error, reject upload (fail-closed).
      AppLogger.error('$_tag Image safety scan failed', e, st);
      return const ImageSafetyResult.unsafe('safety_scan_unavailable');
    }
  }
}
