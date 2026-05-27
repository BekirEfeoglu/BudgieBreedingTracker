sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}

class FreeTierLimitException extends AppException {
  final String entityType;
  final int limit;

  FreeTierLimitException(this.entityType, this.limit)
      : super('Free tier limit reached for $entityType');
}

/// Thrown when a requested entity does not exist (DB miss, stale ID).
///
/// Carries an l10n key (e.g. `'errors.not_found'`) in [message] so the UI
/// can `.tr()` it. Distinct type lets callers pattern-match for "show
/// not-found state" vs other failure paths.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.originalError});
}
