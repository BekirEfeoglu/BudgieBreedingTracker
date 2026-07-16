import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';

/// Client-side raw image size guard used after picker resize/compression.
///
/// Rejects images that exceed the upload limit before the upload pipeline reads
/// the full bytes. Without this guard, on low-bandwidth connections users would
/// wait for the upload to start, only to be rejected after the server-side limit
/// check.
///
/// Scanned uploads default to the same 2 MiB raw-byte contract enforced by
/// StorageService, marketplace, Supabase Storage, and the moderation Edge
/// Functions. Picker resize/quality is best-effort and cannot guarantee a file
/// size, so this post-picker check remains required. Server-side size
/// enforcement is authoritative; the client-side check is UX-only.
abstract final class ImagePickerGuard {
  /// Returns true if [file] is within the size limit; otherwise shows a
  /// localized snackbar via [context] and returns false.
  ///
  /// Safe to call after `await`; rechecks `context.mounted` before touching
  /// the navigator.
  static Future<bool> ensureWithinSizeLimit(
    BuildContext context,
    XFile file, {
    int maxBytes = AppConstants.maxScannedImageBytes,
  }) async {
    final bytes = await file.length();
    if (bytes <= maxBytes) return true;
    if (!context.mounted) return false;

    final mb = maxBytes ~/ (1024 * 1024);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('errors.image_too_large'.tr(args: ['$mb']))),
    );
    return false;
  }

  /// Variant that reports via a pre-captured [messenger] instead of a
  /// [BuildContext]. Use from flows that pop their own route before the async
  /// pick resolves (e.g. a bottom-sheet picker): by then the widget's own
  /// context is unmounted, so a context-based guard silently no-ops. The
  /// caller must capture `ScaffoldMessenger.of(context)` before popping.
  static Future<bool> ensureWithinSizeLimitVia(
    ScaffoldMessengerState messenger,
    XFile file, {
    int maxBytes = AppConstants.maxScannedImageBytes,
  }) async {
    final bytes = await file.length();
    if (bytes <= maxBytes) return true;

    final mb = maxBytes ~/ (1024 * 1024);
    messenger.showSnackBar(
      SnackBar(content: Text('errors.image_too_large'.tr(args: ['$mb']))),
    );
    return false;
  }

  /// Filters [files] to only those within the size limit. Shows a single
  /// snackbar via [context] when any file is rejected. Returns the surviving
  /// files in their original order.
  static Future<List<XFile>> filterWithinSizeLimit(
    BuildContext context,
    List<XFile> files, {
    int maxBytes = AppConstants.maxScannedImageBytes,
  }) async {
    final accepted = <XFile>[];
    var rejectedAny = false;
    for (final file in files) {
      final bytes = await file.length();
      if (bytes <= maxBytes) {
        accepted.add(file);
      } else {
        rejectedAny = true;
      }
    }
    if (rejectedAny && context.mounted) {
      final mb = maxBytes ~/ (1024 * 1024);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.image_too_large'.tr(args: ['$mb']))),
      );
    }
    return accepted;
  }
}
