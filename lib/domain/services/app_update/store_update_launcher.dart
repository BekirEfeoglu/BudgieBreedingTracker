import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/logger.dart';

enum StoreUpdatePlatform { ios, android, other }

typedef StoreMethodInvoker =
    Future<T?> Function<T>(String method, Map<String, Object?> arguments);
typedef StoreExternalLauncher = Future<bool> Function(Uri uri);

final storeUpdateLauncherProvider = Provider<StoreUpdateLauncher>((ref) {
  return const StoreUpdateLauncher();
});

class StoreUpdateLauncher {
  const StoreUpdateLauncher({
    StoreUpdatePlatform? platform,
    StoreMethodInvoker? invokeMethod,
    StoreExternalLauncher? launchExternal,
  }) : _platform = platform,
       _invokeMethod = invokeMethod,
       _launchExternal = launchExternal;

  static const String channelName =
      'com.budgiebreeding.budgie_breeding_tracker/store_update';

  static const MethodChannel _channel = MethodChannel(channelName);

  final StoreUpdatePlatform? _platform;
  final StoreMethodInvoker? _invokeMethod;
  final StoreExternalLauncher? _launchExternal;

  Future<bool> openStore(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl.trim());
    if (uri == null || !_isSupportedUri(uri)) return false;

    final platform = _platform ?? _currentPlatform();
    if (platform == StoreUpdatePlatform.ios) {
      final appId = appStoreProductId(uri);
      if (appId != null) {
        final opened = await _invokeNativeBool('openAppStoreProduct', {
          'appId': appId,
        });
        if (opened) return true;
      }
    }

    if (platform == StoreUpdatePlatform.android) {
      final packageName = playStorePackageName(uri);
      if (packageName != null) {
        final opened = await _invokeNativeBool('openPlayStore', {
          'url': uri.toString(),
          'packageName': packageName,
        });
        if (opened) return true;
      }
    }

    return _launchExternalUri(uri);
  }

  static String? appStoreProductId(Uri uri) {
    final match = RegExp(r'(?:^|/)id(\d+)(?:\D|$)').firstMatch(uri.toString());
    return match?.group(1);
  }

  static String? playStorePackageName(Uri uri) {
    final packageName = uri.queryParameters['id']?.trim();
    return packageName == null || packageName.isEmpty ? null : packageName;
  }

  static StoreUpdatePlatform _currentPlatform() {
    if (Platform.isIOS) return StoreUpdatePlatform.ios;
    if (Platform.isAndroid) return StoreUpdatePlatform.android;
    return StoreUpdatePlatform.other;
  }

  Future<bool> _invokeNativeBool(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      final invoke =
          _invokeMethod ??
          <T>(method, arguments) => _channel.invokeMethod<T>(method, arguments);
      return await invoke<bool>(method, arguments) ?? false;
    } catch (e, st) {
      AppLogger.warning('[AppUpdate] Native store launcher failed: $e');
      AppLogger.error('[AppUpdate] Native store launcher error', e, st);
      return false;
    }
  }

  Future<bool> _launchExternalUri(Uri uri) async {
    try {
      final launch =
          _launchExternal ??
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
      return launch(uri);
    } catch (e, st) {
      AppLogger.error('[AppUpdate] Store URL launch failed', e, st);
      return false;
    }
  }

  bool _isSupportedUri(Uri uri) {
    if (uri.scheme != 'https' &&
        uri.scheme != 'http' &&
        uri.scheme != 'market') {
      return false;
    }
    return uri.host.isNotEmpty;
  }
}
