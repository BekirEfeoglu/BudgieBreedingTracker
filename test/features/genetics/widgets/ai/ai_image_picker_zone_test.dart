import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_image_picker_zone.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiImagePickerZone', () {
    testWidgets('shows camera and gallery buttons when no image', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: null,
          tips: const ['Tip 1', 'Tip 2'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows ActionChips when image is selected', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: '/fake/path/image.jpg',
          tips: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActionChip), findsNWidgets(2));
    });

    testWidgets('shows tips when provided and no image', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: null,
          tips: const ['Full body visible', 'Natural light'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Full body visible'), findsOneWidget);
      expect(find.text('Natural light'), findsOneWidget);
    });

    testWidgets('hides tips when image is selected', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: '/fake/path/image.jpg',
          tips: const ['Tip 1'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tip 1'), findsNothing);
    });

    testWidgets('calls onImageCleared when clear chip tapped', (tester) async {
      var cleared = false;
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () => cleared = true,
          selectedImagePath: '/fake/path/image.jpg',
          tips: const [],
        ),
      );
      await tester.pumpAndSettle();

      // Find the clear ActionChip (second one)
      final clearChips = find.byType(ActionChip);
      await tester.tap(clearChips.last);
      expect(cleared, isTrue);
    });

    testWidgets('hides tips section when tips list is empty', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: null,
          tips: const [],
        ),
      );
      await tester.pumpAndSettle();

      // Camera/gallery buttons present but no tips section
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('uses custom previewHeight', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: '/fake/path/image.jpg',
          previewHeight: 200.0,
        ),
      );
      await tester.pumpAndSettle();

      // Widget renders with custom height (no crash)
      expect(find.byType(AiImagePickerZone), findsOneWidget);
    });

    testWidgets('renders drop zone container when no image', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: null,
        ),
      );
      await tester.pumpAndSettle();

      // Should show camera icon in the drop zone
      expect(find.byType(AiImagePickerZone), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
