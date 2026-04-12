import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

void main() {
  // Sentry must be initialized (or at least not crash) for breadcrumb calls.
  // In tests, Sentry is not initialized, but addBreadcrumb should not throw.

  group('AppLogger — debug', () {
    test('does not throw', () {
      expect(() => AppLogger.debug('test debug message'), returnsNormally);
    });

    test('accepts empty string', () {
      expect(() => AppLogger.debug(''), returnsNormally);
    });

    test('accepts long message', () {
      final longMessage = 'x' * 10000;
      expect(() => AppLogger.debug(longMessage), returnsNormally);
    });
  });

  group('AppLogger — info', () {
    test('does not throw', () {
      expect(() => AppLogger.info('test info message'), returnsNormally);
    });

    test('accepts empty string', () {
      expect(() => AppLogger.info(''), returnsNormally);
    });
  });

  group('AppLogger — warning', () {
    test('does not throw', () {
      expect(() => AppLogger.warning('test warning message'), returnsNormally);
    });

    test('accepts empty string', () {
      expect(() => AppLogger.warning(''), returnsNormally);
    });
  });

  group('AppLogger — error', () {
    test('does not throw with message only', () {
      expect(() => AppLogger.error('test error message'), returnsNormally);
    });

    test('does not throw with error object', () {
      expect(
        () => AppLogger.error('test error', Exception('test')),
        returnsNormally,
      );
    });

    test('does not throw with error and stack trace', () {
      expect(
        () => AppLogger.error(
          'test error',
          Exception('test'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('accepts null error', () {
      expect(() => AppLogger.error('message', null), returnsNormally);
    });

    test('accepts null stack trace', () {
      expect(
        () => AppLogger.error('message', Exception('e'), null),
        returnsNormally,
      );
    });
  });

  group('AppLogger — all log levels can be called sequentially', () {
    test('calling all levels in sequence does not throw', () {
      expect(() {
        AppLogger.debug('debug message');
        AppLogger.info('info message');
        AppLogger.warning('warning message');
        AppLogger.error('error message');
        AppLogger.error('error with exception', Exception('test'));
        AppLogger.error(
          'error with stack',
          Exception('test'),
          StackTrace.current,
        );
      }, returnsNormally);
    });
  });

  group('AppLogger — special characters', () {
    test('handles messages with special characters', () {
      expect(
        () => AppLogger.info('Special chars: !@#\$%^&*()_+{}|:<>?'),
        returnsNormally,
      );
    });

    test('handles messages with unicode', () {
      expect(
        () => AppLogger.info('Unicode: Muhabbet kusu yetistiricisi'),
        returnsNormally,
      );
    });

    test('handles messages with newlines', () {
      expect(() => AppLogger.info('Line 1\nLine 2\nLine 3'), returnsNormally);
    });
  });
}
