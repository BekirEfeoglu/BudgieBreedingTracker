# Error Handling

Source: `.claude/rules/error-handling.md`

## Exception Hierarchy

```dart
sealed class AppException implements Exception {
  final String message;   // l10n key
  final String? code;
  final dynamic originalError;
}

class NetworkException extends AppException {}
class AuthException extends AppException {}
class StorageException extends AppException {}
class DatabaseException extends AppException {}
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
}
class PermissionException extends AppException {}
class FreeTierLimitException extends AppException {}
```

## Error Flow

```
Service throws AppException
  → Repository propagates (or adds context)
    → Provider catches via AsyncValue.guard()
      → UI displays via asyncValue.when(error: ...)
```

## Logging Levels

| Level | Usage |
|-------|-------|
| `AppLogger.debug(tag, msg)` | Development, temporary tracing |
| `AppLogger.info(tag, msg)` | Operational info |
| `AppLogger.warning(msg)` | Degraded state, retry expected |
| `AppLogger.error(msg, error, st)` | Errors (auto Sentry breadcrumb) |

Tag: source class name — `'BirdRepository'`, `'SyncService'`, `'AuthProvider'`

## Sentry

```dart
try {
  await criticalOperation();
} catch (e, st) {
  AppLogger.error('operation failed', e, st);
  await Sentry.captureException(e, stackTrace: st);
  rethrow;
}
```

### Send to Sentry

- Auth/MFA failures
- Sync conflicts / data corruption
- Crashes / unhandled exceptions
- Critical edge function failures

### Do NOT send to Sentry

- Form validation errors (`ValidationException`)
- Expected 404 / empty lists
- User offline (`NetworkException`)
- Free tier limit hit (`FreeTierLimitException`)
- User-cancelled actions

## Retry Strategy

```
NetworkException (transient):
  Attempt 1 → immediately
  Attempt 2 → 2s
  Attempt 3 → 4s (max 3 attempts default)
  → rethrow

AuthException, ValidationException, PermissionException:
  → rethrow immediately (no retry)
```

## User-Facing Messages

- Services throw l10n keys as message: `throw NetworkException('errors.network_unavailable')`
- UI calls `.tr()`: `ErrorState(message: error.message.tr())`
- **Never** show raw exception messages or stack traces

## Rules

- Bare `catch (e)` without logging → `AppLogger.error` + typed exception
- Critical errors without Sentry → `Sentry.captureException`
- Always include `stackTrace` in error logging
- Prefer typed catches: `on NetworkException catch (e, st)` over generic

## See Also

- [[patterns/observability]] — AppLogger + Sentry details
- [[patterns/anti-patterns]] — #22, #23 (bare catch, missing Sentry)
- [[patterns/l10n]] — error l10n keys
