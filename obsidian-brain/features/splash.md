# Feature: splash

**Purpose**: App startup — session check, deep link routing, initial data load.

## Key Screens

- Splash screen (logo animation)
- Initial loading state

## Behavior

1. Check Supabase session (auto-refresh if valid)
2. If authenticated → navigate to home or deep link route
3. If unauthenticated → navigate to auth
4. `DEBUG_START_ROUTE` dart-define skips splash entirely in debug builds

## Deep Link Handling

FCM terminated-state messages processed here via `getInitialMessage()`. Navigate to route from payload after splash completes.

## Logo

`assets/images/app_icon.png` — finalized 2026-04-06. **Do not modify.**

## See Also

- [[features/auth]]
- [[features/_features-index]]
- [[patterns/feature-flags]] — DEBUG_START_ROUTE
