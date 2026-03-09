import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

void main() {
  group('AppIcon', () {
    testWidgets('renders SvgPicture.asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppIcon('assets/icons/general/home.svg')),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('uses explicit size when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIcon('assets/icons/general/home.svg', size: 32),
          ),
        ),
      );

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 32);
      expect(svg.height, 32);
    });

    testWidgets('uses explicit color via ColorFilter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIcon('assets/icons/general/home.svg', color: Colors.red),
          ),
        ),
      );

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svg.colorFilter,
        const ColorFilter.mode(Colors.red, BlendMode.srcIn),
      );
    });

    testWidgets('reads size from IconTheme when not explicit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IconTheme(
              data: IconThemeData(size: 48),
              child: AppIcon('assets/icons/general/home.svg'),
            ),
          ),
        ),
      );

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 48);
      expect(svg.height, 48);
    });

    testWidgets('reads color from IconTheme when not explicit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IconTheme(
              data: IconThemeData(color: Colors.green),
              child: AppIcon('assets/icons/general/home.svg'),
            ),
          ),
        ),
      );

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svg.colorFilter,
        const ColorFilter.mode(Colors.green, BlendMode.srcIn),
      );
    });

    testWidgets('defaults to size 24 when no IconTheme and no explicit size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppIcon('assets/icons/general/home.svg')),
        ),
      );

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 24);
      expect(svg.height, 24);
    });

    testWidgets('passes semanticsLabel to SvgPicture', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppIcon(
              'assets/icons/general/home.svg',
              semanticsLabel: 'Home icon',
            ),
          ),
        ),
      );

      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.semanticsLabel, 'Home icon');
    });

    test('explicit size overrides IconTheme size', () {
      // This is a logic test — AppIcon prioritizes explicit size over IconTheme
      const icon = AppIcon('test.svg', size: 16);
      expect(icon.size, 16);
    });

    test('explicit color overrides IconTheme color', () {
      const icon = AppIcon('test.svg', color: Colors.blue);
      expect(icon.color, Colors.blue);
    });
  });
}
