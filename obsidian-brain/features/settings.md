# Feature: settings

**Purpose**: Centralized app preferences — theme, locale, font scaling,
notification master, backup, export, security, account deletion, legal
documents. The "configuration surface" of the app.

## Key Screens

| Screen | Route |
|--------|-------|
| `SettingsScreen` | `AppRoutes.settings` — top-level list |
| `BackupScreen` | `AppRoutes.backup` — local + remote backup management |
| `LegalDocumentScreen` | `AppRoutes.privacyPolicy`, `termsOfService`, etc. |
| `CommunityGuidelinesView` | `AppRoutes.communityGuidelines` |
| MFA enrollment / verify | `AppRoutes.twoFactorSetup`, `twoFactorVerify` |

## Theme / Locale / Font Providers

| Provider | Notifier | Persistence |
|----------|----------|-------------|
| `themeModeProvider` | `ThemeModeNotifier` | SharedPreferences |
| `appLocaleProvider` | `AppLocaleNotifier` | SharedPreferences |
| `fontScaleProvider` | `FontScaleNotifier` | SharedPreferences |

`fontScaleProvider` honors the system `MediaQuery.textScalerOf(context)`
floor while letting users opt into larger scales than the OS provides
(see [[patterns/accessibility]]).

## Toggle Providers

| Provider | Notifier |
|----------|----------|
| `notificationsMasterProvider` | `NotificationsMasterNotifier` (global push on/off) |
| `compactViewProvider` | `CompactViewNotifier` (list density) |

All preference notifiers (theme/locale/font + bool toggles + date format)
extend `PrefNotifier`/`PrefBoolNotifier`
(`lib/data/local/preferences/pref_notifier.dart`), which guards the
fire-and-forget load in `build()`: a disk value never overwrites a change the
user made while the load was in flight, nothing writes state after dispose,
and storage failures are logged instead of escaping as unhandled errors.

## Storage / Diagnostics

| Provider | Purpose |
|----------|---------|
| `cacheSizeProvider` | Sum of `CachedNetworkImage` + tmp dirs |
| `databaseSizeProvider` | Drift DB file bytes |
| `imageStorageSizeProvider` | Local photo cache bytes |
| `appInfoProvider` | `package_info_plus` snapshot |

## Export

Export wiring lives here (not in a dedicated feature module):

- `exportActionsProvider` — action surface (PDF, Excel)
- `pdfExportServiceProvider`, `excelExportServiceProvider` — service wrappers
- `exportLoadingProvider` — UI lock during export
- `lastExportDateProvider` — drives "you exported X days ago" hint
- Share via OS share sheet (`share_plus`)

See [[domain/data-io]] for the underlying services.

## Backup

`BackupScreen` exposes:

- Local snapshot (JSON, optional encryption)
- Remote backup upload (Supabase Storage)
- Remote backup list + restore

`BackupScheduler` (`lib/domain/services/backup/backup_scheduler.dart`) is
defined but **not wired into `BackupScreen`** — there is no scheduled-backup
toggle in the UI yet (the periodic auto-backup in [[domain/data-io]] is a
design goal, not shipped).

## Security Settings

- MFA enable/disable (TOTP)
- Recovery code generation (one-time view)
- Change password → delegates to the shared MFA-aware `showPasswordChangeSheet`
  (the password re-auth resets AAL2, so 2FA users are re-challenged rather
  than silently failed; the Settings-local dialog that swallowed that
  exception for every 2FA user was removed 2026-07-02)
- Active OAuth providers (Google / Apple) — link/unlink
- "Delete account" CTA → `AccountDeletionController`, guarded by password +
  AAL2 (MFA re-challenge if 2FA enrolled), NOT a grace period (see
  [[features/profile]] for the full step order)

## About

Version / build / links — rate app, share app, support/contact
(`about_section.dart`). All launch actions `await launchUrl` and, on a failed
launch (`false` return or throw), surface `errors.cannot_open_url` ("no suitable
app found") — parity with the More-tab About dialog `_showMoreAboutDialog`. The
rate-app tile used `errors.unknown` until 2026-07-11; it now matches the sibling
paths. Share is guarded the same way (awaited + logged via `AppLogger`).

## Developer Menu

**Not implemented** — the "5-tap on settings header" experimental-flags menu
described in [[patterns/feature-flags]] does not exist in the codebase
(verified 2026-07-02). Documented as a future design goal only.

## See Also

- [[features/profile]] — user-data side of account
- [[features/premium]] — upgrade entry point
- [[domain/data-io]] — backup/export internals
- [[patterns/accessibility]] — font scaling
- [[features/_features-index]]
