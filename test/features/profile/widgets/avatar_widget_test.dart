import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/profile/widgets/avatar_widget.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('AvatarWidget', () {
    testWidgets('renders without error when imageUrl is null', (tester) async {
      await pumpWidgetSimple(tester, const AvatarWidget());

      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('renders with default radius', (tester) async {
      await pumpWidgetSimple(tester, const AvatarWidget());

      final widget = tester.widget<AvatarWidget>(find.byType(AvatarWidget));
      expect(widget.radius, 48.0);
    });

    testWidgets('shows CircleAvatar', (tester) async {
      await pumpWidgetSimple(tester, const AvatarWidget());

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('custom onTap is invoked', (tester) async {
      var tapped = false;

      await pumpWidgetSimple(tester, AvatarWidget(onTap: () => tapped = true));

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });

    testWidgets('shows upload spinner when isUploading is true', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, const AvatarWidget(isUploading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('does not show spinner when isUploading is false', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, const AvatarWidget(isUploading: false));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('custom radius is applied', (tester) async {
      await pumpWidgetSimple(tester, const AvatarWidget(radius: 64));

      final widget = tester.widget<AvatarWidget>(find.byType(AvatarWidget));
      expect(widget.radius, 64.0);
    });

    testWidgets('renders with Stack for overlay support', (tester) async {
      await pumpWidgetSimple(tester, const AvatarWidget());

      expect(find.byType(Stack), findsWidgets);
    });
  });
}
