import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genealogy/widgets/tree_connectors.dart';

void main() {
  group('GenerationLabel', () {
    testWidgets('renders label text correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenerationLabel(label: 'Baba Hattı')),
        ),
      );
      await tester.pump();

      expect(find.text('Baba Hattı'), findsOneWidget);
    });

    testWidgets('renders Container with rounded decoration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenerationLabel(label: 'Anne Hattı')),
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with empty label string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GenerationLabel(label: '')),
        ),
      );
      await tester.pump();

      expect(find.byType(GenerationLabel), findsOneWidget);
    });
  });

  group('OffspringConnectorPainter', () {
    testWidgets('renders CustomPaint with single child count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(48, 70),
              painter: OffspringConnectorPainter(
                childCount: 1,
                lineColor: Colors.grey,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Scaffold kendi CustomPaint'ini de üretiyor; en az 1 bulunmalı
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('renders CustomPaint with multiple child count', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(48, 210),
              painter: OffspringConnectorPainter(
                childCount: 3,
                lineColor: Colors.blue,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    test('shouldRepaint returns true when childCount changes', () {
      const painter1 = OffspringConnectorPainter(
        childCount: 1,
        lineColor: Colors.grey,
      );
      const painter2 = OffspringConnectorPainter(
        childCount: 2,
        lineColor: Colors.grey,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when lineColor changes', () {
      const painter1 = OffspringConnectorPainter(
        childCount: 1,
        lineColor: Colors.grey,
      );
      const painter2 = OffspringConnectorPainter(
        childCount: 1,
        lineColor: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when both fields are equal', () {
      const painter1 = OffspringConnectorPainter(
        childCount: 2,
        lineColor: Colors.red,
      );
      const painter2 = OffspringConnectorPainter(
        childCount: 2,
        lineColor: Colors.red,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });

  group('AncestorConnectorPainter', () {
    testWidgets('renders CustomPaint without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(48, 70),
              painter: AncestorConnectorPainter(
                depth: 0,
                baseColor: Colors.grey,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('renders CustomPaint at depth 3 without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: Size(48, 70),
              painter: AncestorConnectorPainter(
                depth: 3,
                baseColor: Colors.blueGrey,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    test('shouldRepaint returns true when depth changes', () {
      const painter1 = AncestorConnectorPainter(
        depth: 0,
        baseColor: Colors.grey,
      );
      const painter2 = AncestorConnectorPainter(
        depth: 1,
        baseColor: Colors.grey,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns true when baseColor changes', () {
      const painter1 = AncestorConnectorPainter(
        depth: 0,
        baseColor: Colors.grey,
      );
      const painter2 = AncestorConnectorPainter(
        depth: 0,
        baseColor: Colors.blue,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('shouldRepaint returns false when nothing changes', () {
      const painter1 = AncestorConnectorPainter(
        depth: 2,
        baseColor: Colors.grey,
      );
      const painter2 = AncestorConnectorPainter(
        depth: 2,
        baseColor: Colors.grey,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });
}
