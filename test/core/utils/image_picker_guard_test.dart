import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/utils/image_picker_guard.dart';

import '../../helpers/test_localization.dart';

class MockXFile extends Mock implements XFile {}

void main() {
  group('ImagePickerGuard', () {
    testWidgets('accepts a post-picker image exactly at the scanned limit', (
      tester,
    ) async {
      final file = MockXFile();
      when(() => file.length()).thenAnswer((_) async => 2 * 1024 * 1024);

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

      final ok = await ImagePickerGuard.ensureWithinSizeLimit(context, file);

      expect(ok, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('rejects a post-picker image above the scanned limit', (
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

      final ok = await ImagePickerGuard.ensureWithinSizeLimit(context, file);
      await tester.pump();

      expect(ok, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('filters using the compressed picker output size', (
      tester,
    ) async {
      final compressedWithinLimit = MockXFile();
      final compressedAboveLimit = MockXFile();
      when(
        () => compressedWithinLimit.length(),
      ).thenAnswer((_) async => 2 * 1024 * 1024);
      when(
        () => compressedAboveLimit.length(),
      ).thenAnswer((_) async => 2 * 1024 * 1024 + 1);

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

      final accepted = await ImagePickerGuard.filterWithinSizeLimit(context, [
        compressedWithinLimit,
        compressedAboveLimit,
      ]);
      await tester.pump();

      expect(accepted, [compressedWithinLimit]);
      expect(find.byType(SnackBar), findsOneWidget);
    });

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
