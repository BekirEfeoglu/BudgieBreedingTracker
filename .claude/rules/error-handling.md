# Error Handling

## Exception Hierarchy
```dart
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
}

class NetworkException extends AppException {}
class AuthException extends AppException {}
class StorageException extends AppException {}
class DatabaseException extends AppException {}
class ValidationException extends AppException {}
class PermissionException extends AppException {}
class FreeTierLimitException extends AppException {}
```

## Error Flow
```
Service throws AppException → Repository propagates → Provider catches via AsyncValue.guard() → UI displays
```

## Logging
- `AppLogger.debug(tag, message)` — development info
- `AppLogger.info(tag, message)` — general info
- `AppLogger.warning(message)` — potential issues
- `AppLogger.error(message, error, stackTrace)` — errors (auto-adds Sentry breadcrumb)
- NEVER use `print()` — always `AppLogger`

## Sentry
- `Sentry.captureException(error, stackTrace: st)` for critical/unexpected errors
- AppLogger breadcrumbs automatically attached
- Environment tag via `SENTRY_ENVIRONMENT` dart-define

## Rules
- Bare `catch (e)` without logging → use `AppLogger.error`
- Critical errors without Sentry → use `Sentry.captureException`
- L10n error keys for user-facing messages (service throws key, UI calls `.tr()`)
- Retry with exponential backoff for transient network failures
- Localized error messages in `errors` L10n category
