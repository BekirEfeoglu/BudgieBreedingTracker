import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/community/widgets/community_media_gallery.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CommunityMediaGallery', () {
    testWidgets('renders PageView with images', (tester) async {
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const [
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
        ],
        onDoubleTap: () {},
        onOpenImage: (_) {},
      )));
      await tester.pump();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('shows page indicator for multiple images', (tester) async {
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const [
          'https://example.com/1.jpg',
          'https://example.com/2.jpg',
          'https://example.com/3.jpg',
        ],
        onDoubleTap: () {},
        onOpenImage: (_) {},
      )));
      await tester.pump();

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('hides page indicator for single image', (tester) async {
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const ['https://example.com/1.jpg'],
        onDoubleTap: () {},
        onOpenImage: (_) {},
      )));
      await tester.pump();

      expect(find.text('1/1'), findsNothing);
    });

    testWidgets('calls onDoubleTap callback', (tester) async {
      var doubleTapped = false;
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const ['https://example.com/1.jpg'],
        onDoubleTap: () => doubleTapped = true,
        onOpenImage: (_) {},
      )));
      await tester.pump();

      // GestureDetector onDoubleTap requires two quick taps
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(doubleTapped, isTrue);
    });

    testWidgets('calls onOpenImage on single tap after timeout',
        (tester) async {
      String? openedUrl;
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const ['https://example.com/1.jpg'],
        onDoubleTap: () {},
        onOpenImage: (url) => openedUrl = url,
      )));
      await tester.pump();

      await tester.tap(find.byType(GestureDetector).first);
      // Wait for double-tap timeout so single tap registers
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();

      expect(openedUrl, 'https://example.com/1.jpg');
    });

    testWidgets('has fixed height of 320', (tester) async {
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const ['https://example.com/1.jpg'],
        onDoubleTap: () {},
        onOpenImage: (_) {},
      )));
      await tester.pump();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 320);
    });

    testWidgets('renders empty SizedBox for empty imageUrls', (tester) async {
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const [],
        onDoubleTap: () {},
        onOpenImage: (_) {},
      )));
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows placeholder icon while loading', (tester) async {
      await tester.pumpWidget(wrap(CommunityMediaGallery(
        imageUrls: const ['https://example.com/1.jpg'],
        onDoubleTap: () {},
        onOpenImage: (_) {},
      )));
      await tester.pump();

      expect(find.byIcon(LucideIcons.image), findsOneWidget);
    });
  });
}
