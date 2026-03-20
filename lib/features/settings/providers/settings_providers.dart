import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/local/preferences/app_preferences.dart';

export 'settings_theme_providers.dart';
export 'settings_toggle_providers.dart';

// ---------------------------------------------------------------------------
// Unit System
// ---------------------------------------------------------------------------

enum UnitSystem {
  metric,
  imperial;

  String get label => switch (this) {
    UnitSystem.metric => 'settings.unit_metric'.tr(),
    UnitSystem.imperial => 'settings.unit_imperial'.tr(),
  };
}

final unitSystemProvider = NotifierProvider<UnitSystemNotifier, UnitSystem>(
  UnitSystemNotifier.new,
);

class UnitSystemNotifier extends Notifier<UnitSystem> {
  @override
  UnitSystem build() {
    _loadFromPrefs();
    return UnitSystem.metric;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppPreferences.keyUnitSystem);
    if (value == 'imperial') state = UnitSystem.imperial;
  }

  Future<void> setUnit(UnitSystem unit) async {
    state = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPreferences.keyUnitSystem, unit.name);
  }
}

// ---------------------------------------------------------------------------
// Date Format
// ---------------------------------------------------------------------------

enum AppDateFormat {
  dmy,
  mdy,
  ymd;

  String get label => switch (this) {
    AppDateFormat.dmy => 'GG.AA.YYYY',
    AppDateFormat.mdy => 'AA/GG/YYYY',
    AppDateFormat.ymd => 'YYYY-AA-GG',
  };

  String get intlPattern => switch (this) {
    AppDateFormat.dmy => 'dd.MM.yyyy',
    AppDateFormat.mdy => 'MM/dd/yyyy',
    AppDateFormat.ymd => 'yyyy-MM-dd',
  };

  DateFormat formatter({bool withTime = false}) {
    final pattern = withTime ? '$intlPattern HH:mm' : intlPattern;
    return DateFormat(pattern);
  }
}

final dateFormatProvider = NotifierProvider<DateFormatNotifier, AppDateFormat>(
  DateFormatNotifier.new,
);

class DateFormatNotifier extends Notifier<AppDateFormat> {
  @override
  AppDateFormat build() {
    _loadFromPrefs();
    return AppDateFormat.dmy;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppPreferences.keyDateFormat);
    if (value != null) {
      state = AppDateFormat.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppDateFormat.dmy,
      );
    }
  }

  Future<void> setFormat(AppDateFormat format) async {
    state = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPreferences.keyDateFormat, format.name);
  }
}

// ---------------------------------------------------------------------------
// Breeding Defaults
// ---------------------------------------------------------------------------

final defaultIncubationDaysProvider =
    NotifierProvider<DefaultIncubationDaysNotifier, int>(
      DefaultIncubationDaysNotifier.new,
    );

class DefaultIncubationDaysNotifier extends Notifier<int> {
  @override
  int build() {
    _loadFromPrefs();
    return 18;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(AppPreferences.keyDefaultIncubationDays) ?? 18;
  }

  Future<void> setDays(int days) async {
    state = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppPreferences.keyDefaultIncubationDays, days);
  }
}

final defaultClutchSizeProvider =
    NotifierProvider<DefaultClutchSizeNotifier, int>(
      DefaultClutchSizeNotifier.new,
    );

class DefaultClutchSizeNotifier extends Notifier<int> {
  @override
  int build() {
    _loadFromPrefs();
    return 6;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(AppPreferences.keyDefaultClutchSize) ?? 6;
  }

  Future<void> setSize(int size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppPreferences.keyDefaultClutchSize, size);
  }
}

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
