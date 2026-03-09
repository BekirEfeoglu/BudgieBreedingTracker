import 'dart:async';

import 'package:easy_localization/easy_localization.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Keep test output readable by silencing Easy Localization logs.
  EasyLocalization.logger.enableBuildModes = [];
  await testMain();
}
