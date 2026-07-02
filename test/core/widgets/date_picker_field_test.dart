import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';

void main() {
  testWidgets('renders formatted initial date value', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DatePickerField(
              label: 'Lay date',
              value: DateTime(2024, 1, 5),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('05.01.2024'), findsOneWidget);
    expect(find.text('Lay date'), findsOneWidget);
  });

  testWidgets('renders empty input when value is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DatePickerField(
              label: 'Lay date',
              value: null,
              onChanged: (_) {},
            ),
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
      ProviderScope(
        child: MaterialApp(
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
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(selected, fixedDate);
  });

  testWidgets(
    'updates displayed text when value changes via rebuild, without '
    'triggering a setState-during-build assertion',
    (tester) async {
      Widget buildField(DateTime? value) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Form(
              child: DatePickerField(
                label: 'Lay date',
                value: value,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Starting from null mirrors a create-then-populate-from-existing-record
      // form flow (see HealthRecordFormScreen._populateFromExisting), which is
      // exactly the sequence that used to trigger "setState() or
      // markNeedsBuild() called during build" when the controller was synced
      // inside build() instead of didUpdateWidget()/a post-frame callback.
      await tester.pumpWidget(buildField(null));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(buildField(DateTime(2024, 1, 15)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('15.01.2024'), findsOneWidget);
    },
  );
}
