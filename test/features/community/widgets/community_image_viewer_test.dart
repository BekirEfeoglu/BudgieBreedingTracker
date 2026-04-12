@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/community/widgets/community_image_viewer.dart';

void main() {
  group('CommunityImageViewer', () {
    testWidgets('renders with black background and close button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityImageViewer(imageUrl: 'https://example.com/photo.jpg'),
        ),
      );
      await tester.pump();

      expect(find.byType(CommunityImageViewer), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('has InteractiveViewer for zoom', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityImageViewer(imageUrl: 'https://example.com/photo.jpg'),
        ),
      );
      await tester.pump();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('close button pops navigation', (tester) async {
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CommunityImageViewer(
                        imageUrl: 'https://example.com/photo.jpg',
                      ),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('extends body behind app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CommunityImageViewer(imageUrl: 'https://example.com/photo.jpg'),
        ),
      );
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.extendBodyBehindAppBar, isTrue);
    });
  });
}
