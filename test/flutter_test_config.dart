import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';

/// Golden comparator that tolerates a tiny fraction of differing pixels.
///
/// The CI golden job regenerates masters then verifies, so this only absorbs
/// cross-process sub-pixel non-determinism (icon glyph anti-aliasing + decorative
/// box-shadow blur). Real regressions differ by far more than the threshold.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile, {required this.threshold});

  /// Max fraction (0..1) of differing pixels still considered a pass.
  final double threshold;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= threshold) {
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Tolerate sub-pixel golden noise (anti-aliasing + blurred shadows) that the
  // regenerate-then-verify CI job would otherwise flag as a flake.
  final existingComparator = goldenFileComparator;
  if (existingComparator is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenComparator(
      existingComparator.basedir.resolve('flutter_test_config.dart'),
      threshold: 0.01,
    );
  }

  // Globally enable the "reduce motion" accessibility flag for every test so
  // perpetual/decorative animations (pulse, shimmer, scanner, slide-fade
  // entrance) do not run. This keeps `pumpAndSettle` from hanging and prevents
  // entrance-delay timers from leaking, regardless of whether a test uses the
  // shared pump helpers or builds its own MaterialApp.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });

  // Keep test output readable by silencing Easy Localization logs.
  EasyLocalization.logger.enableBuildModes = [];
  AppLogger.silenceConsole = true;
  AppLogger.clearRecentLogs();
  // Prevent fallback recheck timers from leaking into test zones.
  skipFallbackRecheck = true;
  // EasyLocalization.ensureInitialized() uses SharedPreferences internally.
  // Without mock values, the platform channel hangs forever in test env.
  SharedPreferences.setMockInitialValues({});
  // Widgets that pass an explicit locale to DateFormat (e.g. `.yMd('tr')`)
  // throw LocaleDataException without initialized symbol data. Runtime
  // bootstrap (main.dart → EasyLocalization) calls this; tests bypass that
  // path so we initialize once here. Wave 1 of the 2026-05-21 audit
  // introduced widespread locale-aware DateFormat usage.
  await initializeDateFormatting();
  await testMain();
}
