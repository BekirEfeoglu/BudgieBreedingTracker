import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers to prevent silent white screen on uncaught errors
  FlutterError.onError = (details) {
    AppLogger.error('[FlutterError]', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('[PlatformError]', error, stack);
    return true;
  };

  // Run EasyLocalization init in parallel with bootstrap pre-init.
  // Overall timeout prevents permanent white screen if any step hangs.
  try {
    await Future.wait([
      EasyLocalization.ensureInitialized(),
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

  await bootstrapRun(() {
    return EasyLocalization(
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
        Locale('de'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      child: ProviderScope(
        retry: (retryCount, error) => null,
        child: const BudgieBreedingApp(),
      ),
    );
  });
}
