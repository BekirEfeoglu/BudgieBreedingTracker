import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_utils.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/image_safety_service.dart';

/// Service for uploading and managing files in Supabase Storage.
///
/// Provides methods for bird photos, avatars, and general file uploads.
/// All paths are scoped under the user's ID for RLS compatibility.
///
/// Private user-scoped buckets and RLS policies are migration-managed.
/// Bird/egg/chick/community photo buckets use signed URLs.
class StorageService {
  final SupabaseClient _client;
  final ImageSafetyService? _imageSafetyService;

  static const String _birdPhotosBucket = SupabaseConstants.birdPhotosBucket;
  static const String _avatarsBucket = SupabaseConstants.avatarsBucket;
  static const String _communityPhotosBucket =
      SupabaseConstants.communityPhotosBucket;

  /// Allowed image file extensions for upload.
  static const _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
  };

  /// Signed URL expiry for private buckets: 7 days in seconds.
  static const int _signedUrlExpiry = 60 * 60 * 24 * 7;

  /// Buckets that hold user-supplied imagery and therefore require safety
  /// scanning before upload (App Store UGC guideline 1.2). Buckets not listed
  /// here (e.g. backups) skip the scan.
  static const _imageBuckets = {
    SupabaseConstants.birdPhotosBucket,
    SupabaseConstants.avatarsBucket,
    SupabaseConstants.communityPhotosBucket,
    SupabaseConstants.eggPhotosBucket,
    SupabaseConstants.chickPhotosBucket,
    SupabaseConstants.marketplacePhotosBucket,
  };

  const StorageService(this._client, {ImageSafetyService? imageSafetyService})
    : _imageSafetyService = imageSafetyService;

  /// Validates that a path component contains only safe characters (UUID format).
  /// Prevents path traversal attacks via crafted IDs.
  static String _sanitizePath(String id) {
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(id)) {
      throw ArgumentError('Invalid path component: $id');
    }
    return id;
  }

  /// Uploads a bird photo and returns a signed URL.
  ///
  /// File is stored at: `bird-photos/{userId}/{birdId}/{filename}`.
  Future<String> uploadBirdPhoto({
    required String userId,
    required String birdId,
    required XFile file,
  }) async {
    _sanitizePath(userId);
    _sanitizePath(birdId);
    final ext = StorageUtils.safeExtension(file.name);
    if (ext == null) {
      throw const StorageException('File has no valid extension');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$birdId/$timestamp.$ext';

    return _uploadFile(bucket: _birdPhotosBucket, path: path, file: file);
  }

  /// Uploads a user avatar and returns the public URL.
  ///
  /// File is stored at: `avatars/{userId}/avatar.{ext}`.
  /// Overwrites existing avatar.
  Future<String> uploadAvatar({
    required String userId,
    required XFile file,
  }) async {
    _sanitizePath(userId);
    final ext = StorageUtils.safeExtension(file.name);
    if (ext == null) {
      throw const StorageException('File has no valid extension');
    }
    final path = '$userId/avatar.$ext';

    await _uploadBinary(
      bucket: _avatarsBucket,
      path: path,
      file: file,
      upsert: true,
    );

    return _client.storage.from(_avatarsBucket).getPublicUrl(path);
  }

  /// Deletes a bird photo by its storage path.
  Future<void> deleteBirdPhoto({required String storagePath}) async {
    try {
      await _client.storage.from(_birdPhotosBucket).remove([storagePath]);
    } on StorageException catch (e) {
      AppLogger.warning('Failed to delete bird photo: ${e.message}');
      rethrow;
    }
  }

  /// Deletes a user avatar.
  Future<void> deleteAvatar({required String userId}) async {
    _sanitizePath(userId);
    try {
      final files = await _client.storage
          .from(_avatarsBucket)
          .list(path: userId);

      if (files.isNotEmpty) {
        final paths = files.map((f) => '$userId/${f.name}').toList();
        await _client.storage.from(_avatarsBucket).remove(paths);
      }
    } on StorageException catch (e) {
      AppLogger.warning('Failed to delete avatar: ${e.message}');
      rethrow;
    }
  }

  /// Uploads a community post photo and returns a signed URL.
  ///
  /// File is stored at: `community-photos/{userId}/{postId}/{timestamp}.{ext}`.
  Future<String> uploadCommunityPhoto({
    required String userId,
    required String postId,
    required XFile file,
  }) async {
    _sanitizePath(userId);
    _sanitizePath(postId);
    final ext = StorageUtils.safeExtension(file.name);
    if (ext == null) {
      throw const StorageException('File has no valid extension');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/$postId/$timestamp.$ext';

    return _uploadFile(bucket: _communityPhotosBucket, path: path, file: file);
  }

  /// Deletes a community post photo by its storage path.
  Future<void> deleteCommunityPhoto({required String storagePath}) async {
    try {
      await _client.storage.from(_communityPhotosBucket).remove([storagePath]);
    } on StorageException catch (e) {
      AppLogger.warning('Failed to delete community photo: ${e.message}');
      rethrow;
    }
  }

  /// Lists all photos for a bird.
  ///
  /// Returns signed URLs sorted by upload time (newest first).
  Future<List<String>> listBirdPhotos({
    required String userId,
    required String birdId,
  }) async {
    _sanitizePath(userId);
    _sanitizePath(birdId);
    try {
      final files = await _client.storage
          .from(_birdPhotosBucket)
          .list(path: '$userId/$birdId');

      final validFiles = files
          .where((f) => f.id != null && f.name != '.emptyFolderPlaceholder')
          .toList();
      if (validFiles.isEmpty) return [];

      validFiles.sort((a, b) => b.name.compareTo(a.name));
      final paths = validFiles.map((f) => '$userId/$birdId/${f.name}').toList();
      final signedUrls = await _client.storage
          .from(_birdPhotosBucket)
          .createSignedUrls(paths, _signedUrlExpiry);
      return signedUrls.map((s) => s.signedUrl).toList();
    } on StorageException catch (e) {
      AppLogger.warning('Failed to list bird photos: ${e.message}');
      return [];
    }
  }

  /// Gets the public avatar URL for a user, or null if not set.
  ///
  /// Requires an authenticated session. Returns null if the caller is
  /// not authenticated to prevent unauthenticated avatar enumeration.
  Future<String?> getAvatarUrl({required String userId}) async {
    _sanitizePath(userId);
    if (_client.auth.currentUser == null) return null;
    try {
      final files = await _client.storage
          .from(_avatarsBucket)
          .list(path: userId);

      if (files.isEmpty) return null;

      return _client.storage
          .from(_avatarsBucket)
          .getPublicUrl('$userId/${files.first.name}');
    } on StorageException catch (e) {
      AppLogger.warning('Failed to get avatar URL: ${e.message}');
      return null;
    }
  }

  Future<String> _uploadFile({
    required String bucket,
    required String path,
    required XFile file,
    bool upsert = false,
  }) async {
    try {
      await _uploadBinary(
        bucket: bucket,
        path: path,
        file: file,
        upsert: upsert,
      );

      return _client.storage
          .from(bucket)
          .createSignedUrl(path, _signedUrlExpiry);
    } on StorageException catch (e) {
      AppLogger.error('Storage upload failed: ${e.message}');
      rethrow;
    }
  }

  Future<void> _uploadBinary({
    required String bucket,
    required String path,
    required XFile file,
    bool upsert = false,
  }) async {
    final ext = StorageUtils.safeExtension(file.name);
    if (ext == null || !_allowedExtensions.contains(ext)) {
      throw StorageException(
        'File type ${ext != null ? '.$ext' : '(unknown)'} is not allowed. '
        'Allowed: ${_allowedExtensions.join(', ')}',
      );
    }

    final bytes = await file.readAsBytes();

    if (bytes.length > AppConstants.maxUploadSizeBytes) {
      throw const StorageException('File size exceeds 10 MB limit');
    }

    // Validate file content matches claimed extension via magic bytes
    if (!StorageUtils.validateMagicBytes(bytes, ext)) {
      throw StorageException('File content does not match .$ext format');
    }

    final mimeType = StorageUtils.getMimeType(file.name);

    // Image safety scan for user-supplied imagery (App Store UGC guideline 1.2).
    // Fail-closed: if scan unavailable or image flagged, reject upload.
    if (_imageBuckets.contains(bucket)) {
      final scanner = _imageSafetyService;
      if (scanner == null) {
        throw const StorageException('Image safety scanner unavailable');
      }
      final scan = await scanner.scanImage(bytes: bytes, mimeType: mimeType);
      if (!scan.isSafe) {
        AppLogger.warning(
          'Image upload rejected by safety scan: ${scan.rejectionReason}',
        );
        throw StorageException(
          'Image rejected: ${scan.rejectionReason ?? 'safety_scan_failed'}',
        );
      }
    }

    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: upsert),
        );
  }

  /// Deletes all files owned by [userId] across every storage bucket.
  ///
  /// Recursively walks subdirectories (e.g. `bird-photos/{userId}/{birdId}/`
  /// and `photos/marketplace-images/{userId}/{listingId}/`).
  /// Attempts every bucket, then throws if any bucket failed. The account
  /// deletion RPC removes auth.users and cannot retry user-scoped storage
  /// afterwards, so callers must treat this as fail-closed.
  Future<void> deleteAllUserFiles(String userId) async {
    _sanitizePath(userId);
    const buckets = [
      _birdPhotosBucket,
      _avatarsBucket,
      SupabaseConstants.eggPhotosBucket,
      SupabaseConstants.chickPhotosBucket,
      SupabaseConstants.backupsBucket,
      _communityPhotosBucket,
    ];
    final cleanupTargets = [
      for (final bucket in buckets) MapEntry(bucket, userId),
      MapEntry(
        SupabaseConstants.marketplacePhotosBucket,
        'marketplace-images/$userId',
      ),
    ];

    final maskedUserId = AppLogger.obfuscate(userId);
    final failures = <String>[];
    for (final target in cleanupTargets) {
      try {
        await _deleteRecursive(target.key, target.value);
      } catch (e) {
        failures.add(target.key);
        AppLogger.warning(
          'Failed to clear bucket ${target.key} for $maskedUserId: $e',
        );
      }
    }

    if (failures.isNotEmpty) {
      throw StorageException(
        'Failed to clear ${failures.length} storage bucket(s): '
        '${failures.join(', ')}',
      );
    }
  }

  /// Recursively lists and deletes all files under [path] in [bucket].
  Future<void> _deleteRecursive(String bucket, String path) async {
    final items = await _client.storage.from(bucket).list(path: path);
    if (items.isEmpty) return;

    final filePaths = <String>[];
    for (final item in items) {
      final fullPath = '$path/${item.name}';
      if (item.id == null) {
        // No id means it's a folder — recurse into it
        await _deleteRecursive(bucket, fullPath);
      } else {
        filePaths.add(fullPath);
      }
    }

    if (filePaths.isNotEmpty) {
      await _client.storage.from(bucket).remove(filePaths);
    }
  }
}
