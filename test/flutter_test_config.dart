import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Keep test output readable by silencing Easy Localization logs.
  EasyLocalization.logger.enableBuildModes = [];
  AppLogger.silenceConsole = true;
  AppLogger.clearRecentLogs();
  // Prevent fallback recheck timers from leaking into test zones.
  skipFallbackRecheck = true;
  // EasyLocalization.ensureInitialized() uses SharedPreferences internally.
  // Without mock values, the platform channel hangs forever in test env.
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
