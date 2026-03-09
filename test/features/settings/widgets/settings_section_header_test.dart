import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/settings/widgets/settings_section_header.dart';

void main() {
  group('SettingsSectionHeader', () {
    Widget buildSubject({required String title, Widget? icon}) {
      return MaterialApp(
        home: Scaffold(
          body: SettingsSectionHeader(title: title, icon: icon),
        ),
      );
    }

    testWidgets('title metni gosterir', (tester) async {
      await tester.pumpWidget(buildSubject(title: 'Test Baslik'));
      expect(find.text('Test Baslik'), findsOneWidget);
    });

    testWidgets('icon verilmediginde sadece title render edilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(title: 'Baslik'));
      expect(find.byType(SettingsSectionHeader), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('icon verildiginde icon ve title render edilir', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(title: 'Baslik', icon: const Icon(Icons.settings)),
      );
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('Baslik'), findsOneWidget);
    });

    testWidgets('Row widget icinde render edilir', (tester) async {
      await tester.pumpWidget(
        buildSubject(title: 'Row Test', icon: const Icon(Icons.info)),
      );
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Padding icinde render edilir', (tester) async {
      await tester.pumpWidget(buildSubject(title: 'Padding Test'));
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('birden fazla header birlikte render edilebilir', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SettingsSectionHeader(title: 'Birinci'),
                SettingsSectionHeader(title: 'Ikinci'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Birinci'), findsOneWidget);
      expect(find.text('Ikinci'), findsOneWidget);
    });
  });
}
