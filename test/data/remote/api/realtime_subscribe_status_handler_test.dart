import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:supabase_flutter/supabase_flutter.dart'
    show RealtimeSubscribeStatus;

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/realtime_error_log_throttle.dart';
import 'package:budgie_breeding_tracker/data/remote/api/realtime_subscribe_status_handler.dart';

void main() {
  setUp(AppLogger.clearRecentLogs);

  int warnings() =>
      AppLogger.recentLogs.where((e) => e.level == Level.warning).length;
  int debugs() =>
      AppLogger.recentLogs.where((e) => e.level == Level.debug).length;

  void feed(
    RealtimeErrorLogThrottle throttle,
    RealtimeSubscribeStatus status, {
    Object? error,
  }) {
    handleRealtimeSubscribeStatus(
      status: status,
      throttle: throttle,
      message: 'realtime $status ${error ?? ''}',
    );
  }

  group('handleRealtimeSubscribeStatus', () {
    test('caps warnings across a channelError/timedOut reconnect loop', () {
      // Regression: the SDK reports `timedOut`/`closed` with a null error during
      // a reconnect loop. Previously the caller reset the throttle on any
      // null-error status, clearing the budget between every `channelError` and
      // flooding warnings forever. The cap must survive the loop.
      final throttle = RealtimeErrorLogThrottle(maxWarnings: 3);

      for (var i = 0; i < 6; i++) {
        feed(throttle, RealtimeSubscribeStatus.channelError, error: 'e$i');
        feed(throttle, RealtimeSubscribeStatus.timedOut);
      }

      expect(warnings(), 3);
    });

    test('closed neither logs nor resets the warning budget', () {
      final throttle = RealtimeErrorLogThrottle(maxWarnings: 2);

      feed(throttle, RealtimeSubscribeStatus.channelError, error: 'a');
      feed(throttle, RealtimeSubscribeStatus.channelError, error: 'b');
      feed(throttle, RealtimeSubscribeStatus.closed);
      feed(throttle, RealtimeSubscribeStatus.channelError, error: 'c');

      // If `closed` had reset the budget, the third error would warn again.
      expect(warnings(), 2);
      expect(debugs(), 1);
    });

    test('subscribed resets the warning budget', () {
      final throttle = RealtimeErrorLogThrottle(maxWarnings: 2);

      feed(throttle, RealtimeSubscribeStatus.channelError, error: 'a');
      feed(throttle, RealtimeSubscribeStatus.channelError, error: 'b');
      feed(throttle, RealtimeSubscribeStatus.channelError, error: 'c');
      feed(throttle, RealtimeSubscribeStatus.subscribed);
      feed(throttle, RealtimeSubscribeStatus.channelError, error: 'd');

      expect(warnings(), 3); // a, b, d
    });

    test('timedOut is logged (throttled), not silently dropped', () {
      final throttle = RealtimeErrorLogThrottle(maxWarnings: 5);

      feed(throttle, RealtimeSubscribeStatus.timedOut);

      expect(warnings(), 1);
    });
  });
}
