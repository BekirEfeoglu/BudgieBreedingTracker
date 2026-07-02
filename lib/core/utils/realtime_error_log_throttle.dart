import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Throttles repeated realtime-subscription error logs.
///
/// The Supabase realtime client retries a channel indefinitely on its own
/// with no cap from caller code — a persistent connectivity issue (bad
/// network, or the `EADDRNOTAVAIL` errno-49 pattern seen on iOS Simulator)
/// would otherwise call `AppLogger.warning` on every retry forever.
/// `AppLogger.warning` always attaches a Sentry breadcrumb (unlike `debug`,
/// which only does in non-release builds), and Sentry keeps at most ~100
/// breadcrumbs — an unthrottled reconnect loop can fully displace useful
/// context before a real crash is captured. After [maxWarnings] consecutive
/// errors, further logs drop to `AppLogger.debug`.
///
/// One instance per subscription — do not share across independent
/// channels, or one channel's failures would suppress warnings for another.
class RealtimeErrorLogThrottle {
  RealtimeErrorLogThrottle({this.maxWarnings = 5});

  final int maxWarnings;
  int _consecutiveErrors = 0;

  void logError(String message) {
    _consecutiveErrors++;
    if (_consecutiveErrors <= maxWarnings) {
      AppLogger.warning(message);
    } else {
      AppLogger.debug(message);
    }
  }

  /// Restores the warning budget, e.g. after a successful reconnect.
  void reset() => _consecutiveErrors = 0;
}
