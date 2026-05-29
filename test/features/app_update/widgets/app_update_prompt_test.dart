import 'package:budgie_breeding_tracker/domain/services/app_update/app_update_info.dart';
import 'package:budgie_breeding_tracker/domain/services/app_update/app_update_providers.dart';
import 'package:budgie_breeding_tracker/features/app_update/widgets/app_update_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const updateInfo = AppUpdateInfo(
    latestVersion: '2.0.0',
    latestBuild: 20,
    minSupportedBuild: 10,
    storeUrl: 'https://example.com/store',
    releaseNotesTr: 'Yuva takibi iyilestirildi.',
    releaseNotesEn: 'Nest tracking improved.',
  );

  Widget subject(
    AppUpdateStatus? status, {
    TargetPlatform platform = TargetPlatform.iOS,
  }) {
    return ProviderScope(
      overrides: [appUpdateStatusProvider.overrideWith((ref) async => status)],
      child: MaterialApp(
        // Mount AppUpdatePrompt in the builder (above the Navigator), exactly
        // like app.dart, so the in-tree prompt overlay is exercised the same
        // way it renders in production. The prompt is iOS-only, so simulate the
        // platform via Theme.
        theme: ThemeData(platform: platform),
        builder: (context, child) =>
            AppUpdatePrompt(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Text('app child')),
      ),
    );
  }

  testWidgets('renders child without dialog when no update is available', (
    tester,
  ) async {
    await pumpLocalizedApp(tester, subject(null));

    expect(find.text('app child'), findsOneWidget);
    expect(find.text('app_update.available_title'), findsNothing);
    expect(find.text('app_update.required_title'), findsNothing);
  });

  testWidgets('shows optional update dialog with later action', (tester) async {
    const status = AppUpdateStatus(
      info: updateInfo,
      isUpdateAvailable: true,
      isRequired: false,
      currentVersion: '1.0.0',
      currentBuild: 1,
    );

    await pumpLocalizedApp(tester, subject(status));

    expect(find.text('app child'), findsOneWidget);
    expect(find.text('app_update.available_title'), findsOneWidget);
    expect(find.text('app_update.later'), findsOneWidget);
    expect(find.text('app_update.update_now'), findsOneWidget);
  });

  testWidgets('shows required update dialog without later action', (
    tester,
  ) async {
    const status = AppUpdateStatus(
      info: updateInfo,
      isUpdateAvailable: true,
      isRequired: true,
      currentVersion: '1.0.0',
      currentBuild: 1,
    );

    await pumpLocalizedApp(tester, subject(status));

    expect(find.text('app_update.required_title'), findsOneWidget);
    expect(find.text('app_update.later'), findsNothing);
    expect(find.text('app_update.update_now'), findsOneWidget);
  });

  testWidgets('does not reopen same optional update after dismissal', (
    tester,
  ) async {
    const status = AppUpdateStatus(
      info: updateInfo,
      isUpdateAvailable: true,
      isRequired: false,
      currentVersion: '1.0.0',
      currentBuild: 1,
    );

    await pumpLocalizedApp(tester, subject(status));
    expect(find.text('app_update.available_title'), findsOneWidget);

    await tester.tap(find.text('app_update.later'));
    await tester.pumpAndSettle();
    expect(find.text('app_update.available_title'), findsNothing);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('app_update.available_title'), findsNothing);
    expect(find.text('app child'), findsOneWidget);
  });

  testWidgets(
    'does not show optional update on Android (Play owns that path)',
    (tester) async {
      const status = AppUpdateStatus(
        info: updateInfo,
        isUpdateAvailable: true,
        isRequired: false,
        currentVersion: '1.0.0',
        currentBuild: 1,
      );

      await pumpLocalizedApp(
        tester,
        subject(status, platform: TargetPlatform.android),
      );

      expect(find.text('app child'), findsOneWidget);
      expect(find.text('app_update.available_title'), findsNothing);
      expect(find.text('app_update.required_title'), findsNothing);
    },
  );

  testWidgets('shows required update block on Android', (tester) async {
    const status = AppUpdateStatus(
      info: updateInfo,
      isUpdateAvailable: true,
      isRequired: true,
      currentVersion: '1.0.0',
      currentBuild: 1,
    );

    await pumpLocalizedApp(
      tester,
      subject(status, platform: TargetPlatform.android),
    );

    // DB-driven forced update (currentBuild < min_supported_build) is surfaced
    // on Android as a non-dismissible full-screen block, with no "later".
    expect(find.text('app_update.required_title'), findsOneWidget);
    expect(find.text('app_update.update_now'), findsOneWidget);
    expect(find.text('app_update.later'), findsNothing);
  });
}
