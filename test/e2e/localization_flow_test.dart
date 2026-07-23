@Tags(['e2e'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

import '../helpers/e2e_test_harness.dart';

/// Waits for a [PrefNotifier]-backed provider to hydrate from SharedPreferences
/// (a fire-and-forget async load started in `build()`).
///
/// Bounds the wait by event-loop yields, NOT by a `DateTime.now()` wall-clock
/// deadline: under CI load the loop simply runs a few more zero-delay turns
/// instead of expiring on real time (which is the classic near-now flake). The
/// value-equality check is the real readiness condition; the cap only guards a
/// genuine never-arrives bug.
Future<void> _waitForValue<T>(
  T Function() read,
  T expected,
  String label,
) async {
  for (var i = 0; i < 200; i++) {
    if (read() == expected) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('$label did not become $expected');
}

Future<void> _waitForLocale(dynamic container, AppLocale expected) =>
    _waitForValue(
      () => container.read(appLocaleProvider),
      expected,
      'Locale',
    );

Future<void> _waitForDateFormat(dynamic container, AppDateFormat expected) =>
    _waitForValue(
      () => container.read(dateFormatProvider),
      expected,
      'Date format',
    );

void main() {
  ensureE2EBinding();

  group('Localization Flow E2E', () {
    test(
      'GIVEN Turkish app WHEN language is switched to English THEN locale/date format and AppBar language context are updated',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(appLocaleProvider.notifier).state = AppLocale.english;
        await container
            .read(dateFormatProvider.notifier)
            .setFormat(AppDateFormat.mdy);

        final locale = container.read(appLocaleProvider);
        final format = container.read(dateFormatProvider);

        expect(locale, AppLocale.english);
        expect(locale.locale.languageCode, 'en');
        expect(format, AppDateFormat.mdy);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN settings language selection WHEN Deutsch is selected THEN German locale and tt.MM.jjjj-compatible date pattern state are active',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(appLocaleProvider.notifier).state = AppLocale.german;
        await container
            .read(dateFormatProvider.notifier)
            .setFormat(AppDateFormat.dmy);

        final locale = container.read(appLocaleProvider);
        final format = container.read(dateFormatProvider);

        expect(locale, AppLocale.german);
        expect(locale.locale.languageCode, 'de');
        expect(format, AppDateFormat.dmy);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN English locale persisted WHEN app is reopened THEN language preference remains English',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          AppPreferences.keyLanguage: 'en',
          AppPreferences.keyDateFormat: 'mdy',
        });

        final firstContainer = createTestContainer();
        await _waitForLocale(firstContainer, AppLocale.english);
        await _waitForDateFormat(firstContainer, AppDateFormat.mdy);

        expect(firstContainer.read(appLocaleProvider), AppLocale.english);
        expect(firstContainer.read(dateFormatProvider), AppDateFormat.mdy);
        firstContainer.dispose();

        final reopenedContainer = createTestContainer();
        addTearDown(reopenedContainer.dispose);
        await _waitForLocale(reopenedContainer, AppLocale.english);
        await _waitForDateFormat(reopenedContainer, AppDateFormat.mdy);

        expect(reopenedContainer.read(appLocaleProvider), AppLocale.english);
      },
      timeout: e2eTimeout,
    );
  });
}
