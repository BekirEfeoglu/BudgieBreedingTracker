import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/security/certificate_pinning.dart';
import 'core/utils/logger.dart';

part 'bootstrap_helpers.dart';

bool get _profileStartup =>
    kDebugMode || const bool.fromEnvironment('PROFILE_STARTUP');

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
bool _resolvedIosSimulator = false;

/// Resolved RevenueCat API keys — accessible from providers after bootstrap.
String revenueCatApiKeyIos = '';
String revenueCatApiKeyAndroid = '';

/// Resolved Google OAuth client IDs — accessible from providers after bootstrap.
String googleWebClientIdResolved = '';
String googleIosClientIdResolved = '';
bool isIosSimulatorRuntime = false;

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
  final preInitSw = Stopwatch()..start();
  try {
    final orientationSw = Stopwatch()..start();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final orientationMs = orientationSw.elapsedMilliseconds;

    // Install certificate pinning before any network calls.
    CertificatePinning.install();

    // Native fallback: read config injected from Gradle/Xcode (env/local.properties/.env).
    final nativeCfgSw = Stopwatch()..start();
    await _resolveNativeBuildConfigFallbacks();
    final nativeCfgMs = nativeCfgSw.elapsedMilliseconds;

    // Supabase init — apply timeout to prevent indefinite hang on network issues.
    final supabaseSw = Stopwatch()..start();
    await ensureSupabaseInitialized(timeout: const Duration(seconds: 10));
    final supabaseMs = supabaseSw.elapsedMilliseconds;

    // Resolve RevenueCat API keys (sync, no await needed)
    _resolveRevenueCatKeys();

    if (_profileStartup) {
      AppLogger.info('[bootstrap] phase setPreferredOrientations: ${orientationMs}ms');
      AppLogger.info('[bootstrap] phase resolveNativeBuildConfig: ${nativeCfgMs}ms');
      AppLogger.info('[bootstrap] phase Supabase.initialize: ${supabaseMs}ms');
      AppLogger.info('[bootstrap] phase bootstrapPreInit total: ${preInitSw.elapsedMilliseconds}ms');
    }
  } catch (e, st) {
    AppLogger.error('Bootstrap pre-init failed, continuing to runApp', e, st);
  }
}

/// Phase 2: Run the app with optional Sentry wrapping.
/// Always ensures [runApp] is called even if Sentry initialization fails.
///
/// Sentry init is capped by [sentryInitTimeout] so a slow DSN handshake or
/// network hiccup can't keep the splash screen pinned. If init times out,
/// the app launches without Sentry and the error is logged.
Future<void> bootstrapRun(
  FutureOr<Widget> Function() appBuilder, {
  Duration sentryInitTimeout = const Duration(seconds: 8),
}) async {
  if (_resolvedSentryDsn.isEmpty) {
    AppLogger.info('Sentry DSN not provided, skipping Sentry initialization');
    runApp(await appBuilder());
    return;
  }

  // Track whether Sentry's appRunner actually launched the app, so we don't
  // call runApp twice on the happy path or miss it entirely on timeout.
  var appLaunched = false;
  final sentrySw = Stopwatch()..start();
  try {
    await SentryFlutter.init(
      (options) {
        options.dsn = _resolvedSentryDsn;
        options.tracesSampleRate = 0.3;
        options.environment = _resolvedSentryEnv;
        options.sendDefaultPii = false;
      },
      appRunner: () async {
        appLaunched = true;
        if (_profileStartup) {
          AppLogger.info(
            '[bootstrap] phase SentryFlutter.init: ${sentrySw.elapsedMilliseconds}ms',
          );
        }
        runApp(await appBuilder());
      },
    ).timeout(sentryInitTimeout);
  } on TimeoutException {
    AppLogger.warning(
      'Sentry initialization timed out after ${sentryInitTimeout.inSeconds}s, '
      'launching without it',
    );
    if (!appLaunched) runApp(await appBuilder());
  } catch (e, st) {
    AppLogger.error(
      'Sentry initialization failed, launching without it',
      e,
      st,
    );
    if (!appLaunched) runApp(await appBuilder());
  }
}

Future<void> _initSupabase() async {
  AppLogger.info(
    'Supabase credentials — '
    'URL: ${_resolvedSupabaseUrl.isNotEmpty ? 'present' : 'MISSING'}, '
    'Key: ${_resolvedAnonKey.isNotEmpty ? 'present' : 'MISSING'}',
  );

  if (hasSupabaseCredentials) {
    // Reject placeholder/test keys in release mode to prevent accidental
    // production deploys with invalid credentials.
    if (!_isValidSupabaseUrl(_resolvedSupabaseUrl) ||
        !_isValidSupabaseApiKey(_resolvedAnonKey)) {
      AppLogger.warning(
        'Supabase credentials appear invalid or are placeholders. '
        'Check SUPABASE_URL and SUPABASE_ANON_KEY values.',
      );
      return;
    }
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
  isIosSimulatorRuntime = _resolvedIosSimulator;

  // Warn at startup if RevenueCat keys are missing — purchases will be
  // disabled at runtime but the app will still function in free-tier mode.
  final platformKey = Platform.isIOS ? revenueCatApiKeyIos : revenueCatApiKeyAndroid;
  if (platformKey.isEmpty) {
    AppLogger.warning(
      '[Bootstrap] RevenueCat API key not configured for ${Platform.isIOS ? 'iOS' : 'Android'}. '
      'Premium purchases will be unavailable. '
      'Set REVENUECAT_API_KEY_${Platform.isIOS ? 'IOS' : 'ANDROID'} via --dart-define.',
    );
  }

  // Warn at startup if Google OAuth keys are missing — Google sign-in will
  // fall back to browser OAuth (or fail) without these.
  if (googleWebClientIdResolved.isEmpty) {
    AppLogger.warning(
      '[Bootstrap] GOOGLE_WEB_CLIENT_ID not configured. '
      'Native Google sign-in will be unavailable. '
      'Set via --dart-define or .env file.',
    );
  }
}

Future<void> _resolveNativeBuildConfigFallbacks() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

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
    _resolvedIosSimulator =
        config['IS_IOS_SIMULATOR'] == true || _resolvedIosSimulator;
  } catch (e) {
    AppLogger.warning('[Bootstrap] Native config fallback unavailable: $e');
  }
}
