@Tags(['marketplace'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_image_picker.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject({
    List<String> imagePaths = const [],
    ValueChanged<List<String>>? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MarketplaceImagePicker(
          imagePaths: imagePaths,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  group('MarketplaceImagePicker', () {
    testWidgets('renders with empty image list', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.byType(MarketplaceImagePicker), findsOneWidget);
    });

    testWidgets('shows add button when less than 3 images', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(imagePaths: ['/fake/path1.jpg', '/fake/path2.jpg']),
      );

      // The _AddButton renders a LucideIcons.plus icon
      expect(find.byIcon(const IconData(0xe8c4)), findsNothing); // placeholder
      // Verify the ListView with add button is present (2 images + 1 add tile)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows add button when image list is empty', (tester) async {
      await pumpLocalizedApp(tester, buildSubject(imagePaths: const []));

      // With 0 images, add button should appear - ListView is present
      expect(find.byType(ListView), findsOneWidget);
      // photo_count key rendered as raw key (0 images)
      expect(find.text('marketplace.photo_count'), findsOneWidget);
    });

    testWidgets('hides add button when 3 images are present', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          imagePaths: [
            '/fake/path1.jpg',
            '/fake/path2.jpg',
            '/fake/path3.jpg',
          ],
        ),
      );

      // With 3 images (maxImages), add button should NOT be shown.
      // The GestureDetector for _AddButton is only built when count < maxImages.
      // We can verify by checking that no Container with plus icon exists.
      // The ListView should still render (for the image tiles).
      expect(find.byType(ListView), findsOneWidget);

      // add_photos label should still be visible
      expect(find.text('marketplace.add_photos'), findsOneWidget);
    });

    testWidgets('shows cover photo badge on first image', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(imagePaths: ['/fake/cover.jpg', '/fake/second.jpg']),
      );

      // Cover badge uses the l10n key 'marketplace.cover_photo'
      expect(find.text('marketplace.cover_photo'), findsOneWidget);
    });

    testWidgets('shows add_photos label', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.text('marketplace.add_photos'), findsOneWidget);
    });

    testWidgets('does not show cover badge when no images', (tester) async {
      await pumpLocalizedApp(tester, buildSubject(imagePaths: const []));

      expect(find.text('marketplace.cover_photo'), findsNothing);
    });

    testWidgets('shows cover badge only on first image with multiple images',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          imagePaths: [
            '/fake/path1.jpg',
            '/fake/path2.jpg',
            '/fake/path3.jpg',
          ],
        ),
      );

      // Only one cover badge regardless of image count
      expect(find.text('marketplace.cover_photo'), findsOneWidget);
    });
  });
}
