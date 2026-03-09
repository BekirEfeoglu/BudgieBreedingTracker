<p align="center">
  <img src="assets/images/app_icon.png" alt="BudgieBreedingTracker" width="140" />
</p>

<h1 align="center">BudgieBreedingTracker</h1>

<p align="center">
  <em>The all-in-one breeding companion for budgerigar enthusiasts</em>
</p>

<p align="center">
  <a href="https://budgiebreedingtracker.online"><img src="https://img.shields.io/badge/Web-budgiebreedingtracker.online-FF6F00?style=flat&logo=googlechrome&logoColor=white" alt="Website" /></a>
  &nbsp;
  <a href="https://github.com/BekirEfeoglu/BudgieBreedingTracker/actions/workflows/ci.yml"><img src="https://github.com/BekirEfeoglu/BudgieBreedingTracker/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  &nbsp;
  <a href="https://codecov.io/gh/BekirEfeoglu/BudgieBreedingTracker"><img src="https://codecov.io/gh/BekirEfeoglu/BudgieBreedingTracker/graph/badge.svg" alt="Coverage" /></a>
  &nbsp;
  <img src="https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  &nbsp;
  <img src="https://img.shields.io/badge/Dart-3.8+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  &nbsp;
  <img src="https://img.shields.io/badge/Supabase-Backend-3FCF8E?logo=supabase&logoColor=white" alt="Supabase" />
  &nbsp;
  <img src="https://img.shields.io/badge/SQLite-Drift_2.31-003B57?logo=sqlite&logoColor=white" alt="Drift" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android_%7C_iOS-grey?logo=android&logoColor=white" alt="Platform" />
  &nbsp;
  <img src="https://img.shields.io/badge/License-Proprietary-red" alt="License" />
  &nbsp;
  <img src="https://img.shields.io/badge/Lines_of_Code-75k+-blueviolet" alt="Lines of Code" />
  &nbsp;
  <img src="https://img.shields.io/badge/Localization-TR_%7C_EN_%7C_DE-orange" alt="i18n" />
  &nbsp;
  <img src="https://img.shields.io/badge/Riverpod-3-00B0FF?logo=dart&logoColor=white" alt="Riverpod" />
</p>

<p align="center">
  <a href="#-features">Features</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
  <a href="#-architecture">Architecture</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
  <a href="#-tech-stack">Tech Stack</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
  <a href="#-getting-started">Getting Started</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
  <a href="#-project-structure">Project Structure</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
  <a href="#-contributing">Contributing</a>
</p>

---

## Overview

BudgieBreedingTracker is a production-grade Flutter application built for budgerigar breeders who need a reliable, feature-rich tool to manage every aspect of their aviary. From individual bird profiles to advanced genetics calculations, incubation monitoring to multi-generation pedigrees — everything is designed to work **offline-first** with seamless cloud synchronization.

<table>
<tr>
<td width="50%">

**Why BudgieBreedingTracker?**

- Complete lifecycle tracking from egg to adult bird
- Genetics calculator with Punnett square (curated mutation set)
- Works without internet — syncs when connected
- Three languages out of the box (TR / EN / DE)
- Enterprise-grade data protection with AES-256 encryption

</td>
<td width="50%">

**At a Glance**

```
556 Dart source files    75,100+ lines of code
 20 feature modules       52 screens
 52 routes                19 database tables
490 test files            82 custom SVG icons
 49 dependencies       1,746 translation keys × 3 langs
```

</td>
</tr>
</table>

## Key Highlights

<table>
<tr>
<td align="center" width="20%">
<h3>📡 Offline-First</h3>
<p>All data stored locally via SQLite. Works without internet, syncs automatically when connected.</p>
</td>
<td align="center" width="20%">
<h3>🧬 Genetics Engine</h3>
<p>Punnett square calculator with epistasis support, genotype wizard, and mutation prediction.</p>
</td>
<td align="center" width="20%">
<h3>🌍 Multi-Language</h3>
<p>Turkish, English, and German — 1,746 translation keys per language, instantly switchable.</p>
</td>
<td align="center" width="20%">
<h3>☁️ Cloud Sync</h3>
<p>Background sync to Supabase every 15 min with server-wins conflict resolution and retry logic.</p>
</td>
<td align="center" width="20%">
<h3>🛡️ Admin Panel</h3>
<p>Full management suite — user control, system monitoring, audit logs, and security settings.</p>
</td>
</tr>
</table>

