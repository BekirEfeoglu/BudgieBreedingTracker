import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/constants/admin_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_capacity_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_monitoring_snapshot_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_monitoring_content.dart';

import '../../../helpers/test_localization.dart';

/// This test mounts REAL translations (`pumpTranslatedWidget`) because it
/// asserts on a formatted DB limit ('/ 500 MB') that comes from a translated
/// template. easy_localization caches translations in a process-static keyed by
/// locale, so loading real 'tr' strings here pollutes any later raw-key l10n
/// assertion that runs in the SAME isolate. It therefore lives in its own file:
/// `flutter test` runs each file in a separate isolate, which guarantees this
/// real-translation load can never leak into the raw-key assertions in
/// admin_monitoring_content_test.dart under a shuffled order
/// (test-stability.md § Triage #3 / anti-patterns #2, #9).
void main() {
  group('MonitoringContent (real translations)', () {
    testWidgets(
      'shows Free plan database limit when provider returns free cap',
      (tester) async {
        await pumpTranslatedWidget(
          tester,
          ProviderScope(
            overrides: [
              monitoringSnapshotsProvider.overrideWith(
                (_) async => const MonitoringTrend(),
              ),
              dbSizeLimitProvider.overrideWith(
                (_) async => AdminConstants.dbSizeLimitForPlan('free'),
              ),
            ],
            child: const MonitoringContent(
              capacity: ServerCapacity(databaseSizeBytes: 25 * 1024 * 1024),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('/ 500 MB'), findsOneWidget);
        expect(find.text('/ 8.0 GB'), findsNothing);
      },
    );
  });
}
