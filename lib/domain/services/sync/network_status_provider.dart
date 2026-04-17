import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides current network connectivity status as a live stream.
///
/// Uses [Connectivity] for quick offline detection, then verifies
/// actual internet access via DNS lookup to catch captive portals
/// and WiFi-without-internet scenarios.
final networkStatusProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.asyncMap((results) async {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) return false;

    // Verify actual internet access (not just WiFi connection)
    return _verifyInternetAccess();
  });
});

/// Verifies actual internet connectivity via DNS lookup.
///
/// Returns `true` if DNS resolution succeeds within the timeout,
/// `false` otherwise (captive portal, no internet, etc.).
Future<bool> _verifyInternetAccess() async {
  try {
    final result = await InternetAddress.lookup(
      'dns.google',
    ).timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
