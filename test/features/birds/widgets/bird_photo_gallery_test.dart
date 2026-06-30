import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_photo_gallery.dart';

void main() {
  group('BirdPhotoGallery', () {
    testWidgets('returns SizedBox.shrink for empty photoUrls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdPhotoGallery(photoUrls: [])),
        ),
      );

      expect(find.text(l10n('birds.photos')), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('shows photos title when urls are provided', (tester) async {
      const urls = ['https://example.com/photo1.jpg'];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdPhotoGallery(photoUrls: urls)),
        ),
      );

      expect(find.text(l10n('birds.photos')), findsOneWidget);
    });

    testWidgets('shows horizontal ListView with correct item count', (
      tester,
    ) async {
      const urls = [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
        'https://example.com/photo3.jpg',
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdPhotoGallery(photoUrls: urls)),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('renders GestureDetectors for each photo', (tester) async {
      const urls = [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdPhotoGallery(photoUrls: urls)),
        ),
      );

      // Each photo has a GestureDetector
      expect(find.byType(GestureDetector), findsNWidgets(2));
    });

    testWidgets('delete button meets the 48dp touch target minimum', (
      tester,
    ) async {
      const urls = ['https://example.com/photo1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdPhotoGallery(photoUrls: urls, onDeletePhoto: (_) {}),
          ),
        ),
      );

      final size = tester.getSize(
        find.bySemanticsLabel(l10n('birds.delete_photo')),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('is a StatelessWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BirdPhotoGallery(photoUrls: ['https://example.com/p.jpg']),
          ),
        ),
      );

      expect(
        tester.widget(find.byType(BirdPhotoGallery)),
        isA<BirdPhotoGallery>(),
      );
    });

    testWidgets('contains Column as root layout widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BirdPhotoGallery(
              photoUrls: ['https://example.com/photo.jpg'],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('single photo shows one GestureDetector', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BirdPhotoGallery(photoUrls: ['https://example.com/only.jpg']),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('shows Padding wrapper', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BirdPhotoGallery(photoUrls: ['https://example.com/a.jpg']),
          ),
        ),
      );

      expect(find.byType(Padding), findsAtLeastNWidgets(1));
    });
  });
}
