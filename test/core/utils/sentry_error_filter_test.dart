import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';

/// Test host that uses the real SentryErrorFilter.reportIfUnexpected()
/// filtering logic but intercepts the Sentry call via sendToSentry override.
class _TestFilterHost with SentryErrorFilter {
  final List<Object> reportedErrors = [];

  @override
  void sendToSentry(Object error, StackTrace stackTrace) {
    reportedErrors.add(error);
  }
}

void main() {
  late _TestFilterHost host;

  setUp(() {
    host = _TestFilterHost();
  });

  group('SentryErrorFilter', () {
    test('skips FreeTierLimitException', () {
      host.reportIfUnexpected(
        FreeTierLimitException('birds', 50),
        StackTrace.current,
      );
      expect(host.reportedErrors, isEmpty);
    });

    test('skips ValidationException', () {
      host.reportIfUnexpected(
        const ValidationException('invalid field'),
        StackTrace.current,
      );
      expect(host.reportedErrors, isEmpty);
    });

    test('reports NetworkException', () {
      const error = NetworkException('connection failed');
      host.reportIfUnexpected(error, StackTrace.current);
      expect(host.reportedErrors, [error]);
    });

    test('reports AuthException', () {
      const error = AuthException('session expired');
      host.reportIfUnexpected(error, StackTrace.current);
      expect(host.reportedErrors, [error]);
    });

    test('reports StorageException', () {
      const error = StorageException('upload failed');
      host.reportIfUnexpected(error, StackTrace.current);
      expect(host.reportedErrors, [error]);
    });

    test('reports DatabaseException', () {
      const error = DatabaseException('query failed');
      host.reportIfUnexpected(error, StackTrace.current);
      expect(host.reportedErrors, [error]);
    });

    test('reports generic Exception', () {
      final error = Exception('unexpected');
      host.reportIfUnexpected(error, StackTrace.current);
      expect(host.reportedErrors, [error]);
    });

    test('reports generic Error', () {
      final error = StateError('bad state');
      host.reportIfUnexpected(error, StackTrace.current);
      expect(host.reportedErrors, [error]);
    });
  });
}
