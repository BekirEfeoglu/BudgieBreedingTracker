# Feature: app_update

**Purpose**: Automatic update prompting on both platforms, each using its
platform-native mechanism:
- **iOS** — `AppUpdatePrompt` shows an app-wide dialog. Optional updates are
  dismissible ("Later"); required updates (`local < min_supported_build`)
  render a non-dismissible blocking dialog. The live App Store version is
  auto-detected via iTunes Lookup (merged with `system_settings.app_version`).
- **Android** — Google Play **native in-app updates** via the `in_app_update`
  package (`InAppUpdateService` + `AndroidInAppUpdater`). Flexible by default
  (background download → "restart" SnackBar); immediate (full-screen, blocking)
  when the Play release sets `updatePriority >= 4`. No remote config needed.

To avoid a double prompt, the custom dialog is **iOS-only**:
`appUpdateStatusProvider` returns null on Android, and the widget also gates on
`Theme.of(context).platform == TargetPlatform.iOS`.

## Key Widgets

| Widget | Role |
|--------|------|
| `AppUpdatePrompt` | iOS dialog wrapper, mounted at the builder level alongside `OfflineBanner` |
| `AndroidInAppUpdater` | App-wide wrapper (outermost in the builder); on Android triggers the Play check at startup + resume and shows the flexible "restart" SnackBar. Passthrough on other platforms. |

There's no dedicated screen — iOS renders a dialog over the current shell;
Android uses Google Play's own native update UI.

## iOS Provider Chain

`appUpdateStatusProvider` returns null on Android (the native flow handles it).

```
AppUpdatePrompt (iOS only)
  └── watches appUpdateStatusProvider (lib/domain/services/app_update/)
        └── reads package_info_plus local build + version
        └── reads remote AppUpdateInfo (system_settings.app_version) + iTunes Lookup
        └── AppUpdateInfo.evaluate() → AppUpdateStatus (isUpdateAvailable + isRequired)
```

An available update with `isRequired == false` opens the dismissible dialog;
`isRequired == true` (local build < `min_supported_build`) renders the
non-dismissible blocking dialog.

## Android Native Flow

```
AndroidInAppUpdater (Android only)
  └── ref.read(inAppUpdateServiceProvider).checkAndStart()   // startup + resume
        └── InAppUpdateService → InAppUpdateClient (Play Core via in_app_update)
        └── updateAvailable + immediateAllowed + updatePriority >= 4 → immediate
        └── else flexibleAllowed → flexible (background download)
  └── on InstallStatus.downloaded → "restart" SnackBar → completeFlexibleUpdate()
```

The native flow only runs on a Play-installed build (not debug/emulator/
simulator). Fail-open: a failed check never blocks the app. A `completeFlexible`
failure (user tapped restart but install failed) is reported to Sentry.

## Dismissal & Frequency (iOS dialog)

- "Later" closes the dialog for this launch
- "Update now" opens the platform store via `url_launcher`
- Cool-down between prompts is handled by `AppUpdatePrompt` (tracks the shown
  version key) — repeated same-version prompts are suppressed
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

`AppUpdatePrompt` localizes release notes from `AppUpdateInfo`'s
`releaseNotesTr` / `releaseNotesEn` / `releaseNotesDe` fields by device
language, falling back to English.

## See Also

- [[domain/services-index]] — `app_update_service`, `app_store_lookup_service`, `in_app_update_service` (Android Play Core)
- [[infrastructure/release-ops]] — version bump workflow; set Play `updatePriority` via the Publishing API for Android immediate updates
- [[features/_features-index]]
