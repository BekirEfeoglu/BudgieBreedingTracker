import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  // Widgets that pass an explicit locale to DateFormat (e.g. `.yMd('tr')`)
  // throw LocaleDataException without initialized symbol data. Runtime
  // bootstrap (main.dart → EasyLocalization) calls this; tests bypass that
  // path so we initialize once here. Wave 1 of the 2026-05-21 audit
  // introduced widespread locale-aware DateFormat usage.
  await initializeDateFormatting();
  await testMain();
}
