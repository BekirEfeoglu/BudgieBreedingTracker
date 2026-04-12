import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/settings/widgets/settings_navigation_tile.dart';

void main() {
  group('SettingsNavigationTile', () {
    bool tapped = false;

    setUp(() => tapped = false);

    Widget buildSubject({
      String title = 'Test Navigasyon',
      String? subtitle,
      Widget? icon,
      Widget? trailing,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SettingsNavigationTile(
            title: title,
            onTap: () => tapped = true,
            subtitle: subtitle,
            icon: icon,
            trailing: trailing,
          ),
        ),
      );
    }

    testWidgets('title metni gosterir', (tester) async {
      await tester.pumpWidget(buildSubject(title: 'Gizlilik'));
      expect(find.text('Gizlilik'), findsOneWidget);
    });

    testWidgets('subtitle verildiginde gosterilir', (tester) async {
      await tester.pumpWidget(buildSubject(subtitle: 'Alt baslik'));
      expect(find.text('Alt baslik'), findsOneWidget);
    });

    testWidgets('subtitle verilmediginde bos birakilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(SettingsNavigationTile), findsOneWidget);
    });

    testWidgets('varsayilan trailing chevronRight iconudur', (tester) async {
      await tester.pumpWidget(buildSubject());
      final iconFinder = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == LucideIcons.chevronRight,
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('custom trailing verildiginde kullanilir', (tester) async {
      await tester.pumpWidget(
        buildSubject(trailing: const Icon(Icons.open_in_new)),
      );
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('dokunulabilir ve onTap cagrilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('icon verildiginde leading olarak gosterilir', (tester) async {
      await tester.pumpWidget(buildSubject(icon: const Icon(Icons.lock)));
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });
}
