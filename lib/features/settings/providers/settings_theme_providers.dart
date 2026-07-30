import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/local/preferences/app_preferences.dart';
import '../../../data/local/preferences/pref_notifier.dart';

// Legacy keys for one-time migration (pre-unification values).
const _legacyThemeModeKey = 'theme_mode';
const _legacyLocaleKey = 'app_locale';

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

/// Provides the current [ThemeMode], persisted in SharedPreferences.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Manages [ThemeMode] state and persists it locally.
class ThemeModeNotifier extends PrefNotifier<ThemeMode> {
  @override
  ThemeMode get defaultValue => ThemeMode.system;

  @override
  Future<ThemeMode?> readFromPrefs(SharedPreferences prefs) async {
    // Migrate from legacy int-based key ('theme_mode') to unified string key.
    final legacyIndex = prefs.getInt(_legacyThemeModeKey);
    if (legacyIndex != null) {
      final migrated = legacyIndex >= 0 && legacyIndex < ThemeMode.values.length
          ? ThemeMode.values[legacyIndex]
          : ThemeMode.system;
      await prefs.setString(AppPreferences.keyThemeMode, migrated.name);
      await prefs.remove(_legacyThemeModeKey);
      return migrated;
    }

    final value = prefs.getString(AppPreferences.keyThemeMode);
    if (value == null) return null;
    return ThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> writeToPrefs(SharedPreferences prefs, ThemeMode value) =>
      prefs.setString(AppPreferences.keyThemeMode, value.name);

  Future<void> setThemeMode(ThemeMode mode) => set(mode);
}

// ---------------------------------------------------------------------------
// Locale / Language
// ---------------------------------------------------------------------------

/// Supported app locales.
enum AppLocale {
  turkish,
  english,
  german;

  /// The [Locale] instance for this enum value.
  Locale get locale => switch (this) {
    AppLocale.turkish => const Locale('tr'),
    AppLocale.english => const Locale('en'),
    AppLocale.german => const Locale('de'),
  };

  /// Localization key for the language label.
  String get labelKey => switch (this) {
    AppLocale.turkish => 'settings.language_turkish',
    AppLocale.english => 'settings.language_english',
    AppLocale.german => 'settings.language_german',
  };

  /// Native (untranslated) label – always displayed in the target language.
  String get nativeLabel => switch (this) {
    AppLocale.turkish => 'Türkçe',
    AppLocale.english => 'English',
    AppLocale.german => 'Deutsch',
  };

  /// Resolves an [AppLocale] from a language code string.
  static AppLocale fromCode(String code) => switch (code) {
    'tr' => AppLocale.turkish,
    'en' => AppLocale.english,
    'de' => AppLocale.german,
    _ => AppLocale.turkish,
  };
}

/// Provides the current [AppLocale], persisted in SharedPreferences.
///
/// Usage in UI:
/// ```dart
/// final locale = ref.watch(appLocaleProvider);
/// ```
///
/// To change the locale (call from a callback, NOT from build):
/// ```dart
/// ref.read(appLocaleProvider.notifier).setLocale(AppLocale.english, context);
/// ```
final appLocaleProvider = NotifierProvider<AppLocaleNotifier, AppLocale>(
  AppLocaleNotifier.new,
);

/// Manages [AppLocale] state and persists the selection in SharedPreferences.
///
/// The [setLocale] method also calls `context.setLocale()` so that
/// easy_localization is kept in sync.
class AppLocaleNotifier extends PrefNotifier<AppLocale> {
  @override
  AppLocale get defaultValue => AppLocale.turkish;

  @override
  Future<AppLocale?> readFromPrefs(SharedPreferences prefs) async {
    // Migrate from legacy key ('app_locale') to unified key.
    final legacyCode = prefs.getString(_legacyLocaleKey);
    if (legacyCode != null) {
      await prefs.setString(AppPreferences.keyLanguage, legacyCode);
      await prefs.remove(_legacyLocaleKey);
      return AppLocale.fromCode(legacyCode);
    }

    final code = prefs.getString(AppPreferences.keyLanguage);
    if (code == null) return null;
    return AppLocale.fromCode(code);
  }

  @override
  Future<void> writeToPrefs(SharedPreferences prefs, AppLocale value) =>
      prefs.setString(AppPreferences.keyLanguage, value.locale.languageCode);

  /// Sets the app locale, persists it, and syncs easy_localization.
  ///
  /// [context] is required to call `context.setLocale()` from
  /// easy_localization; it is used synchronously, before any await.
  Future<void> setLocale(AppLocale locale, BuildContext context) {
    context.setLocale(locale.locale);
    return set(locale);
  }

  /// Initializes the provider state from the current easy_localization locale.
  ///
  /// Call this once from a top-level widget's `initState` or `build` to ensure
  /// the provider and easy_localization start in sync.
  void syncFromContext(BuildContext context) {
    final current = EasyLocalization.of(context)?.locale ?? const Locale('tr');
    state = AppLocale.fromCode(current.languageCode);
  }
}

// ---------------------------------------------------------------------------
// Font Scale
// ---------------------------------------------------------------------------

enum AppFontScale {
  small,
  normal,
  large,
  extraLarge;

  String get labelKey => switch (this) {
    AppFontScale.small => 'settings.font_small',
    AppFontScale.normal => 'settings.font_normal',
    AppFontScale.large => 'settings.font_large',
    AppFontScale.extraLarge => 'settings.font_extra_large',
  };

  double get scaleFactor => switch (this) {
    AppFontScale.small => 0.85,
    AppFontScale.normal => 1.0,
    AppFontScale.large => 1.15,
    AppFontScale.extraLarge => 1.3,
  };
}

/// Resolves the effective text scaler without suppressing the platform's
/// accessibility setting.
///
/// The system scaler is the floor. The in-app preference can request a larger
/// scale, but it can never shrink text below the user's iOS/Android setting.
TextScaler resolveAppTextScaler(
  TextScaler systemTextScaler,
  AppFontScale appFontScale,
) {
  return systemTextScaler.clamp(minScaleFactor: appFontScale.scaleFactor);
}

final fontScaleProvider = NotifierProvider<FontScaleNotifier, AppFontScale>(
  FontScaleNotifier.new,
);

class FontScaleNotifier extends PrefNotifier<AppFontScale> {
  @override
  AppFontScale get defaultValue => AppFontScale.normal;

  @override
  Future<AppFontScale?> readFromPrefs(SharedPreferences prefs) async {
    final value = prefs.getString(AppPreferences.keyFontScale);
    if (value == null) return null;
    return AppFontScale.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppFontScale.normal,
    );
  }

  @override
  Future<void> writeToPrefs(SharedPreferences prefs, AppFontScale value) =>
      prefs.setString(AppPreferences.keyFontScale, value.name);

  Future<void> setScale(AppFontScale scale) => set(scale);
}
