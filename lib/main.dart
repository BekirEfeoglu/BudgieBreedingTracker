import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/utils/logger.dart';

void main() async {
  final totalSw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers to prevent silent white screen on uncaught errors
  FlutterError.onError = (details) {
    AppLogger.error('[FlutterError]', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('[PlatformError]', error, stack);
    return true;
  };

  // Graceful error boundary in release; keep red screen in debug for diagnostics
  if (kReleaseMode) {
    ErrorWidget.builder = (details) {
      return const SizedBox.shrink();
    };
  }

  // Run EasyLocalization init in parallel with bootstrap pre-init.
  // Overall timeout prevents permanent white screen if any step hangs.
  final parallelSw = Stopwatch()..start();
  int easyLocMs = 0;
  try {
    final easyLocSw = Stopwatch()..start();
    final easyLocFuture = EasyLocalization.ensureInitialized().whenComplete(() {
      easyLocMs = easyLocSw.elapsedMilliseconds;
    });
    await Future.wait([
      easyLocFuture,
      bootstrapPreInit(),
    ]).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        AppLogger.warning(
          'Bootstrap timed out after 15s, proceeding to runApp',
        );
        return [null, null];
      },
    );
  } catch (e, st) {
    AppLogger.error('Bootstrap failed, proceeding to runApp', e, st);
  }
  final parallelMs = parallelSw.elapsedMilliseconds;
  if (kDebugMode || const bool.fromEnvironment('PROFILE_STARTUP')) {
    AppLogger.info('[bootstrap] phase EasyLocalization.ensureInitialized: ${easyLocMs}ms');
    AppLogger.info('[bootstrap] phase parallel(easyLoc+preInit): ${parallelMs}ms');
  }

  final runSw = Stopwatch()..start();
  await bootstrapRun(() {
    return EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      child: ProviderScope(
        retry: (retryCount, error) => null,
        child: const BudgieBreedingApp(),
      ),
    );
  });
  final runMs = runSw.elapsedMilliseconds;
  final totalMs = totalSw.elapsedMilliseconds;
  if (kDebugMode || const bool.fromEnvironment('PROFILE_STARTUP')) {
    AppLogger.info('[bootstrap] phase bootstrapRun(sentry+runApp): ${runMs}ms');
  }
  AppLogger.info(
    '[bootstrap] total: ${totalMs}ms '
    '(easyLoc=${easyLocMs}ms, parallel=${parallelMs}ms, run=${runMs}ms)',
  );
}
