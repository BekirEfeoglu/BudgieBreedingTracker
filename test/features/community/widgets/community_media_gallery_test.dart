@Tags(['community'])
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_media_gallery.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = true}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: child),
      ),
    );
  }

  Future<void> doubleTapGallery(WidgetTester tester) async {
    final galleryCenter = tester.getCenter(find.byType(CommunityMediaGallery));
    await tester.tapAt(galleryCenter);
    await tester.pump(kDoubleTapMinTime + const Duration(milliseconds: 1));
    await tester.tapAt(galleryCenter);
    await tester.pump();
  }

  group('CommunityMediaGallery', () {
    testWidgets('renders a cell per image in a collage (no PageView)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
            ],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(CachedNetworkImage), findsNWidgets(2));
    });

    testWidgets('shows "1 / N" counter chip for 3+ images', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
              'https://example.com/3.jpg',
            ],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('shows "+N" overlay when more than 3 images', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
              'https://example.com/3.jpg',
              'https://example.com/4.jpg',
              'https://example.com/5.jpg',
            ],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      // 5 images → 3 shown in the collage, "+2" overlay on the last cell.
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('shows no counter chip for single image', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const ['https://example.com/1.jpg'],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 / 1'), findsNothing);
    });

    testWidgets('calls onDoubleTap callback', (tester) async {
      var doubleTapped = false;
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const ['https://example.com/1.jpg'],
            onDoubleTap: () => doubleTapped = true,
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      await doubleTapGallery(tester);

      expect(doubleTapped, isTrue);
      await tester.pump(kDoubleTapTimeout);
    });

    testWidgets('shows heart animation on double-tap', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const ['https://example.com/1.jpg'],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
          disableAnimations: false,
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);

      await doubleTapGallery(tester);

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('calls onOpenImage with the tapped index after timeout', (
      tester,
    ) async {
      int? openedIndex;
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const ['https://example.com/1.jpg'],
            onDoubleTap: () {},
            onOpenImage: (index) => openedIndex = index,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump(kDoubleTapTimeout);
      await tester.pump();

      expect(openedIndex, 0);
    });

    testWidgets('single image uses the tall (300) cell height', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const ['https://example.com/1.jpg'],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is SizedBox && w.height == 300),
        findsOneWidget,
      );
    });

    testWidgets('renders empty SizedBox for empty imageUrls', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const [],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows skeleton placeholder while loading', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityMediaGallery(
            imageUrls: const ['https://example.com/1.jpg'],
            onDoubleTap: () {},
            onOpenImage: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}
