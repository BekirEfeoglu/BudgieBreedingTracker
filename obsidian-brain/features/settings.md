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
- Scheduled backup toggle (uses `BackupScheduler`)

## Security Settings

- MFA enable/disable (TOTP)
- Recovery code generation (one-time view)
- Change password
- Active OAuth providers (Google / Apple) — link/unlink
- "Delete account" CTA → multi-step confirm + grace period

## Developer Menu

5-tap on the settings header title reveals experimental flags. Hidden in
production builds via feature-flag gate (see [[patterns/feature-flags]]).

## See Also

- [[features/profile]] — user-data side of account
- [[features/premium]] — upgrade entry point
- [[domain/data-io]] — backup/export internals
- [[patterns/accessibility]] — font scaling
- [[features/_features-index]]
