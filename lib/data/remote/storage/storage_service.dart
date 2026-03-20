import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Service for uploading and managing files in Supabase Storage.
///
/// Provides methods for bird photos, avatars, and general file uploads.
/// All paths are scoped under the user's ID for RLS compatibility.
///
/// **Supabase Dashboard requirements:**
/// - Buckets (bird-photos, egg-photos, chick-photos, avatars, backups)
///   must be created manually in Supabase Dashboard.
/// - Bird/egg/chick photo buckets should be set to **public** so that
///   `getPublicUrl()` returns accessible URLs.
/// - RLS policies needed:
///   - `SELECT`: public (or authenticated for private buckets)
///   - `INSERT`: authenticated, restricted to own user path
///   - `DELETE`: authenticated, restricted to own user path
class StorageService {
  final SupabaseClient _client;

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

  /// Signed URL expiry: 1 year in seconds.
  static const int _signedUrlExpiry = 60 * 60 * 24 * 365;

  const StorageService(this._client);

  /// Uploads a bird photo and returns the public URL.
  ///
  /// File is stored at: `bird-photos/{userId}/{birdId}/{filename}`.
  Future<String> uploadBirdPhoto({
    required String userId,
    required String birdId,
    required XFile file,
  }) async {
    final ext = _safeExtension(file.name);
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
    final ext = _safeExtension(file.name);
    final path = '$userId/avatar.$ext';

    return _uploadFile(
      bucket: _avatarsBucket,
      path: path,
      file: file,
      upsert: true,
    );
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

  /// Uploads a community post photo and returns the public URL.
  ///
  /// File is stored at: `community-photos/{userId}/{postId}/{timestamp}.{ext}`.
  Future<String> uploadCommunityPhoto({
    required String userId,
    required String postId,
    required XFile file,
  }) async {
    final ext = _safeExtension(file.name);
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
  /// Returns public URLs sorted by upload time (newest first).
  Future<List<String>> listBirdPhotos({
    required String userId,
    required String birdId,
  }) async {
    try {
      final files = await _client.storage
          .from(_birdPhotosBucket)
          .list(path: '$userId/$birdId');

      final validFiles = files
          .where((f) => f.id != null && f.name != '.emptyFolderPlaceholder')
          .toList();

      final paths = validFiles.map((f) => '$userId/$birdId/${f.name}').toList();
      final signedUrls = await _client.storage
          .from(_birdPhotosBucket)
          .createSignedUrls(paths, _signedUrlExpiry);
      final urls = signedUrls.map((s) => s.signedUrl).toList();
      urls.sort((a, b) => b.compareTo(a));
      return urls;
    } on StorageException catch (e) {
      AppLogger.warning('Failed to list bird photos: ${e.message}');
      return [];
    }
  }

  /// Gets the avatar URL for a user, or null if not set.
  Future<String?> getAvatarUrl({required String userId}) async {
    try {
      final files = await _client.storage
          .from(_avatarsBucket)
          .list(path: userId);

      if (files.isEmpty) return null;

      return _client.storage
          .from(_avatarsBucket)
          .createSignedUrl('$userId/${files.first.name}', _signedUrlExpiry);
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
      final ext = _safeExtension(file.name);
      if (!_allowedExtensions.contains(ext)) {
        throw StorageException(
          'File type .$ext is not allowed. '
          'Allowed: ${_allowedExtensions.join(', ')}',
        );
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > AppConstants.maxUploadSizeBytes) {
        throw const StorageException('File size exceeds 10 MB limit');
      }
      final mimeType = _getMimeType(file.name);

      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: upsert),
          );

      // Signed URL works for both public and private buckets (1 year expiry)
      return _client.storage
          .from(bucket)
          .createSignedUrl(path, _signedUrlExpiry);
    } on StorageException catch (e) {
      AppLogger.error('Storage upload failed: ${e.message}');
      rethrow;
    }
  }

  /// Deletes all files owned by [userId] across every storage bucket.
  ///
  /// Recursively walks subdirectories (e.g. `bird-photos/{userId}/{birdId}/`).
  /// Errors are logged but do not throw — the server-side RPC also
  /// handles storage cleanup, so client-side deletion is best-effort.
  Future<void> deleteAllUserFiles(String userId) async {
    const buckets = [
      _birdPhotosBucket,
      _avatarsBucket,
      SupabaseConstants.eggPhotosBucket,
      SupabaseConstants.chickPhotosBucket,
      SupabaseConstants.backupsBucket,
      _communityPhotosBucket,
    ];

    for (final bucket in buckets) {
      try {
        await _deleteRecursive(bucket, userId);
      } catch (e) {
        AppLogger.warning('Failed to clear bucket $bucket for $userId: $e');
      }
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

  /// Extracts file extension safely, falling back to 'jpg' if no dot is found.
  static String _safeExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == filename.length - 1) return 'jpg';
    return filename.substring(dotIndex + 1).toLowerCase();
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }
}
