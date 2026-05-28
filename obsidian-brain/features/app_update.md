# Feature: app_update

**Purpose**: Automatic update prompting on both platforms, each using its
platform-native mechanism:
- **iOS** — `AppUpdatePrompt` renders an **in-tree prompt** (NOT a route — see
  below). Optional updates show a dismissible banner ("Later"); required
  updates (`local < min_supported_build`) show a full-screen blocking layer.
  The live App Store version is auto-detected via iTunes Lookup (merged with
  `system_settings.app_version`).
- **Android** — Google Play **native in-app updates** via the `in_app_update`
  package (`InAppUpdateService` + `AndroidInAppUpdater`). Flexible by default
  (background download → "restart" SnackBar); immediate (full-screen, blocking)
  when the Play release sets `updatePriority >= 4`. No remote config needed.

To avoid a double prompt, the custom prompt is **iOS-only**:
`appUpdateStatusProvider` returns null on Android, and the widget also gates on
`Theme.of(context).platform == TargetPlatform.iOS`.

## Key Widgets

| Widget | Role |
|--------|------|
| `AppUpdatePrompt` | iOS prompt wrapper; renders an in-tree banner/overlay (not a route), mounted at the builder level alongside `OfflineBanner` |
| `AndroidInAppUpdater` | App-wide wrapper (outermost in the builder); on Android triggers the Play check at startup + resume and shows the flexible "restart" SnackBar. Passthrough on other platforms. |

There's no dedicated screen — iOS draws an in-tree banner/overlay in the widget
tree (a `Stack` over the child) so GoRouter page rebuilds can't dismiss it;
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

An available update with `isRequired == false` renders the dismissible banner;
`isRequired == true` (local build < `min_supported_build`) renders the
full-screen blocking layer. Both are drawn **in-tree** (a `Stack` over the
child), NOT via `showDialog` — an imperative dialog pushed from the builder is
dismissed whenever GoRouter rebuilds its pages (e.g. on an auth-token refresh).

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

## Dismissal & Frequency (iOS prompt)

- "Later" hides the banner; the dismissed version is remembered
  (`_dismissedVersionKey`), so the same version won't re-prompt this launch
- "Update now" opens the App Store via `url_launcher`
- Required updates have no "Later" — the full-screen layer can't be dismissed
- The optional banner animates in (slide-up + fade) and matches the app's card
  language (tinted icon square, soft shadow)

## Placement

Mounted in the `MaterialApp.router` builder (`app.dart`) so it sits above all
routes. Drawing the prompt in-tree (not as a route) is what lets it survive
GoRouter rebuilds:

```
AndroidInAppUpdater(
  child: AppUpdatePrompt(
    child: OfflineBanner(child: routedChild),
  ),
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
