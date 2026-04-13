import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_helpers.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiButtonSpinner', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await pumpWidgetSimple(tester, const AiButtonSpinner());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has fixed 18x18 size', (tester) async {
      await pumpWidgetSimple(tester, const AiButtonSpinner());
      await tester.pump();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 18);
      expect(sizedBox.height, 18);
    });
  });

  group('formatAiError', () {
    test('formats AppException with l10n key prefix', () {
      const error = NetworkException('genetics.local_ai_error_timeout');
      final result = formatAiError(error);
      // Returns the tr() of the key — in test env returns key itself
      expect(result, isNotEmpty);
    });

    test('formats AppException with l10n key and args', () {
      const error = NetworkException(
        'genetics.local_ai_error_http\x00404',
      );
      final result = formatAiError(error);
      expect(result, isNotEmpty);
    });

    test('formats AppException without l10n prefix as raw message', () {
      const error = ValidationException('some raw message');
      final result = formatAiError(error);
      expect(result, 'some raw message');
    });

    test('formats non-AppException as toString', () {
      final result = formatAiError(Exception('boom'));
      expect(result, contains('boom'));
    });

    test('formats null error', () {
      final result = formatAiError(null);
      expect(result, isNotEmpty);
    });

    test('formats String error', () {
      final result = formatAiError('string error');
      expect(result, 'string error');
    });
  });
}
