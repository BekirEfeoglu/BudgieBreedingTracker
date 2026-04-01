import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

import '../../../helpers/test_helpers.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{};
  }
}

Future<BuildContext> _pumpLocaleHarness(
  WidgetTester tester,
  ProviderContainer container, {
  Locale startLocale = const Locale('tr'),
}) async {
  late BuildContext context;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
        fallbackLocale: const Locale('tr'),
        startLocale: startLocale,
        path: 'unused',
        assetLoader: const _TestAssetLoader(),
        child: MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return context;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDateFormat', () {
    test('exposes expected labels and intl patterns', () {
      expect(AppDateFormat.dmy.label, 'GG.AA.YYYY');
      expect(AppDateFormat.dmy.intlPattern, 'dd.MM.yyyy');

      expect(AppDateFormat.mdy.label, 'AA/GG/YYYY');
      expect(AppDateFormat.mdy.intlPattern, 'MM/dd/yyyy');

      expect(AppDateFormat.ymd.label, 'YYYY-AA-GG');
      expect(AppDateFormat.ymd.intlPattern, 'yyyy-MM-dd');
    });

    test('formatter uses optional time suffix correctly', () {
      final date = DateTime(2026, 4, 1, 16, 30);

      expect(AppDateFormat.dmy.formatter().format(date), '01.04.2026');
      expect(
        AppDateFormat.ymd.formatter(withTime: true).format(date),
        '2026-04-01 16:30',
      );
    });
  });

  group('dateFormatProvider', () {
    test('loads persisted format and updates it', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyDateFormat: AppDateFormat.mdy.name,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitUntil(
        () => container.read(dateFormatProvider) == AppDateFormat.mdy,
        maxAttempts: 100,
        interval: const Duration(milliseconds: 5),
      );
      expect(container.read(dateFormatProvider), AppDateFormat.mdy);

      await container
          .read(dateFormatProvider.notifier)
          .setFormat(AppDateFormat.ymd);

      expect(container.read(dateFormatProvider), AppDateFormat.ymd);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppPreferences.keyDateFormat),
        AppDateFormat.ymd.name,
      );
    });

    test('falls back to dmy for invalid persisted value', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyDateFormat: 'invalid-format',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitUntil(
        () => container.read(dateFormatProvider) == AppDateFormat.dmy,
        maxAttempts: 100,
        interval: const Duration(milliseconds: 5),
      );

      expect(container.read(dateFormatProvider), AppDateFormat.dmy);
    });
  });

  group('themeModeProvider', () {
    test('loads persisted theme mode and updates it', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyThemeMode: ThemeMode.dark.name,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitUntil(
        () => container.read(themeModeProvider) == ThemeMode.dark,
        maxAttempts: 100,
        interval: const Duration(milliseconds: 5),
      );
      expect(container.read(themeModeProvider), ThemeMode.dark);

      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppPreferences.keyThemeMode),
        ThemeMode.light.name,
      );
    });
  });

  group('appLocaleProvider', () {
    testWidgets('setLocale updates provider state and persists language code', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final context = await _pumpLocaleHarness(tester, container);

      await container
          .read(appLocaleProvider.notifier)
          .setLocale(AppLocale.english, context);

      expect(container.read(appLocaleProvider), AppLocale.english);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppPreferences.keyLanguage), 'en');
    });

    testWidgets('syncFromContext aligns state with EasyLocalization locale', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final context = await _pumpLocaleHarness(
        tester,
        container,
        startLocale: const Locale('de'),
      );

      container.read(appLocaleProvider.notifier).syncFromContext(context);
      expect(container.read(appLocaleProvider), AppLocale.german);
    });
  });

  group('fontScaleProvider', () {
    test('loads persisted scale and updates it', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyFontScale: AppFontScale.large.name,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitUntil(
        () => container.read(fontScaleProvider) == AppFontScale.large,
        maxAttempts: 100,
        interval: const Duration(milliseconds: 5),
      );
      expect(container.read(fontScaleProvider), AppFontScale.large);

      await container
          .read(fontScaleProvider.notifier)
          .setScale(AppFontScale.extraLarge);
      expect(container.read(fontScaleProvider), AppFontScale.extraLarge);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppPreferences.keyFontScale),
        AppFontScale.extraLarge.name,
      );
    });
  });
}
