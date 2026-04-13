import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

export 'settings_theme_providers.dart';
export 'settings_toggle_providers.dart';

// Re-export shared date format providers so existing imports work.
export 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';

// ---------------------------------------------------------------------------
// Cache Size
// ---------------------------------------------------------------------------

final cacheSizeProvider = FutureProvider<int>((ref) async {
  final tempDir = await getTemporaryDirectory();
  return _getDirectorySize(tempDir);
});

final databaseSizeProvider = FutureProvider<int>((ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(appDir.path, 'budgie_tracker.sqlite'));
  if (!await dbFile.exists()) return 0;
  return dbFile.length();
});

final imageStorageSizeProvider = FutureProvider<int>((ref) async {
  final tempDir = await getTemporaryDirectory();
  final appDir = await getApplicationDocumentsDirectory();

  final candidates = <Directory>[
    Directory(p.join(tempDir.path, 'libCachedImageData')),
    Directory(p.join(appDir.path, 'images')),
    Directory(p.join(appDir.path, 'photo_cache')),
  ];

  int total = 0;
  for (final dir in candidates) {
    total += await _getDirectorySize(dir);
  }

  if (total > 0) return total;

  // Fallback: scan temp folder for common image extensions.
  return _getDirectorySizeWhere(tempDir, (file) {
    final lower = file.path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif') ||
        lower.endsWith('.avif');
  });
});

Future<int> _getDirectorySize(Directory dir) async {
  int size = 0;
  if (await dir.exists()) {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
  }
  return size;
}

Future<int> _getDirectorySizeWhere(
  Directory dir,
  bool Function(File file) include,
) async {
  int size = 0;
  if (await dir.exists()) {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && include(entity)) {
        size += await entity.length();
      }
    }
  }
  return size;
}

// ---------------------------------------------------------------------------
// App Info
// ---------------------------------------------------------------------------

final appInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});
