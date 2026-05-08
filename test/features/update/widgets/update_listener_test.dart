import 'package:budgie_breeding_tracker/core/enums/update_status.dart';
import 'package:budgie_breeding_tracker/data/models/app_version_model.dart';
import 'package:budgie_breeding_tracker/features/update/providers/update_status_provider.dart';
import 'package:budgie_breeding_tracker/features/update/screens/forced_update_screen.dart';
import 'package:budgie_breeding_tracker/features/update/widgets/update_listener.dart';
import 'package:budgie_breeding_tracker/features/update/widgets/update_optional_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const appVersion = AppVersion(
    platform: 'ios',
    latestVersion: '2.0.0',
    latestBuild: 20,
    minSupportedBuild: 10,
    storeUrl: 'https://example.com/store',
    releaseNotesTr: 'Yeni kuluçka uyarıları eklendi.',
  );

  Widget subject(UpdateStatus status) {
    return ProviderScope(
      overrides: [
        updateStatusProvider.overrideWith((ref) async => status),
        appVersionInfoProvider.overrideWith((ref) async => appVersion),
      ],
      child: const MaterialApp(
        home: Scaffold(body: UpdateListener(child: Text('main app'))),
      ),
    );
  }

  testWidgets('renders child when update status is none', (tester) async {
    await pumpLocalizedApp(tester, subject(UpdateStatus.none));

    expect(find.text('main app'), findsOneWidget);
    expect(find.byType(ForcedUpdateScreen), findsNothing);
    expect(find.byType(UpdateOptionalSheet), findsNothing);
  });

  testWidgets('replaces child with forced update screen', (tester) async {
    await pumpLocalizedApp(tester, subject(UpdateStatus.forced));

    expect(find.byType(ForcedUpdateScreen), findsOneWidget);
    expect(find.text('main app'), findsNothing);
    expect(find.text('update.forced_title'), findsOneWidget);
    expect(find.text('update.update_now'), findsOneWidget);
  });

  testWidgets('shows optional update sheet while keeping child rendered', (
    tester,
  ) async {
    await pumpLocalizedApp(tester, subject(UpdateStatus.optional));

    expect(find.text('main app'), findsOneWidget);
    expect(find.byType(UpdateOptionalSheet), findsOneWidget);
    expect(find.text('update.title'), findsOneWidget);
    expect(find.text('update.later'), findsOneWidget);
  });

  testWidgets('does not reopen optional sheet after it is dismissed', (
    tester,
  ) async {
    await pumpLocalizedApp(tester, subject(UpdateStatus.optional));
    expect(find.byType(UpdateOptionalSheet), findsOneWidget);

    await tester.tap(find.text('update.later'));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateOptionalSheet), findsNothing);

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(UpdateOptionalSheet), findsNothing);
    expect(find.text('main app'), findsOneWidget);
  });
}
