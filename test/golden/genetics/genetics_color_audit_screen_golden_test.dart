@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_theme.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_color_audit_screen.dart';

void main() {
  testWidgets('renders genetics color audit board on iPhone-sized canvas', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      const Size(393, 1024),
      const GeneticsColorAuditScreen(),
    );

    await expectLater(
      find.byType(GeneticsColorAuditScreen),
      matchesGoldenFile('goldens/genetics_color_audit_screen.png'),
    );
  });

  testWidgets('renders primary genetics audit board zoomed for review', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      const Size(920, 980),
      const Scaffold(body: SafeArea(child: GeneticsPrimaryColorAuditBoard())),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/genetics_color_audit_primary_board.png'),
    );
  });

  testWidgets('renders advanced genetics audit board zoomed for review', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      const Size(980, 720),
      const Scaffold(body: SafeArea(child: GeneticsAdvancedColorAuditBoard())),
    );

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/genetics_color_audit_advanced_board.png'),
    );
  });
}

Future<void> _pumpGolden(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}
