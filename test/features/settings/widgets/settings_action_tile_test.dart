import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/settings/widgets/settings_action_tile.dart';

void main() {
  group('SettingsActionTile', () {
    int tapCount = 0;

    setUp(() => tapCount = 0);

    Widget buildSubject({
      String title = 'Aksiyon',
      String? subtitle,
      Widget? icon,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SettingsActionTile(
            title: title,
            onTap: () => tapCount++,
            subtitle: subtitle,
            icon: icon,
            isLoading: isLoading,
          ),
        ),
      );
    }

    testWidgets('title metni gosterir', (tester) async {
      await tester.pumpWidget(buildSubject(title: 'Veri Disa Aktar'));
      expect(find.text('Veri Disa Aktar'), findsOneWidget);
    });

    testWidgets('subtitle verildiginde gosterilir', (tester) async {
      await tester.pumpWidget(
        buildSubject(subtitle: 'Kisisel verilerinizi indirin'),
      );
      expect(find.text('Kisisel verilerinizi indirin'), findsOneWidget);
    });

    testWidgets('isLoading=false iken CircularProgressIndicator gosterilmez', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(isLoading: false));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('isLoading=true iken CircularProgressIndicator gosterilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(isLoading: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('isLoading=false iken onTap cagrilir', (tester) async {
      await tester.pumpWidget(buildSubject(isLoading: false));
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('isLoading=true iken onTap cagrilmaz', (tester) async {
      await tester.pumpWidget(buildSubject(isLoading: true));
      await tester.tap(find.byType(ListTile), warnIfMissed: false);
      await tester.pump();
      expect(tapCount, 0);
    });

    testWidgets('icon verildiginde render edilir', (tester) async {
      await tester.pumpWidget(buildSubject(icon: const Icon(Icons.download)));
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('ListTile olarak render edilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
