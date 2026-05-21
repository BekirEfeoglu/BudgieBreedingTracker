# Feature: app_update

**Purpose**: Soft, dismissible in-app prompt that nudges users to install
the latest store version when their build is older than the latest
available — but still above `min_supported_build`. Sister feature to
[[features/update]] (hard block) and shares `AppVersionInfo`.

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
escalates to the [[features/update]] full-screen blocker via redirect.

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

- [[features/update]] — hard update barrier
- [[domain/services-index]] — `app_update_service`, `app_store_lookup_service`
- [[infrastructure/release-ops]] — version bump workflow
- [[features/_features-index]]
