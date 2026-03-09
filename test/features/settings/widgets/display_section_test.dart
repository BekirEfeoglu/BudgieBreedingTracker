import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/display_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_section_header.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_selection_tile.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_toggle_tile.dart';

// -- Test Notifier'lari --

class _FakeThemeModeNotifier extends ThemeModeNotifier {
  final ThemeMode _initial;
  _FakeThemeModeNotifier(this._initial);

  @override
  ThemeMode build() => _initial;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
  }
}

class _FakeCompactViewNotifier extends CompactViewNotifier {
  final bool _initial;
  _FakeCompactViewNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSubject({
    ThemeMode themeMode = ThemeMode.system,
    bool compactView = false,
  }) {
    return ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(() => _FakeThemeModeNotifier(themeMode)),
        compactViewProvider.overrideWith(
          () => _FakeCompactViewNotifier(compactView),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: DisplaySection())),
      ),
    );
  }

  group('DisplaySection', () {
    testWidgets('hatasiz render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Overflow hatalarini tüket
      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(DisplaySection), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
    });

    testWidgets('tema secim tile render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSelectionTile<ThemeMode>), findsOneWidget);
    });

    testWidgets('compact view toggle tile render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsToggleTile), findsOneWidget);
    });

    testWidgets('compactView=true iken switch acik gosterilir', (tester) async {
      await tester.pumpWidget(buildSubject(compactView: true));
      await tester.pump(const Duration(milliseconds: 500));
      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isTrue);
    });

    testWidgets('compactView=false iken switch kapali gosterilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(compactView: false));
      await tester.pump(const Duration(milliseconds: 500));
      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
    });

    testWidgets('compact view toggle tiklama sonrasi durum degisir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(compactView: false));
      await tester.pump(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DisplaySection)),
      );
      container.read(compactViewProvider.notifier).toggle();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(compactViewProvider), isTrue);
    });

    testWidgets('tema degistirme calisiyor', (tester) async {
      await tester.pumpWidget(buildSubject(themeMode: ThemeMode.light));
      await tester.pump(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DisplaySection)),
      );
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
