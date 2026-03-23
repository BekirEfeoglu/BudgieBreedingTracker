import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/language_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_section_header.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_selection_tile.dart';

import '../../../helpers/test_localization.dart';

// -- Test Notifier'lari --

class _FakeAppLocaleNotifier extends AppLocaleNotifier {
  final AppLocale _initial;
  _FakeAppLocaleNotifier(this._initial);

  @override
  AppLocale build() => _initial;

  @override
  Future<void> setLocale(AppLocale locale, BuildContext context) async {
    state = locale;
  }
}

class _FakeDateFormatNotifier extends DateFormatNotifier {
  final AppDateFormat _initial;
  _FakeDateFormatNotifier(this._initial);

  @override
  AppDateFormat build() => _initial;

  @override
  Future<void> setFormat(AppDateFormat format) async {
    state = format;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSubject({
    AppLocale locale = AppLocale.turkish,
    AppDateFormat dateFormat = AppDateFormat.dmy,
  }) {
    return ProviderScope(
      overrides: [
        appLocaleProvider.overrideWith(() => _FakeAppLocaleNotifier(locale)),
        dateFormatProvider.overrideWith(
          () => _FakeDateFormatNotifier(dateFormat),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: LanguageSection())),
      ),
    );
  }

  group('LanguageSection', () {
    testWidgets('hatasiz render edilir', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LanguageSection), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader render edilir', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
    });

    testWidgets('dil secim tile render edilir', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSelectionTile<AppLocale>), findsOneWidget);
    });

    testWidgets('tarih formati secim tile render edilir', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSelectionTile<AppDateFormat>), findsOneWidget);
    });

    testWidgets('turkce seciliyken Turkce native label gosterilir', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,buildSubject(locale: AppLocale.turkish));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Türkçe'), findsOneWidget);
    });

    testWidgets('ingilizce seciliyken English native label gosterilir', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,buildSubject(locale: AppLocale.english));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('almanca seciliyken Deutsch native label gosterilir', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,buildSubject(locale: AppLocale.german));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Deutsch'), findsOneWidget);
    });

    testWidgets('dmy tarih formati seciliyken label gosterilir', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,buildSubject(dateFormat: AppDateFormat.dmy));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('GG.AA.YYYY'), findsOneWidget);
    });

    testWidgets('mdy tarih formati seciliyken label gosterilir', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,buildSubject(dateFormat: AppDateFormat.mdy));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('AA/GG/YYYY'), findsOneWidget);
    });

    testWidgets('dil degistirme notifier state guncellenir', (tester) async {
      await pumpLocalizedApp(tester,buildSubject(locale: AppLocale.turkish));
      await tester.pump(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LanguageSection)),
      );
      await container
          .read(appLocaleProvider.notifier)
          .setLocale(
            AppLocale.english,
            tester.element(find.byType(LanguageSection)),
          );
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(appLocaleProvider), AppLocale.english);
    });
  });
}
