import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asset loader that returns empty maps so `.tr()` calls return raw keys
/// instead of throwing.
class TestAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

/// Asset loader that reads the real JSON translation files from disk.
class RealTestAssetLoader extends AssetLoader {
  const RealTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final file = File('$path/${locale.languageCode}.json');
    final raw = file.readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

/// Wraps a widget with EasyLocalization for tests that use `.tr()` calls.
///
/// Keys render as raw strings (e.g. `birds.title`) instead of translated text.
/// Use this only for legacy tests that intentionally assert on keys.
Future<void> pumpLocalizedWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('tr'),
  ThemeData? theme,
  bool settle = true,
}) async {
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      assetLoader: TestAssetLoader(),
      fallbackLocale: const Locale('tr'),
      child: MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Wraps a widget with EasyLocalization backed by the real translation files.
Future<void> pumpTranslatedWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('tr'),
  ThemeData? theme,
  bool settle = true,
}) async {
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      assetLoader: const RealTestAssetLoader(),
      fallbackLocale: const Locale('tr'),
      startLocale: locale,
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: theme,
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Wraps a pre-built widget tree (e.g., one that already includes
/// [MaterialApp] or [ProviderScope]) with EasyLocalization.
///
/// Use this when the test already constructs its own [MaterialApp] or needs
/// a custom widget tree that should not be wrapped in another MaterialApp.
/// This keeps legacy raw-key rendering behavior for compatibility.
Future<void> pumpLocalizedApp(
  WidgetTester tester,
  Widget app, {
  Locale locale = const Locale('tr'),
  bool settle = true,
}) async {
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      assetLoader: TestAssetLoader(),
      fallbackLocale: const Locale('tr'),
      child: app,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Wraps a pre-built app tree with the real translation files.
Future<void> pumpTranslatedApp(
  WidgetTester tester,
  Widget app, {
  Locale locale = const Locale('tr'),
  bool settle = true,
}) async {
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      assetLoader: const RealTestAssetLoader(),
      fallbackLocale: const Locale('tr'),
      startLocale: locale,
      child: app,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
