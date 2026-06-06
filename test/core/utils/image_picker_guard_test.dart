import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/utils/image_picker_guard.dart';

import '../../helpers/test_localization.dart';

class MockXFile extends Mock implements XFile {}

void main() {
  group('ImagePickerGuard', () {
    testWidgets('uses the caller-provided single image size limit', (
      tester,
    ) async {
      final file = MockXFile();
      when(() => file.length()).thenAnswer((_) async => 2 * 1024 * 1024 + 1);

      late BuildContext context;
      await pumpLocalizedApp(
        tester,
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final ok = await ImagePickerGuard.ensureWithinSizeLimit(
        context,
        file,
        maxBytes: 2 * 1024 * 1024,
      );
      await tester.pump();

      expect(ok, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
