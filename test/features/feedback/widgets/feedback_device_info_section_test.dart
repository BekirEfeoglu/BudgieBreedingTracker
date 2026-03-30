import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_device_info_section.dart';

import '../../../helpers/test_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject(String deviceInfo) =>
      ProviderScope(child: FeedbackDeviceInfoSection(deviceInfo: deviceInfo));

  group('FeedbackDeviceInfoSection', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject('OS: Android 14\nModel: Pixel 7'),
      );
      expect(find.byType(FeedbackDeviceInfoSection), findsOneWidget);
    });

    testWidgets('contains an ExpansionTile', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject('OS: Android 14\nModel: Pixel 7'),
      );
      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('shows device_info title key text', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject('OS: Android 14'));
      expect(
        find.text(resolvedL10n('feedback.device_info')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows device_info_desc subtitle key text', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject('OS: Android 14'));
      expect(
        find.text(resolvedL10n('feedback.device_info_desc')),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('expands tile and shows key-value pairs', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject('OS: Android 14\nModel: Pixel 7'),
      );
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('OS'), findsAtLeastNWidgets(1));
    });

    testWidgets('ignores lines without colon separator', (tester) async {
      await pumpTranslatedWidget(
        tester,
        buildSubject('NoColonLine\nOS: Android 14'),
      );
      expect(find.byType(FeedbackDeviceInfoSection), findsOneWidget);
    });

    testWidgets('handles empty device info string', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject(''));
      expect(find.byType(FeedbackDeviceInfoSection), findsOneWidget);
    });

    testWidgets('value with multiple colons is preserved', (tester) async {
      await pumpTranslatedWidget(tester, buildSubject('Time: 12:30:00'));
      await tester.tap(find.byType(ExpansionTile));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('12:30:00'), findsAtLeastNWidgets(1));
    });
  });
}
