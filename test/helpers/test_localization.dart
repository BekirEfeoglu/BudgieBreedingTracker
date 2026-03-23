import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asset loader that returns empty maps so `.tr()` calls return raw keys
/// instead of throwing.
class TestAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

/// Wraps a widget with EasyLocalization for tests that use `.tr()` calls.
///
/// Keys will render as raw strings (e.g., 'birds.title' instead of
/// translated text). This eliminates the need for `tester.takeException()`
/// suppression loops.
Future<void> pumpLocalizedWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('tr'),
  ThemeData? theme,
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
  await tester.pumpAndSettle();
}

/// Wraps a pre-built widget tree (e.g., one that already includes
/// [MaterialApp] or [ProviderScope]) with EasyLocalization.
///
/// Use this when the test already constructs its own [MaterialApp] or needs
/// a custom widget tree that should not be wrapped in another MaterialApp.
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