## Features

### 🐦 Bird & Flock Management

| | Feature | Highlights |
|---|---------|-----------|
| **Birds** | Full bird registry | Gender, ring number, mutation, color, status, photo gallery, notes |
| **Breeding** | Pair management | Match male & female, track clutches, monitor nesting activity |
| **Eggs** | Incubation tracker | 18-day countdown, fertility status, turning reminders (08:00/14:00/20:00), hatch predictions |
| **Chicks** | Growth monitoring | Weight, measurements, developmental milestones from hatch to weaning |
| **Health** | Medical records | Vet visits, medications, health observations per bird |

### 📊 Analytics & Science

| | Feature | Highlights |
|---|---------|-----------|
| **Genetics** | Mutation calculator | Punnett square, genotype wizard, epistasis support, calculation history |
| **Genealogy** | Family tree | Multi-generation pedigree visualization, ancestor tracking |
| **Statistics** | Breeding analytics | Success rates, population trends, growth charts, hatch analytics |
| **Calendar** | Event planner | Breeding schedule, custom reminders, milestone tracking |

### ⚙️ Platform & Infrastructure

| | Feature | Highlights |
|---|---------|-----------|
| **Offline-First** | Local-first data | SQLite via Drift — all reads/writes work without internet |
| **Cloud Sync** | Background sync | Automatic push/pull to Supabase every 15 min + on reconnect |
| **Multi-Language** | i18n | Turkish, English, German — 1,746 keys per language |
| **Notifications** | Smart alerts | Incubation milestones, feeding schedules, custom event reminders |
| **Backup** | Data safety | PDF/Excel export, AES-256-CBC encrypted cloud backups |
| **Admin Panel** | Management | User management, system monitoring, audit logs, security settings |
| **Premium** | Subscription | Gated advanced analytics, genealogy and genetics features |
| **Error Tracking** | Sentry | Crash reporting, performance monitoring, route tracking |

## Screenshots

<p align="center">
  <img src="docs/screenshots/home-dashboard.png" alt="Dashboard" width="160">
  <img src="docs/screenshots/bird-list.png" alt="Bird List" width="160">
  <img src="docs/screenshots/bird-detail.png" alt="Bird Detail" width="160">
  <img src="docs/screenshots/breeding-list.png" alt="Breeding List" width="160">
  <img src="docs/screenshots/breeding-detail.png" alt="Breeding Detail" width="160">
</p>

<p align="center">
  <img src="docs/screenshots/genetics-calculator.png" alt="Genetics Calculator" width="160">
  <img src="docs/screenshots/chick-list.png" alt="Chick List" width="160">
  <img src="docs/screenshots/calendar.png" alt="Calendar" width="160">
  <img src="docs/screenshots/statistics.png" alt="Statistics" width="160">
  <img src="docs/screenshots/genealogy.png" alt="Family Tree" width="160">
</p>

<p align="center">
  <b>Dashboard</b> · <b>Birds</b> · <b>Bird Detail</b> · <b>Breeding</b> · <b>Incubation</b>
  <br>
  <b>Genetics</b> · <b>Chicks</b> · <b>Calendar</b> · <b>Statistics</b> · <b>Family Tree</b>
</p>

