import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/accessibility_section.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_section_header.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_selection_tile.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/settings_toggle_tile.dart';

// -- Test Notifier'lari --

class _FakeFontScaleNotifier extends FontScaleNotifier {
  final AppFontScale _initial;
  _FakeFontScaleNotifier(this._initial);

  @override
  AppFontScale build() => _initial;

  @override
  Future<void> setScale(AppFontScale scale) async {
    state = scale;
  }
}

class _FakeReduceAnimationsNotifier extends ReduceAnimationsNotifier {
  final bool _initial;
  _FakeReduceAnimationsNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

class _FakeHapticFeedbackNotifier extends HapticFeedbackNotifier {
  final bool _initial;
  _FakeHapticFeedbackNotifier(this._initial);

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
    AppFontScale fontScale = AppFontScale.normal,
    bool reduceAnimations = false,
    bool hapticFeedback = true,
  }) {
    return ProviderScope(
      overrides: [
        fontScaleProvider.overrideWith(() => _FakeFontScaleNotifier(fontScale)),
        reduceAnimationsProvider.overrideWith(
          () => _FakeReduceAnimationsNotifier(reduceAnimations),
        ),
        hapticFeedbackProvider.overrideWith(
          () => _FakeHapticFeedbackNotifier(hapticFeedback),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: AccessibilitySection()),
        ),
      ),
    );
  }

  group('AccessibilitySection', () {
    testWidgets('hatasiz render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(AccessibilitySection), findsOneWidget);
    });

    testWidgets('SettingsSectionHeader render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
    });

    testWidgets('yazi boyutu secim tile render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsSelectionTile<AppFontScale>), findsOneWidget);
    });

    testWidgets('iki toggle tile render edilir (animasyon+haptic)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsToggleTile), findsNWidgets(2));
    });

    testWidgets('reduceAnimations=true iken ilk switch acik', (tester) async {
      await tester.pumpWidget(buildSubject(reduceAnimations: true));
      await tester.pump(const Duration(milliseconds: 500));

      final tiles = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      // Birinci switch: reduceAnimations
      expect(tiles.first.value, isTrue);
    });

    testWidgets('hapticFeedback=false iken ikinci switch kapali', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(hapticFeedback: false));
      await tester.pump(const Duration(milliseconds: 500));

      final tiles = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      // Ikinci switch: hapticFeedback
      expect(tiles.last.value, isFalse);
    });

    testWidgets('reduceAnimations toggle calisir', (tester) async {
      await tester.pumpWidget(buildSubject(reduceAnimations: false));
      await tester.pump(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AccessibilitySection)),
      );
      container.read(reduceAnimationsProvider.notifier).toggle();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(reduceAnimationsProvider), isTrue);
    });

    testWidgets('hapticFeedback toggle calisir', (tester) async {
      await tester.pumpWidget(buildSubject(hapticFeedback: true));
      await tester.pump(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AccessibilitySection)),
      );
      container.read(hapticFeedbackProvider.notifier).toggle();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(hapticFeedbackProvider), isFalse);
    });

    testWidgets('fontScale degistirme notifier state guncellenir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(fontScale: AppFontScale.normal));
      await tester.pump(const Duration(milliseconds: 500));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AccessibilitySection)),
      );
      await container
          .read(fontScaleProvider.notifier)
          .setScale(AppFontScale.large);
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(fontScaleProvider), AppFontScale.large);
    });
  });
}
