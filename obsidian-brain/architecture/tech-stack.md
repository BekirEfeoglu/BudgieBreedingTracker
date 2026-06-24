# Tech Stack

Source: `pubspec.yaml`, `.claude/rules/architecture.md`

## Core

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Flutter | 3.41+ |
| Language | Dart | >=3.8.0 <4.0.0 |
| State management | flutter_riverpod | ^3.3.1 |
| Navigation | go_router | ^17.0.0 |
| Local database | drift | ^2.31.0 |
| Remote backend | supabase_flutter | >=2.5.0 <2.13.0 |

## Data & Serialization

| Package | Purpose |
|---------|---------|
| freezed_annotation ^3.0.0 | Immutable data classes + union types |
| json_annotation ^4.11.0 | JSON serialization |
| riverpod_annotation ^4.0.0 | Code-gen providers |
| drift ^2.31.0 | Type-safe SQLite ORM |
| sqlite3_flutter_libs 0.5.42 | Native SQLite libs (pinned — drift compat) |

## Backend & Cloud

| Package | Purpose |
|---------|---------|
| supabase_flutter >=2.5.0 <2.13.0 | Postgres + Auth + Storage + Realtime (capped below 2.13.0 — 2.13+ pulls the passkeys → device_info_plus 12.4.0 chain whose visionOS `isiOSAppOnVision` selector fails to compile on CI macos-latest Xcode SDK) |
| firebase_core ^4.1.1 | FCM prerequisite |
| firebase_messaging ^16.2.2 | Push notifications (FCM) |
| purchases_flutter ^10.2.3 | RevenueCat in-app purchases |
| sentry_flutter ^9.0.0 | Error tracking + performance |

## UI & UX

| Package | Purpose |
|---------|---------|
| flutter_svg ^2.0.10+1 | SVG icon rendering |
| lucide_icons ^0.257.0 | Generic UI icons |
| shimmer ^3.0.0 | Skeleton loading |
| cached_network_image ^3.3.0 | Network image + cache |
| photo_view ^0.15.0 | Zoomable image viewer |
| image_picker ^1.0.0 | Camera + gallery picker |
| fl_chart ^1.2.0 | Statistics charts |
| google_mobile_ads ^8.0.0 | AdMob ads (free tier) |

## Localization & Time

| Package | Purpose |
|---------|---------|
| easy_localization ^3.0.0 | i18n (tr/en/de) |
| intl ^0.20.0 | DateFormat, number formatting |
| timezone ^0.11.0 | tz.TZDateTime for notifications |
| flutter_timezone ^5.0.2 | Device timezone detection |
| flutter_local_notifications ^21.0.0 | Scheduled device notifications |

## Auth & Security

| Package | Purpose |
|---------|---------|
| flutter_secure_storage ^10.0.0 | Encrypted token storage |
| google_sign_in ^7.2.0 | Google OAuth |
| sign_in_with_apple ^8.0.0 | Apple Sign-In |
| encrypt ^5.0.3 | Local encryption utilities |

## Utilities

| Package | Purpose |
|---------|---------|
| uuid ^4.3.0 | Client-side UUID generation |
| connectivity_plus ">=7.0.0 <7.1.0" | Network state (pinned — iOS 26 SDK compat) |
| path_provider ^2.1.0 | File system paths (pinned 2.5.1 — FFI bug) |
| share_plus ^12.0.0 | OS share sheet |
| file_picker ^11.0.2 | File import |
| url_launcher ^6.2.0 | Open URLs |
| package_info_plus ^9.0.0 | App version info |
| logger ^2.0.0 | Console logging |
| crypto ^3.0.3 | Hash utilities |
| http ^1.5.0 | HTTP client |
| pdf ^3.10.0 | PDF export |
| excel ^4.0.0 | Excel export |

## Dev Dependencies

| Package | Purpose |
|---------|---------|
| build_runner ^2.13.0 | Code generation runner |
| riverpod_generator ^4.0.0 | Riverpod code gen |
| freezed ^3.0.0 | Freezed code gen |
| json_serializable ^6.13.0 | JSON code gen |
| drift_dev ^2.31.0 | Drift code gen |
| mocktail ^1.0.0 | Test mocking |
| fake_async ^1.3.0 | Fake timer in tests |
| flutter_lints ^6.0.0 | Lint rules |

## See Also

- [[architecture/layers]] — how these packages fit into the layer structure
- [[overview]] — codebase stats
