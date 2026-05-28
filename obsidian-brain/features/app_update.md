# Feature: app_update

**Purpose**: The single in-app update path. Shows an app-wide dialog when the
local build is older than the latest store version. Optional updates are
dismissible ("Later"); required updates (`local < min_supported_build`) render
a non-dismissible blocking dialog. iOS auto-detects the live App Store version
via iTunes Lookup; Android relies on the `system_settings.app_version` remote
config.

## Key Widgets

| Widget | Role |
|--------|------|
| `AppUpdatePrompt` | App-wide wrapper, mounted at the router builder level alongside `OfflineBanner` |

There's no dedicated screen — the prompt renders as a dialog over the
current shell so users can dismiss and continue.

## Provider Chain

```
AppUpdatePrompt
  └── watches appUpdateProvider (lib/domain/services/app_update/)
        └── reads package_info_plus local build
        └── reads remote AppVersionInfo (release notes + latest_build)
        └── compares → UpdateStatus.softAvailable | hardRequired | upToDate
```

`UpdateStatus.softAvailable` opens the dismissible dialog. `hardRequired`
renders the non-dismissible blocking dialog.

## Dismissal & Frequency

- "Later" closes the dialog for this launch
- "Update now" opens the platform store via `url_launcher`
- Cool-down between prompts is handled by `appUpdateProvider` — repeated
  same-version prompts are suppressed
- Hard updates ignore dismissal entirely

## Placement

Mounted in `app_router.dart` builder so it sits above all routes and
survives navigation:

```
AppUpdatePrompt(
  child: OfflineBanner(child: routedChild),
)
```

## Release Notes

`AppVersionInfo.releaseNotesFor(localeCode)` returns localized notes from
the remote config. Master locale is Turkish; fallback chain is
`current → en → tr`.

## See Also

- [[domain/services-index]] — `app_update_service`, `app_store_lookup_service`
- [[infrastructure/release-ops]] — version bump workflow
- [[features/_features-index]]
