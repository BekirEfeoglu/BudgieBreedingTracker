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
Service throws AppException -> Repository propagates -> Provider catches via AsyncValue.guard() -> UI displays
```
- Services throw typed `AppException` subclasses
- Repositories propagate without catching (unless adding context)
- Providers use `AsyncValue.guard()` — error state auto-propagates to UI
- UI uses `asyncValue.when(error: ...)` or `ref.listen()` for side-effect errors

## Logging
| Method | Usage |
|--------|-------|
| `AppLogger.debug(tag, message)` | Development info, temporary tracing |
| `AppLogger.info(tag, message)` | General operational info |
| `AppLogger.warning(message)` | Potential issues, degraded state |
| `AppLogger.error(message, error, stackTrace)` | Errors (auto-adds Sentry breadcrumb) |

- NEVER use `print()` — always `AppLogger`
- Tag should identify the source: `'BirdRepository'`, `'SyncService'`, `'AuthProvider'`

## Sentry
- `Sentry.captureException(error, stackTrace: st)` for critical/unexpected errors
- AppLogger breadcrumbs automatically attached
- Environment tag via `SENTRY_ENVIRONMENT` dart-define
- Use for: unhandled exceptions, auth failures, data corruption, sync conflicts
- Don't use for: expected validation errors, user-facing form errors, network timeouts

## Retry Strategy
```dart
// Exponential backoff for transient network failures
Future<T> withRetry<T>(Future<T> Function() action, {int maxAttempts = 3}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } on NetworkException {
      if (attempt == maxAttempts) rethrow;
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
    }
  }
  throw StateError('unreachable');
}
```
- Retry only for `NetworkException` (transient)
- Don't retry: `AuthException`, `ValidationException`, `PermissionException`
- Max 3 attempts with exponential backoff (2s, 4s, 8s)

## User-Facing Error Messages
- Services throw l10n keys as `message`: `throw NetworkException('errors.network_unavailable')`
- UI calls `.tr()` on the message: `ErrorState(message: error.message.tr())`
- All user-facing error messages in `errors` l10n category
- Never show raw exception messages or stack traces to users

## Rules
- Bare `catch (e)` without logging -> use `AppLogger.error`
- Critical errors without Sentry -> use `Sentry.captureException`
- Always include `stackTrace` in error logging
- Typed catches preferred: `on NetworkException catch (e, st)` over generic `catch (e)`

> **Related**: providers.md (AsyncValue error handling), localization.md (error l10n keys), ai-workflow.md (prohibited actions)
