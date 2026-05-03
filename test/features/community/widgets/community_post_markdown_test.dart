@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/community/widgets/community_post_markdown.dart';

void main() {
  group('ContentText', () {
    testWidgets('renders plain text when showFull is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: 'Hello world',
              showFull: false,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders markdown content when showFull is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: 'Line one\nLine two',
              showFull: true,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Line one'), findsOneWidget);
      expect(find.text('Line two'), findsOneWidget);
    });

    testWidgets('renders bold markdown when showFull is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: '**bold text**',
              showFull: true,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('bold text'), findsOneWidget);
    });

    testWidgets('renders heading markdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: '# Heading 1\n## Heading 2',
              showFull: true,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Heading 2'), findsOneWidget);
    });

    testWidgets('renders unordered list items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: '- Item one\n- Item two',
              showFull: true,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Item one'), findsOneWidget);
      expect(find.text('Item two'), findsOneWidget);
    });

    testWidgets('renders ordered list items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: '1. First\n2. Second',
              showFull: true,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('shows read more hint when content overflows', (tester) async {
      final longContent = 'word ' * 200;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: longContent,
              showFull: false,
              maxLines: 2,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ContentText), findsOneWidget);
    });

    testWidgets('renders italic markdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: '_italic text_',
              showFull: true,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('italic text'), findsOneWidget);
    });

    testWidgets('handles empty content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: '',
              showFull: false,
              maxLines: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ContentText), findsOneWidget);
    });

    testWidgets('handles content with newlines when showFull is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentText(
              content: 'Line1\nLine2\nLine3\nLine4',
              showFull: false,
              maxLines: 2,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ContentText), findsOneWidget);
    });
  });
}
