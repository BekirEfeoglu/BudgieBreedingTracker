import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/settings/widgets/settings_selection_tile.dart';

enum _TestOption { optionA, optionB, optionC }

void main() {
  group('SettingsSelectionTile', () {
    final options = [
      const SettingsOption<_TestOption>(
        value: _TestOption.optionA,
        label: 'Secenek A',
      ),
      const SettingsOption<_TestOption>(
        value: _TestOption.optionB,
        label: 'Secenek B',
        subtitle: 'B aciklamasi',
      ),
      const SettingsOption<_TestOption>(
        value: _TestOption.optionC,
        label: 'Secenek C',
        icon: Icon(Icons.star),
      ),
    ];

    _TestOption? changedValue;

    setUp(() => changedValue = null);

    Widget buildSubject({
      _TestOption currentValue = _TestOption.optionA,
      String? dialogTitle,
      Widget? icon,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SettingsSelectionTile<_TestOption>(
            title: 'Secim Ayari',
            currentValue: currentValue,
            options: options,
            onChanged: (v) => changedValue = v,
            icon: icon,
            dialogTitle: dialogTitle,
          ),
        ),
      );
    }

    testWidgets('title metni gosterilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Secim Ayari'), findsOneWidget);
    });

    testWidgets('mevcut secenegin label metni subtitle olarak gosterilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(currentValue: _TestOption.optionA));
      expect(find.text('Secenek A'), findsOneWidget);
    });

    testWidgets('baska bir secenek secildiginde label guncellenir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(currentValue: _TestOption.optionB));
      expect(find.text('Secenek B'), findsOneWidget);
    });

    testWidgets('tıklandıgında dialog acilir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dialog acildiginda secenekler listelenir', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.text('Secenek A'), findsAtLeastNWidgets(1));
      expect(find.text('Secenek B'), findsOneWidget);
      expect(find.text('Secenek C'), findsOneWidget);
    });

    testWidgets('dialogTitle verildiginde dialog basliginde kullanilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(dialogTitle: 'Ozel Baslik'));
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.text('Ozel Baslik'), findsOneWidget);
    });

    testWidgets(
      'dialogTitle verilmediginde tile title dialog basliginda kullanilir',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.tap(find.byType(ListTile));
        await tester.pumpAndSettle();
        expect(find.text('Secim Ayari'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('secenek secildiginde onChanged cagrilir ve dialog kapanir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(currentValue: _TestOption.optionA));
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Dialog icindeki 'Secenek B' radiosu bul ve tap
      final radioTile = find.widgetWithText(
        RadioListTile<_TestOption>,
        'Secenek B',
      );
      await tester.tap(radioTile);
      await tester.pumpAndSettle();

      expect(changedValue, _TestOption.optionB);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('icon verildiginde render edilir', (tester) async {
      await tester.pumpWidget(buildSubject(icon: const Icon(Icons.tune)));
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('SettingsOption subtitle\'i dialog\'da gosterilir', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.text('B aciklamasi'), findsOneWidget);
    });
  });
}
