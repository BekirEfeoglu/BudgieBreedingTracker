import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';

String _exceptionKind(AppException exception) {
  return switch (exception) {
    NetworkException() => 'network',
    AuthException() => 'auth',
    DatabaseException() => 'database',
    StorageException() => 'storage',
    ValidationException() => 'validation',
    PermissionException() => 'permission',
  };
}

void main() {
  group('AppException hierarchy', () {
    test('NetworkException stores message, code and originalError', () {
      final original = Exception('socket');
      final exception = NetworkException(
        'Network failed',
        code: 'NET-1',
        originalError: original,
      );

      expect(exception.message, 'Network failed');
      expect(exception.code, 'NET-1');
      expect(exception.originalError, same(original));
      expect(exception, isA<AppException>());
    });

    test('AuthException stores message, code and originalError', () {
      final original = Exception('auth');
      final exception = AuthException(
        'Unauthorized',
        code: 'AUTH-1',
        originalError: original,
      );

      expect(exception.message, 'Unauthorized');
      expect(exception.code, 'AUTH-1');
      expect(exception.originalError, same(original));
      expect(exception, isA<AppException>());
    });

    test('DatabaseException stores message, code and originalError', () {
      final original = Exception('db');
      final exception = DatabaseException(
        'Database failure',
        code: 'DB-1',
        originalError: original,
      );

      expect(exception.message, 'Database failure');
      expect(exception.code, 'DB-1');
      expect(exception.originalError, same(original));
      expect(exception, isA<AppException>());
    });

    test('StorageException stores message, code and originalError', () {
      final original = Exception('storage');
      final exception = StorageException(
        'Storage failure',
        code: 'ST-1',
        originalError: original,
      );

      expect(exception.message, 'Storage failure');
      expect(exception.code, 'ST-1');
      expect(exception.originalError, same(original));
      expect(exception, isA<AppException>());
    });

    test('ValidationException stores message, code and originalError', () {
      final original = Exception('validation');
      final exception = ValidationException(
        'Invalid value',
        code: 'VAL-1',
        originalError: original,
      );

      expect(exception.message, 'Invalid value');
      expect(exception.code, 'VAL-1');
      expect(exception.originalError, same(original));
      expect(exception, isA<AppException>());
    });

    test('PermissionException stores message, code and originalError', () {
      final original = Exception('permission');
      final exception = PermissionException(
        'Access denied',
        code: 'PERM-1',
        originalError: original,
      );

      expect(exception.message, 'Access denied');
      expect(exception.code, 'PERM-1');
      expect(exception.originalError, same(original));
      expect(exception, isA<AppException>());
    });
  });

  group('sealed class pattern matching', () {
    test('switch maps each subtype', () {
      expect(_exceptionKind(const NetworkException('x')), 'network');
      expect(_exceptionKind(const AuthException('x')), 'auth');
      expect(_exceptionKind(const DatabaseException('x')), 'database');
      expect(_exceptionKind(const StorageException('x')), 'storage');
      expect(_exceptionKind(const ValidationException('x')), 'validation');
      expect(_exceptionKind(const PermissionException('x')), 'permission');
    });
  });
}
