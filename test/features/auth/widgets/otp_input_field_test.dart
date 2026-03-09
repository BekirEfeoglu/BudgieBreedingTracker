import 'package:budgie_breeding_tracker/features/auth/widgets/otp_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('OtpInputField', () {
    testWidgets('renders one text field per requested length', (tester) async {
      await pumpWidgetSimple(
        tester,
        OtpInputField(length: 4, onCompleted: (_) {}),
      );

      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('aggregates code and calls onCompleted at full length', (
      tester,
    ) async {
      final changes = <String>[];
      String? completedCode;

      await pumpWidgetSimple(
        tester,
        OtpInputField(
          length: 4,
          onChanged: changes.add,
          onCompleted: (value) => completedCode = value,
        ),
      );

      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(0), '1');
      await tester.pump();
      await tester.enterText(fields.at(1), '2');
      await tester.pump();
      await tester.enterText(fields.at(2), '3');
      await tester.pump();
      await tester.enterText(fields.at(3), '4');
      await tester.pump();

      expect(changes, ['1', '12', '123', '1234']);
      expect(completedCode, '1234');
    });

    testWidgets('does not call onCompleted before all digits are entered', (
      tester,
    ) async {
      String? completedCode;

      await pumpWidgetSimple(
        tester,
        OtpInputField(length: 4, onCompleted: (value) => completedCode = value),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '1');
      await tester.pump();
      await tester.enterText(fields.at(1), '2');
      await tester.pump();
      await tester.enterText(fields.at(2), '3');
      await tester.pump();

      expect(completedCode, isNull);
    });
  });
}