> **[Live Demo & Landing Page →](https://budgiebreedingtracker.online)**

## Architecture

### Clean Architecture — Feature-First

The codebase follows a strict layered architecture with unidirectional dependency flow:

```
 ┌──────────────────────────────────────────────────────────────┐
 │  router/            Navigation layer (GoRouter + 3 Guards)   │
 ├──────────────────────────────────────────────────────────────┤
 │  features/          UI layer — 20 self-contained modules     │
 │                     each with providers / screens / widgets  │
 ├──────────────────────────────────────────────────────────────┤
 │  domain/            Business logic — 12 service directories  │
 │                     auth · sync · genetics · backup · ...    │
 ├──────────────────────────────────────────────────────────────┤
 │  data/              Data layer                               │
 │                     models · Drift (local) · Supabase (remote)
 │                     repositories · mappers · converters      │
 ├──────────────────────────────────────────────────────────────┤
 │  core/              Shared foundation                        │
 │                     constants · enums · theme · widgets      │
 └──────────────────────────────────────────────────────────────┘
```

**Layer Rules:** `core/` never imports from upper layers. `data/` never imports from `features/`. Each feature module is self-contained.

### Offline-First Sync Engine

```
 ┌──────────┐     ┌──────────┐     ┌────────────────┐     ┌──────────┐
 │  UI      │────>│  Repo    │────>│  DAO (SQLite)  │     │ Supabase │
 │  Layer   │     │  sitory  │     │  Local-first   │     │  Cloud   │
 └──────────┘     └────┬─────┘     └───────┬────────┘     └────┬─────┘
                       │                   │                    │
                       │         ┌─────────▼──────────┐        │
                       │         │  SyncMetadata       │        │
                       │         │  (pending queue)    │        │
                       │         └─────────┬──────────┘        │
                       │                   │                    │
                       │         ┌─────────▼──────────┐        │
                       └────────>│  SyncOrchestrator   │───────>│
                                 │  Push → Pull cycle  │<───────│
                                 │  15 min interval    │        │
                                 └────────────────────┘        │
```

| Phase | Action | Detail |
|-------|--------|--------|
| **Write** | `DAO.insertItem()` | All writes go to local SQLite first |
| **Queue** | `SyncMetadata.markPending()` | Record marked for sync |
| **Push** | `RemoteSource.upsert()` | Background push to Supabase |
| **Pull** | `insertOnConflictUpdate()` | Server-wins conflict resolution |
| **Retry** | Exponential backoff | 30s → 10 min cap, max 5 retries |

### State Management — Riverpod 3

```
Data Providers (singleton)
  └─ DAO → Repository → RemoteSource

Feature Providers (per module)
  ├─ StreamProvider.family    → real-time lists & detail views
  ├─ NotifierProvider         → filter, search, form state
  ├─ Provider.family          → computed / filtered data
  └─ FutureProvider.family    → one-shot async fetches
```

## Tech Stack

<table>
<tr><td><b>Category</b></td><td><b>Technology</b></td><td><b>Purpose</b></td></tr>
<tr><td rowspan="2"><b>Core</b></td><td>Flutter 3.16+ / Dart 3.8+</td><td>Cross-platform UI framework</td></tr>
<tr><td>Material Design 3</td><td>Modern adaptive theming</td></tr>
<tr><td rowspan="3"><b>State & Nav</b></td><td>Riverpod 3</td><td>Reactive state management with code generation</td></tr>
<tr><td>GoRouter 17+</td><td>Declarative routing with auth/admin/premium guards</td></tr>
<tr><td>Freezed 3</td><td>Immutable data classes + JSON serialization</td></tr>
<tr><td rowspan="2"><b>Database</b></td><td>Drift 2.31+ (SQLite)</td><td>Local-first typed database with migrations</td></tr>
<tr><td>Supabase</td><td>PostgreSQL, Auth, Storage, Edge Functions</td></tr>
<tr><td rowspan="3"><b>UI & Assets</b></td><td>fl_chart 1.1+</td><td>Interactive charts and analytics</td></tr>
<tr><td>flutter_svg + Lucide</td><td>82 custom SVG icons + generic UI icons</td></tr>
<tr><td>easy_localization</td><td>TR, EN, DE — 1,746 keys per language</td></tr>
<tr><td rowspan="4"><b>Infrastructure</b></td><td>Sentry</td><td>Crash reporting & performance monitoring</td></tr>
<tr><td>encrypt (AES-256-CBC)</td><td>Backup encryption with random IV</td></tr>
<tr><td>pdf + excel</td><td>Export to PDF and Excel formats</td></tr>
<tr><td>share_plus + path_provider</td><td>File sharing & local storage paths</td></tr>
</table>

## Getting Started

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter SDK | 3.16+ |
| Dart SDK | 3.8+ |
| Supabase project | For backend features |
| IDE | Android Studio or VS Code |

### Quick Start

```bash
# 1. Clone
git clone https://github.com/BekirEfeoglu/BudgieBreedingTracker.git
cd BudgieBreedingTracker

# 2. Install dependencies
flutter pub get

# 3. Generate code (Freezed, Drift, Riverpod, JSON Serializable)
dart run build_runner build --delete-conflicting-outputs

# 4. Run (pass credentials via --dart-define)
flutter run \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-key>
```

### Environment Variables

| Variable | Required | Description |
|----------|:--------:|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous (public) key |
| `SENTRY_DSN` | No | Sentry DSN for error tracking |
| `SENTRY_ENVIRONMENT` | No | Sentry environment identifier |

### Available Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `dart run build_runner build --delete-conflicting-outputs` | Code generation |
| `dart run build_runner clean` | Clean generated files |
| `flutter analyze` | Static analysis |
| `flutter test` | Run all tests |
| `flutter test --coverage` | Tests with coverage report |
| `python scripts/check_l10n_sync.py` | Verify translation sync |
| `python scripts/verify_code_quality.py` | Anti-pattern scan |

## Project Structure

```
BudgieBreedingTracker/
├── .github/
│   ├── workflows/ci.yml              # CI pipeline (7 jobs)
│   └── pull_request_template.md       # PR template
├── assets/
│   ├── icons/                         # 82 SVG icons across 10 categories
│   │   ├── admin/        (6)         #   admin, birds (14), breeding (5)
│   │   ├── birds/       (14)         #   chicks (4), community (7), eggs (6)
│   │   ├── general/     (19)         #   general (19), genetics (6)
│   │   ├── navigation/   (7)         #   navigation (7), settings (7)
│   │   └── ...
│   ├── images/                        # App logo, icons
│   └── translations/                  # tr.json, en.json, de.json
├── scripts/                           # CI utility scripts (Python)
│   ├── check_l10n_sync.py            #   Translation sync validator
│   ├── verify_code_quality.py        #   Anti-pattern scanner
│   └── verify_rules.py              #   Project rules checker
├── lib/
│   ├── main.dart                      # Entry point
│   ├── app.dart                       # MaterialApp.router (ConsumerWidget)
│   ├── bootstrap.dart                 # Async init (Supabase, orientation)
│   ├── core/                          # ── Shared Foundation ──
│   │   ├── constants/                 #   AppConstants, AppIcons (82 SVG paths)
│   │   ├── enums/                     #   11 enum files
│   │   ├── errors/                    #   AppException hierarchy
│   │   ├── extensions/                #   Context, date, string, num
│   │   ├── theme/                     #   Colors, spacing, typography, shadows
│   │   ├── utils/                     #   DateUtils, AppLogger
│   │   └── widgets/                   #   21 shared widgets + AppIcon
│   ├── data/                          # ── Data Layer ──
│   │   ├── models/                    #   21 Freezed model files
│   │   ├── local/
│   │   │   ├── database/
│   │   │   │   ├── tables/            #   19 Drift tables
│   │   │   │   ├── daos/              #   19 DAOs
│   │   │   │   ├── mappers/           #   19 mapper extensions
│   │   │   │   ├── converters/        #   Enum converters
│   │   │   │   └── app_database.dart  #   Schema v14, 30+ indexes
│   │   │   └── preferences/           #   SharedPreferences wrapper
│   │   ├── remote/
│   │   │   ├── api/                   #   19 Supabase remote sources
│   │   │   ├── storage/               #   StorageService (5 buckets)
│   │   │   └── supabase/              #   EdgeFunctionClient
│   │   └── repositories/              #   18 entity + base + sync_metadata
│   ├── domain/                        # ── Business Logic ──
│   │   └── services/                  #   12 dirs: auth, sync, genetics,
│   │                                  #   backup, calendar, encryption,
│   │                                  #   export, import, incubation,
│   │                                  #   messaging, notifications, payment
│   ├── features/                      # ── UI Layer (20 modules) ──
│   │   ├── admin/                     #   Dashboard, users, monitoring, audit
│   │   ├── auth/                      #   Login, register, 2FA, verification
│   │   ├── birds/                     #   Bird CRUD, list, detail, form
│   │   ├── breeding/                  #   Pair management, clutch tracking
│   │   ├── calendar/                  #   Event calendar, reminders
│   │   ├── chicks/                    #   Chick CRUD, growth tracking
│   │   ├── community/                 #   Community feed (MVP)
│   │   ├── eggs/                      #   Egg management, incubation
│   │   ├── feedback/                  #   User feedback
│   │   ├── genealogy/                 #   Family tree, pedigree
│   │   ├── genetics/                  #   Punnett square, genotype wizard
│   │   ├── health_records/            #   Health tracking
│   │   ├── home/                      #   Dashboard, stats, quick actions
│   │   ├── more/                      #   More menu / settings hub
│   │   ├── notifications/             #   Notification management
│   │   ├── premium/                   #   Subscription features
│   │   ├── profile/                   #   User profile, avatar
│   │   ├── settings/                  #   App settings, backup, export
│   │   ├── splash/                    #   Splash / onboarding
│   │   └── statistics/                #   Charts, analytics
│   └── router/                        # ── Navigation ──
│       ├── app_router.dart            #   52 routes, ShellRoute
│       ├── route_names.dart           #   AppRoutes constants
│       └── guards/                    #   Auth, admin, premium guards
└── test/                              # 490 test files
```

## CI/CD

GitHub Actions runs **7 parallel jobs** on every push and PR to `main`:

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Flutter Analyze  │  │  Flutter Test   │  │ Localization    │  │  Code Quality   │
│ Static analysis  │  │ Full test suite │  │ Sync            │  │ Anti-pattern    │
│ flutter analyze  │  │ + coverage      │  │ TR/EN/DE keys   │  │ scanner         │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │                    │
         └──────── Required status checks (must pass to merge) ───────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Golden Test    │  │  Android Build  │  │   iOS Build     │
│ Visual regres-  │  │ APK debug build │  │ --no-codesign   │
│ sion testing    │  │ (ubuntu)        │  │ (macOS)         │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

**Branch protection** on `main`: PR required, 4 required status checks, no force push, auto-delete on merge.

## Contributing

### Workflow

```bash
# 1. Branch from main
git checkout -b feat/your-feature

# 2. Develop & verify locally
flutter analyze && flutter test
python scripts/check_l10n_sync.py
python scripts/verify_code_quality.py

# 3. Commit (Conventional Commits)
git commit -m "feat(birds): add batch delete functionality"

# 4. Push & open PR
git push -u origin feat/your-feature
```

### Commit Convention

| Type | Usage | Example |
|------|-------|---------|
| `feat` | New feature | `feat(genetics): add epistasis support` |
| `fix` | Bug fix | `fix(sync): resolve egg push order conflict` |
| `refactor` | Restructure | `refactor(breeding): extract pair validator` |
| `test` | Tests | `test(chicks): add growth form widget tests` |
| `perf` | Performance | `perf(home): use COUNT query for dashboard` |
| `chore` | Config/deps | `chore(deps): update riverpod to 3.1.0` |
| `docs` | Documentation | `docs: update README architecture diagram` |
| `ci` | CI pipeline | `ci: add coverage threshold check` |

### Branch Naming

```
feat/<description>       fix/<description>       refactor/<description>
test/<description>       chore/<description>     hotfix/<description>
```

## Acknowledgments

This project is built on the shoulders of amazing open-source communities:

- [Flutter](https://flutter.dev) & [Dart](https://dart.dev) — Cross-platform framework and language
- [Supabase](https://supabase.com) — Open-source Firebase alternative (PostgreSQL, Auth, Storage)
- [Riverpod](https://riverpod.dev) — Reactive state management for Flutter
- [Drift](https://drift.simonbinder.eu) — Reactive persistence library for Dart & Flutter
- [Freezed](https://pub.dev/packages/freezed) — Code generation for immutable data classes
- [Sentry](https://sentry.io) — Error tracking and performance monitoring

## License

This project is proprietary software. All rights reserved.

---

<p align="center">
  <sub>Built with</sub><br/>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white&style=for-the-badge" alt="Flutter" /></a>
  &nbsp;
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white&style=for-the-badge" alt="Supabase" /></a>
  &nbsp;
  <a href="https://riverpod.dev"><img src="https://img.shields.io/badge/Riverpod-00B0FF?logo=dart&logoColor=white&style=for-the-badge" alt="Riverpod" /></a>
  &nbsp;
  <img src="https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white&style=for-the-badge" alt="SQLite" />
</p>

<p align="center">
  <a href="https://budgiebreedingtracker.online"><strong>budgiebreedingtracker.online</strong></a>
</p>
