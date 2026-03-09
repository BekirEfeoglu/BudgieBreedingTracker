import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/utils/logger.dart';

/// Compile-time environment values (from --dart-define or --dart-define-from-file).
const _compileTimeSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _compileTimeAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _compileTimeSentryDsn = String.fromEnvironment('SENTRY_DSN');
const _compileTimeSentryEnv = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: 'production',
);
const _compileTimeRevenueCatIos =
    String.fromEnvironment('REVENUECAT_API_KEY_IOS');
const _compileTimeRevenueCatAndroid =
    String.fromEnvironment('REVENUECAT_API_KEY_ANDROID');

/// Resolved RevenueCat API keys — accessible from providers after bootstrap.
String revenueCatApiKeyIos = '';
String revenueCatApiKeyAndroid = '';

bool _isSupabaseInitialized() {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

/// Returns true if required Supabase compile-time credentials are present.
bool get hasSupabaseCredentials =>
    _compileTimeSupabaseUrl.isNotEmpty && _compileTimeAnonKey.isNotEmpty;

/// Ensures Supabase is initialized, retrying on demand when bootstrap timed out.
Future<bool> ensureSupabaseInitialized({
  Duration timeout = const Duration(seconds: 10),
}) async {
  if (_isSupabaseInitialized()) return true;
  if (!hasSupabaseCredentials) {
    AppLogger.warning(
      'Supabase credentials missing; cannot initialize at runtime',
    );
    return false;
  }
  try {
    await _initSupabase().timeout(timeout);
  } on TimeoutException {
    AppLogger.warning(
      'Supabase initialization timed out after ${timeout.inSeconds}s',
    );
  } catch (e, st) {
    AppLogger.error('Supabase runtime initialization failed', e, st);
  }
  return _isSupabaseInitialized();
}

/// Phase 1: Pre-init — runs in parallel with EasyLocalization.
/// Orientation lock and Supabase init run concurrently.
/// Has an overall timeout to prevent permanent white screen.
Future<void> bootstrapPreInit() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Supabase init — apply timeout to prevent indefinite hang on network issues.
    await ensureSupabaseInitialized(timeout: const Duration(seconds: 10));

    // Resolve RevenueCat API keys (sync, no await needed)
    _resolveRevenueCatKeys();
  } catch (e, st) {
    AppLogger.error('Bootstrap pre-init failed, continuing to runApp', e, st);
  }
}

/// Phase 2: Run the app with optional Sentry wrapping.
/// Always ensures [runApp] is called even if Sentry initialization fails.
Future<void> bootstrapRun(FutureOr<Widget> Function() appBuilder) async {
  if (_compileTimeSentryDsn.isNotEmpty) {
    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = _compileTimeSentryDsn;
          options.tracesSampleRate = 0.3;
          options.environment = _compileTimeSentryEnv;
          options.sendDefaultPii = false;
        },
        appRunner: () async {
          runApp(await appBuilder());
        },
      );
    } catch (e, st) {
      AppLogger.error('Sentry initialization failed, launching without it', e, st);
      runApp(await appBuilder());
    }
  } else {
    AppLogger.info('Sentry DSN not provided, skipping Sentry initialization');
    runApp(await appBuilder());
  }
}

Future<void> _initSupabase() async {
  AppLogger.info(
    'Supabase credentials — '
    'URL: ${_compileTimeSupabaseUrl.isNotEmpty ? 'present' : 'MISSING'}, '
    'Key: ${_compileTimeAnonKey.isNotEmpty ? 'present' : 'MISSING'}',
  );

  if (hasSupabaseCredentials) {
    try {
      await Supabase.initialize(
        url: _compileTimeSupabaseUrl,
        anonKey: _compileTimeAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      AppLogger.info('Supabase initialized successfully');
    } catch (e, st) {
      AppLogger.error('Supabase initialization failed: ${e.runtimeType}: $e', e, st);
    }
  } else {
    AppLogger.warning(
      'Supabase credentials not provided. '
      'Use --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>',
    );
  }
}

void _resolveRevenueCatKeys() {
  revenueCatApiKeyIos = _compileTimeRevenueCatIos;
  revenueCatApiKeyAndroid = _compileTimeRevenueCatAndroid;
}
