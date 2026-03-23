import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Keep test output readable by silencing Easy Localization logs.
  EasyLocalization.logger.enableBuildModes = [];
  // EasyLocalization.ensureInitialized() uses SharedPreferences internally.
  // Without mock values, the platform channel hangs forever in test env.
  SharedPreferences.setMockInitialValues({});
  await testMain();
}
