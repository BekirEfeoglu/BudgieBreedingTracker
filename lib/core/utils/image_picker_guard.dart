import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';

/// Client-side image size guard used by photo pickers.
///
/// Rejects images that exceed [AppConstants.maxUploadSizeBytes] before the
/// upload pipeline reads the full bytes. Without this guard, on low-bandwidth
/// connections users would wait for the upload to start, only to be rejected
/// after the server-side limit check.
///
/// Server-side enforcement (StorageService / marketplace remote source) remains
/// the source of truth — the client-side check is UX-only.
abstract final class ImagePickerGuard {
  /// Returns true if [file] is within the size limit; otherwise shows a
  /// localized snackbar via [context] and returns false.
  ///
  /// Safe to call after `await`; rechecks `context.mounted` before touching
  /// the navigator.
  static Future<bool> ensureWithinSizeLimit(
    BuildContext context,
    XFile file,
  ) async {
    final bytes = await file.length();
    if (bytes <= AppConstants.maxUploadSizeBytes) return true;
    if (!context.mounted) return false;

    const mb = AppConstants.maxUploadSizeBytes ~/ (1024 * 1024);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('errors.image_too_large'.tr(args: ['$mb']))),
    );
    return false;
  }

  /// Filters [files] to only those within the size limit. Shows a single
  /// snackbar via [context] when any file is rejected. Returns the surviving
  /// files in their original order.
  static Future<List<XFile>> filterWithinSizeLimit(
    BuildContext context,
    List<XFile> files,
  ) async {
    final accepted = <XFile>[];
    var rejectedAny = false;
    for (final file in files) {
      final bytes = await file.length();
      if (bytes <= AppConstants.maxUploadSizeBytes) {
        accepted.add(file);
      } else {
        rejectedAny = true;
      }
    }
    if (rejectedAny && context.mounted) {
      const mb = AppConstants.maxUploadSizeBytes ~/ (1024 * 1024);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.image_too_large'.tr(args: ['$mb']))),
      );
    }
    return accepted;
  }
}
