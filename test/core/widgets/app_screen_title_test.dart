import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';

void main() {
  Widget wrapAppBar(Widget child) {
    return MaterialApp(
      home: Scaffold(appBar: AppBar(title: child)),
    );
  }

  group('AppScreenTitle', () {
    testWidgets('renders provided title text', (tester) async {
      await tester.pumpWidget(
        wrapAppBar(
          const AppScreenTitle(title: 'Screen', iconAsset: AppIcons.bird),
        ),
      );

      expect(find.text('Screen'), findsOneWidget);
    });

    testWidgets('renders AppIcon when icon asset is provided', (tester) async {
      await tester.pumpWidget(
        wrapAppBar(
          const AppScreenTitle(title: 'Birds', iconAsset: AppIcons.bird),
        ),
      );

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('renders Icon when IconData is provided', (tester) async {
      await tester.pumpWidget(
        wrapAppBar(const AppScreenTitle(title: 'Info', icon: Icons.info)),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });
}
