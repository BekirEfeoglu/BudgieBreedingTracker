import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_theme_providers.dart';

// Build() içinde fire-and-forget _loadFromPrefs() çağrısı yapıldığından,
// provider'ın ilk değerini okumadan önce async yüklemenin tamamlanmasını
// beklemek gerekir. Her test manuel dispose kullanır.

Future<ProviderContainer> _makeContainerAndWarm(
  NotifierProvider provider, {
  Map<String, Object> values = const {},
}) async {
  SharedPreferences.setMockInitialValues(values);
  await SharedPreferences.getInstance();
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(provider);
  await Future<void>.delayed(const Duration(milliseconds: 150));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('themeModeProvider', () {
    test('initial state is ThemeMode.system', () async {
      final container = await _makeContainerAndWarm(themeModeProvider);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('setThemeMode changes state to dark', () async {
      final container = await _makeContainerAndWarm(themeModeProvider);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setThemeMode changes state to light', () async {
      final container = await _makeContainerAndWarm(themeModeProvider);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('setThemeMode persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(prefs.getString(AppPreferences.keyThemeMode), 'dark');
    });

    test('loads persisted dark from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        themeModeProvider,
        values: {AppPreferences.keyThemeMode: 'dark'},
      );

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('loads persisted light from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        themeModeProvider,
        values: {AppPreferences.keyThemeMode: 'light'},
      );

      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('unknown persisted value defaults to system', () async {
      final container = await _makeContainerAndWarm(
        themeModeProvider,
        values: {AppPreferences.keyThemeMode: 'unknown_value'},
      );

      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('appLocaleProvider', () {
    test('initial state is AppLocale.turkish', () async {
      final container = await _makeContainerAndWarm(appLocaleProvider);

      expect(container.read(appLocaleProvider), AppLocale.turkish);
    });

    test('loads persisted english from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        appLocaleProvider,
        values: {AppPreferences.keyLanguage: 'en'},
      );

      expect(container.read(appLocaleProvider), AppLocale.english);
    });

    test('loads persisted german from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        appLocaleProvider,
        values: {AppPreferences.keyLanguage: 'de'},
      );

      expect(container.read(appLocaleProvider), AppLocale.german);
    });

    test('loads persisted turkish from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        appLocaleProvider,
        values: {AppPreferences.keyLanguage: 'tr'},
      );

      expect(container.read(appLocaleProvider), AppLocale.turkish);
    });
  });

  group('AppLocale enum', () {
    test('fromCode(tr) returns turkish', () {
      expect(AppLocale.fromCode('tr'), AppLocale.turkish);
    });

    test('fromCode(en) returns english', () {
      expect(AppLocale.fromCode('en'), AppLocale.english);
    });

    test('fromCode(de) returns german', () {
      expect(AppLocale.fromCode('de'), AppLocale.german);
    });

    test('fromCode unknown code defaults to turkish', () {
      expect(AppLocale.fromCode('xx'), AppLocale.turkish);
      expect(AppLocale.fromCode(''), AppLocale.turkish);
    });

    test('locale getter returns correct Locale instances', () {
      expect(AppLocale.turkish.locale, const Locale('tr'));
      expect(AppLocale.english.locale, const Locale('en'));
      expect(AppLocale.german.locale, const Locale('de'));
    });

    test('nativeLabel returns untranslated language names', () {
      expect(AppLocale.turkish.nativeLabel, 'Türkçe');
      expect(AppLocale.english.nativeLabel, 'English');
      expect(AppLocale.german.nativeLabel, 'Deutsch');
    });
  });

  group('fontScaleProvider', () {
    test('initial state is AppFontScale.normal', () async {
      final container = await _makeContainerAndWarm(fontScaleProvider);

      expect(container.read(fontScaleProvider), AppFontScale.normal);
    });

    test('setScale changes state to large', () async {
      final container = await _makeContainerAndWarm(fontScaleProvider);

      await container
          .read(fontScaleProvider.notifier)
          .setScale(AppFontScale.large);

      expect(container.read(fontScaleProvider), AppFontScale.large);
    });

    test('setScale changes state to small', () async {
      final container = await _makeContainerAndWarm(fontScaleProvider);

      await container
          .read(fontScaleProvider.notifier)
          .setScale(AppFontScale.small);

      expect(container.read(fontScaleProvider), AppFontScale.small);
    });

    test('setScale persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(fontScaleProvider);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await container
          .read(fontScaleProvider.notifier)
          .setScale(AppFontScale.extraLarge);

      expect(prefs.getString(AppPreferences.keyFontScale), 'extraLarge');
    });

    test('loads persisted small from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        fontScaleProvider,
        values: {AppPreferences.keyFontScale: 'small'},
      );

      expect(container.read(fontScaleProvider), AppFontScale.small);
    });

    test('loads persisted extraLarge from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        fontScaleProvider,
        values: {AppPreferences.keyFontScale: 'extraLarge'},
      );

      expect(container.read(fontScaleProvider), AppFontScale.extraLarge);
    });

    test('unknown persisted value defaults to normal', () async {
      final container = await _makeContainerAndWarm(
        fontScaleProvider,
        values: {AppPreferences.keyFontScale: 'gigantic'},
      );

      expect(container.read(fontScaleProvider), AppFontScale.normal);
    });
  });

  group('AppFontScale enum', () {
    test('scale factors are correct', () {
      expect(AppFontScale.small.scaleFactor, 0.85);
      expect(AppFontScale.normal.scaleFactor, 1.0);
      expect(AppFontScale.large.scaleFactor, 1.15);
      expect(AppFontScale.extraLarge.scaleFactor, 1.3);
    });
  });
}
