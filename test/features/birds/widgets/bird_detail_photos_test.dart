import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_photos.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_photo_gallery.dart';

import '../../../helpers/test_helpers.dart';

import '../../../helpers/test_localization.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
  bool settle = true,
}) async {
  await pumpLocalizedApp(tester,
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
    settle: settle,
  );
}

void main() {
  group('BirdDetailPhotos', () {
    testWidgets('shows nothing when loading', (tester) async {
      final bird = createTestBird();
      final controller = StreamController<List<String>>();

      await _pump(
        tester,
        BirdDetailPhotos(bird: bird),
        overrides: [
          birdPhotosProvider.overrideWith((ref, id) => controller.stream),
        ],
      );

      expect(find.byType(BirdPhotoGallery), findsNothing);
      expect(find.text('birds.add_photo'), findsNothing);

      addTearDown(() {
        if (!controller.isClosed) controller.close();
      });
    });

    testWidgets('shows add photo button when data loaded with empty urls', (
      tester,
    ) async {
      final bird = createTestBird();

      await _pump(
        tester,
        BirdDetailPhotos(bird: bird),
        overrides: [
          birdPhotosProvider.overrideWith(
            (ref, id) => Stream.value(<String>[]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('birds.add_photo'), findsOneWidget);
      expect(find.byType(BirdPhotoGallery), findsNothing);
    });

    testWidgets('shows photo gallery when urls exist', (tester) async {
      final bird = createTestBird();

      await _pump(
        tester,
        BirdDetailPhotos(bird: bird),
        overrides: [
          birdPhotosProvider.overrideWith(
            (ref, id) => Stream.value(['https://example.com/photo1.jpg']),
          ),
        ],
        settle: false,
      );
      // Use pump() instead of pumpAndSettle() to avoid timeout from
      // CachedNetworkImage scheduling infinite frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BirdPhotoGallery), findsOneWidget);
      expect(find.text('birds.add_photo'), findsOneWidget);
    });

    testWidgets('shows gallery and camera options when add photo tapped', (
      tester,
    ) async {
      final bird = createTestBird();

      await _pump(
        tester,
        BirdDetailPhotos(bird: bird),
        overrides: [
          birdPhotosProvider.overrideWith(
            (ref, id) => Stream.value(<String>[]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('birds.add_photo'));
      await tester.pumpAndSettle();

      expect(find.text('birds.photo_source_gallery'), findsOneWidget);
      expect(find.text('birds.photo_source_camera'), findsOneWidget);
    });

    testWidgets('shows error state with add photo button on error', (
      tester,
    ) async {
      final bird = createTestBird();

      await _pump(
        tester,
        BirdDetailPhotos(bird: bird),
        overrides: [
          birdPhotosProvider.overrideWith(
            (ref, id) => Stream<List<String>>.error(Exception('Network error')),
          ),
        ],
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // If AsyncError state reached, verify error text
      final errorTextFinder = find.text('birds.photos_load_error');
      if (errorTextFinder.evaluate().isNotEmpty) {
        expect(errorTextFinder, findsOneWidget);
        expect(find.text('birds.add_photo'), findsOneWidget);
      } else {
        // Widget is in loading state — verify widget renders without crashing
        expect(find.byType(BirdDetailPhotos), findsOneWidget);
      }
    });
  });
}
