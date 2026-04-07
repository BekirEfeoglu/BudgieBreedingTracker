import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

void main() {
  testWidgets('calendar navigation icon renders without exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: IconTheme(
              data: IconThemeData(size: 24, color: Colors.black87),
              child: AppIcon(AppIcons.calendar),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppIcon), findsOneWidget);
  });
}
