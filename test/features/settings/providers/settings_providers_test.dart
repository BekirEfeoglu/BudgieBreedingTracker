import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{};
  }
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var i = 0; i < 100; i++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
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

  group('themeModeProvider', () {
    test('loads persisted theme mode and updates it', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyThemeMode: ThemeMode.dark.name,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _waitUntil(
        () => container.read(themeModeProvider) == ThemeMode.dark,
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

      await _waitUntil(
        () => container.read(fontScaleProvider) == AppFontScale.large,
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
