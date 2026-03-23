import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_info_banner.dart';

import '../../../helpers/test_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject({ThemeData? theme}) {
    final resolvedTheme = theme ?? ThemeData.light(useMaterial3: true);
    return ProviderScope(
      child: MaterialApp(
        theme: resolvedTheme,
        home: const Scaffold(body: FeedbackInfoBanner()),
      ),
    );
  }

  group('FeedbackInfoBanner', () {
    testWidgets('renders without errors', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      expect(find.byType(FeedbackInfoBanner), findsOneWidget);
    });

    testWidgets('shows feedback.info localization key', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      // easy_localization returns key string in test environment
      expect(find.text('feedback.info'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders an AppIcon (SvgPicture)', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      // AppIcon renders an SvgPicture inside
      expect(find.byType(SvgPicture), findsAtLeastNWidgets(1));
    });

    testWidgets('renders a Container as outer wrapper', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with dark theme without errors', (tester) async {
      final darkTheme = ThemeData.dark(useMaterial3: true);
      await pumpLocalizedApp(tester,buildSubject(theme: darkTheme));
      expect(find.byType(FeedbackInfoBanner), findsOneWidget);
    });

    testWidgets('contains a Row with icon and text', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      // The banner body is a Row
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('text is wrapped in an Expanded widget', (tester) async {
      await pumpLocalizedApp(tester,buildSubject());
      expect(find.byType(Expanded), findsAtLeastNWidgets(1));
    });
  });
}
