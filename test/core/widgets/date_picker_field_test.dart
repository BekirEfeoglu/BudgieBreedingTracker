import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';

void main() {
  testWidgets('renders formatted initial date value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePickerField(
            label: 'Lay date',
            value: DateTime(2024, 1, 5),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('05.01.2024'), findsOneWidget);
    expect(find.text('Lay date'), findsOneWidget);
  });

  testWidgets('renders empty input when value is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePickerField(
            label: 'Lay date',
            value: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final textField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('opens picker and returns selected date', (tester) async {
    DateTime? selected;
    final fixedDate = DateTime(2024, 2, 10);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePickerField(
            label: 'Lay date',
            value: fixedDate,
            firstDate: DateTime(2024, 1, 1),
            lastDate: DateTime(2024, 12, 31),
            onChanged: (date) => selected = date,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(selected, fixedDate);
  });
}
