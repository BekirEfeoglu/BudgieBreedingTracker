import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart' show Level;
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/realtime_error_log_throttle.dart';

void main() {
  setUp(AppLogger.clearRecentLogs);

  group('RealtimeErrorLogThrottle', () {
    test('logs the first N consecutive errors as warnings', () {
      final throttle = RealtimeErrorLogThrottle(maxWarnings: 3);

      for (var i = 0; i < 3; i++) {
        throttle.logError('boom $i');
      }

      final warningCount = AppLogger.recentLogs
          .where((e) => e.level == Level.warning)
          .length;
      expect(warningCount, 3);
    });

    test(
      'switches to debug-level logging after maxWarnings consecutive errors',
      () {
        final throttle = RealtimeErrorLogThrottle(maxWarnings: 3);

        for (var i = 0; i < 10; i++) {
          throttle.logError('boom $i');
        }

        final warningCount = AppLogger.recentLogs
            .where((e) => e.level == Level.warning)
            .length;
        final debugCount = AppLogger.recentLogs
            .where((e) => e.level == Level.debug)
            .length;
        expect(warningCount, 3);
        expect(debugCount, 7);
      },
    );

    test('reset() restores the warning budget', () {
      final throttle = RealtimeErrorLogThrottle(maxWarnings: 2);

      throttle.logError('a');
      throttle.logError('b');
      throttle.logError('c'); // debug now
      throttle.reset();
      throttle.logError('d'); // warning again after reset

      final warningCount = AppLogger.recentLogs
          .where((e) => e.level == Level.warning)
          .length;
      expect(warningCount, 3); // a, b, d
    });

    test('defaults maxWarnings to 5, matching RealtimeSyncService', () {
      final throttle = RealtimeErrorLogThrottle();
      expect(throttle.maxWarnings, 5);
    });
  });
}
