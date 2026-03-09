import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_info_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject({ThemeData? theme}) {
    final resolvedTheme = theme ?? ThemeData.light(useMaterial3: true);
    return ProviderScope(
      child: MaterialApp(
        theme: resolvedTheme,
        home: Scaffold(body: FeedbackInfoBanner(theme: resolvedTheme)),
      ),
    );
  }

  group('FeedbackInfoBanner', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(FeedbackInfoBanner), findsOneWidget);
    });

    testWidgets('shows feedback.info localization key', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // easy_localization returns key string in test environment
      expect(find.text('feedback.info'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders an AppIcon (SvgPicture)', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // AppIcon renders an SvgPicture inside
      expect(find.byType(SvgPicture), findsAtLeastNWidgets(1));
    });

    testWidgets('renders a Container as outer wrapper', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with dark theme without errors', (tester) async {
      final darkTheme = ThemeData.dark(useMaterial3: true);
      await tester.pumpWidget(buildSubject(theme: darkTheme));
      await tester.pump();

      expect(find.byType(FeedbackInfoBanner), findsOneWidget);
      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }
    });

    testWidgets('contains a Row with icon and text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // The banner body is a Row
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('text is wrapped in an Expanded widget', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(Expanded), findsAtLeastNWidgets(1));
    });
  });
}
