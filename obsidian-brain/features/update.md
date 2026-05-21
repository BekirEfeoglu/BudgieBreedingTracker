# Feature: update

**Purpose**: Hard barrier shown when the local build number is below
`min_supported_build` (server-defined). Blocks navigation until the user
installs the new version from the store.

## Key Screens

| Screen | Route |
|--------|-------|
| `ForcedUpdateScreen` | Mounted by router when version gate fails |

## Behavior

- `PopScope(canPop: false)` prevents back-button dismissal
- Localized release notes (`AppVersionInfo.releaseNotesFor(locale)`) shown
  per device locale
- Primary CTA opens the App Store / Play Store via `url_launcher`
- Auth state is preserved — once user updates and relaunches, session
  resumes without re-login

## Provider

`appVersionInfoProvider` resolves `AppVersionInfo` via
[[domain/services-index]] (`update_check_service`). Returns local build
number + remote `min_supported_build` + release notes per locale. When
`local < min_supported_build`, the router redirects here.

## Difference From `app_update`

| Feature | `update` (this) | `app_update` |
|---------|----------------|--------------|
| Severity | Hard block | Soft nudge |
| Dismissable | No | Yes (with "Later") |
| Trigger | `local < min_supported_build` | `local < latest_available` |
| Mounted | Replaces shell | In-app dialog |

The two coexist: `app_update` runs on every cold start to nudge users;
`update` only fires when the build is below the floor (security or
breaking-change releases).

## Server Config

`min_supported_build` lives in the Supabase `app_config` table. Bumping
it forces every below-floor user to update on next launch. Use sparingly —
this is a UX hammer.

## See Also

- [[features/app_update]] — soft update prompt
- [[domain/services-index]] — `update_check_service`
- [[infrastructure/release-ops]] — bumping `min_supported_build`
- [[features/_features-index]]
