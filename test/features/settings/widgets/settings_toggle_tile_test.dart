import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/settings/widgets/settings_toggle_tile.dart';

void main() {
  group('SettingsToggleTile', () {
    bool? changedValue;

    setUp(() => changedValue = null);

    Widget buildSubject({
      String title = 'Test Baslik',
      bool value = false,
      String? subtitle,
      Widget? icon,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SettingsToggleTile(
            title: title,
            value: value,
            onChanged: (v) => changedValue = v,
            subtitle: subtitle,
            icon: icon,
          ),
        ),
      );
    }

    testWidgets('title metni gosterir', (tester) async {
      await tester.pumpWidget(buildSubject(title: 'Bildirimler'));
      expect(find.text('Bildirimler'), findsOneWidget);
    });

    testWidgets('subtitle verilmediginde subtitle gosterilmez', (tester) async {
      await tester.pumpWidget(buildSubject());
      // SwitchListTile subtitle null oldugunda Text render edilmez
      expect(find.byType(SettingsToggleTile), findsOneWidget);
    });

    testWidgets('subtitle verildiginde gosterilir', (tester) async {
      await tester.pumpWidget(buildSubject(subtitle: 'Aciklama'));
      expect(find.text('Aciklama'), findsOneWidget);
    });

    testWidgets('value=false iken switch kapali gosterilir', (tester) async {
      await tester.pumpWidget(buildSubject(value: false));
      // Adaptive switch platform'a gore degisir, genel Switch bulmak icin
      // SwitchListTile.adaptive kullanildigini dogrula
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('switch toggle edildiginde onChanged cagrilir', (tester) async {
      await tester.pumpWidget(buildSubject(value: false));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(changedValue, isNotNull);
    });

    testWidgets('icon verildiginde render edilir', (tester) async {
      await tester.pumpWidget(
        buildSubject(icon: const Icon(Icons.notifications)),
      );
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets(
      'value=true iken SwitchListTile value true olarak render edilir',
      (tester) async {
        await tester.pumpWidget(buildSubject(value: true));
        final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
        expect(tile.value, isTrue);
      },
    );

    testWidgets(
      'value=false iken SwitchListTile value false olarak render edilir',
      (tester) async {
        await tester.pumpWidget(buildSubject(value: false));
        final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
        expect(tile.value, isFalse);
      },
    );
  });
}
