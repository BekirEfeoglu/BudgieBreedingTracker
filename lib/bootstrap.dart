import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
const _compileTimeRevenueCatIos = String.fromEnvironment(
  'REVENUECAT_API_KEY_IOS',
);
const _compileTimeRevenueCatAndroid = String.fromEnvironment(
  'REVENUECAT_API_KEY_ANDROID',
);
const _compileTimeGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
);
const _compileTimeGoogleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
);

const _nativeConfigChannel = MethodChannel(
  'com.budgiebreeding.budgie_breeding_tracker/config',
);

String _resolvedSupabaseUrl = _compileTimeSupabaseUrl;
String _resolvedAnonKey = _compileTimeAnonKey;
String _resolvedSentryDsn = _compileTimeSentryDsn;
String _resolvedSentryEnv = _compileTimeSentryEnv;
String _resolvedRevenueCatIos = _compileTimeRevenueCatIos;
String _resolvedRevenueCatAndroid = _compileTimeRevenueCatAndroid;
String _resolvedGoogleWebClientId = _compileTimeGoogleWebClientId;
String _resolvedGoogleIosClientId = _compileTimeGoogleIosClientId;

/// Resolved RevenueCat API keys — accessible from providers after bootstrap.
String revenueCatApiKeyIos = '';
String revenueCatApiKeyAndroid = '';

/// Resolved Google OAuth client IDs — accessible from providers after bootstrap.
String googleWebClientIdResolved = '';
String googleIosClientIdResolved = '';

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
    _resolvedSupabaseUrl.isNotEmpty && _resolvedAnonKey.isNotEmpty;

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

    // Android fallback: read config injected from Gradle (env/local.properties/.env).
    await _resolveAndroidBuildConfigFallbacks();

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
  if (_resolvedSentryDsn.isNotEmpty) {
    try {
      await SentryFlutter.init(
        (options) {
          options.dsn = _resolvedSentryDsn;
          options.tracesSampleRate = 0.3;
          options.environment = _resolvedSentryEnv;
          options.sendDefaultPii = false;
          options.beforeSend = _beforeSendSentry;
        },
        appRunner: () async {
          runApp(await appBuilder());
        },
      );
    } catch (e, st) {
      AppLogger.error(
        'Sentry initialization failed, launching without it',
        e,
        st,
      );
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
    'URL: ${_resolvedSupabaseUrl.isNotEmpty ? 'present' : 'MISSING'}, '
    'Key: ${_resolvedAnonKey.isNotEmpty ? 'present' : 'MISSING'}',
  );

  if (hasSupabaseCredentials) {
    try {
      await Supabase.initialize(
        url: _resolvedSupabaseUrl,
        anonKey: _resolvedAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      AppLogger.info('Supabase initialized successfully');
    } catch (e, st) {
      AppLogger.error(
        'Supabase initialization failed: ${e.runtimeType}: $e',
        e,
        st,
      );
    }
  } else {
    AppLogger.warning(
      'Supabase credentials not provided. '
      'Use --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>',
    );
  }
}

void _resolveRevenueCatKeys() {
  revenueCatApiKeyIos = _resolvedRevenueCatIos;
  revenueCatApiKeyAndroid = _resolvedRevenueCatAndroid;
  googleWebClientIdResolved = _resolvedGoogleWebClientId;
  googleIosClientIdResolved = _resolvedGoogleIosClientId;
}

Future<void> _resolveAndroidBuildConfigFallbacks() async {
  if (!Platform.isAndroid) return;

  try {
    final config = await _nativeConfigChannel.invokeMapMethod<String, dynamic>(
      'getConfig',
    );
    if (config == null || config.isEmpty) return;

    _resolvedSupabaseUrl = _preferNonEmpty(
      _resolvedSupabaseUrl,
      config['SUPABASE_URL'],
    );
    _resolvedAnonKey = _preferNonEmpty(
      _resolvedAnonKey,
      config['SUPABASE_ANON_KEY'],
    );
    _resolvedSentryDsn = _preferNonEmpty(
      _resolvedSentryDsn,
      config['SENTRY_DSN'],
    );
    _resolvedSentryEnv = _preferNonEmpty(
      _resolvedSentryEnv,
      config['SENTRY_ENVIRONMENT'],
    );
    _resolvedRevenueCatIos = _preferNonEmpty(
      _resolvedRevenueCatIos,
      config['REVENUECAT_API_KEY_IOS'],
    );
    _resolvedRevenueCatAndroid = _preferNonEmpty(
      _resolvedRevenueCatAndroid,
      config['REVENUECAT_API_KEY_ANDROID'],
    );
    _resolvedGoogleWebClientId = _preferNonEmpty(
      _resolvedGoogleWebClientId,
      config['GOOGLE_WEB_CLIENT_ID'],
    );
    _resolvedGoogleIosClientId = _preferNonEmpty(
      _resolvedGoogleIosClientId,
      config['GOOGLE_IOS_CLIENT_ID'],
    );
  } catch (e) {
    AppLogger.warning('[Bootstrap] Android config fallback unavailable: $e');
  }
}

/// Filters out noisy Sentry events that are expected in sandbox/debug.
///
/// - Purchase errors caused by sandbox testing (store problem, billing
///   unavailable, not activated) are dropped to avoid polluting dashboards.
/// - Debug builds are excluded entirely.
SentryEvent? _beforeSendSentry(SentryEvent event, Hint hint) {
  // Drop all events in debug mode
  if (kDebugMode) return null;

  final exceptions = event.exceptions ?? [];
  for (final ex in exceptions) {
    final value = (ex.value ?? '').toString();
    // Sandbox IAP errors — expected during App Store review testing
    if (value.contains('purchase_not_activated') ||
        value.contains('BILLING_UNAVAILABLE') ||
        value.contains('BILLING SERVICE UNAVAILABLE') ||
        value.contains('purchase_store_problem') ||
        value.contains('STOREKIT_ERROR')) {
      AppLogger.info('[Sentry] Filtered sandbox purchase error: $value');
      return null;
    }
  }

  return event;
}

String _preferNonEmpty(String primary, Object? fallback) {
  final trimmedPrimary = primary.trim();
  if (trimmedPrimary.isNotEmpty) return trimmedPrimary;
  return fallback?.toString().trim() ?? '';
}
