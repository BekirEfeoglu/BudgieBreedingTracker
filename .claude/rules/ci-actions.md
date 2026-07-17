# CI & GitHub Actions

## Workflow Design
- Action'lari version tag yerine pinned commit SHA ile kullan
- `ci.yml` branch filtresi main-only akisa uyar: push ve PR validation `main` icindir
- `pull_request` vs `pull_request_target` secimini bilincli yap:
  - Fork veya bot PR metadata islemleri: `pull_request_target`
  - Kod calistiran normal PR validation: `pull_request`
- Minimum permission ver: `contents: read`, `pull-requests: read`
- Secrets gerektiren veya deploy yapan job'lar sadece `main` push'ta calissin

## CI Jobs (bkz. CLAUDE.md § CI/CD Pipeline)
| Job | Gate | Blocker |
|-----|------|---------|
| `analyze` | `flutter analyze --no-fatal-infos` | PR merge |
| `test` | Unit + widget tests (random order via `--test-randomize-ordering-seed random`), optional Codecov when `CODECOV_TOKEN` exists | PR merge |
| `golden-test` | Visual regression (Linux) | PR merge |
| `edge-functions-test` | `deno test --allow-env --allow-net supabase/functions` | PR merge + Edge deploy |
| `scripts-test` | Python script tests (>=98% cov) | PR merge |
| `l10n-sync` | Translation key parity | PR merge |
| `code-quality` | Anti-pattern scan + platform target policy + obsidian-brain lint + migration drift structure guard + rule symbol drift guard | PR merge |
| `rules-sync` | CLAUDE.md stats verification | PR merge |
| `security-audit` | `python scripts/verify_security.py` — cert pinning, secrets posture | PR merge |
| `auto-fix-stats` | Auto-PR for stats drift | main only |
| `edge-function-changes` | Edge source/config/deploy-workflow path guard | main push |
| `deploy-edge-functions` | Supabase Edge Function deploy | main only, path-gated, needs analyze+test+edge-functions-test |

## Release-Ready Workflow
- `release-ready.yml` manuel calisir; main push CI'sini store artifact uretimiyle yavaslatma
- `Release Ready Plan` no-op guard job'i workflow_dispatch eventinde en az bir job'in calismasini garanti eder
- `Android Release (AAB)` sadece manuel release hazirlik kontrolunde signed AAB ve Dart symbol artifact uretir
- Main push icin `android-build` debug APK smoke gate olarak kalir; store'a gidecek AAB icin release-ready veya Codemagic kullan

## Dependabot Rules
- Auto-merge veya label yazma islemlerine guvenme
- `GITHUB_TOKEN` read-only gelebilir; merge/edit/label kolayca fail olur
- Workflow'lari triage/summary odakli tut; destructive action kullanma
- PR metadata icin `dependabot/fetch-metadata` kullan
- Dependabot disi eventlerde workflow'un kirmiziya dusmemesi icin no-op guard job bulundur
- Dependency bump main'e alinmadan once `flutter pub get` lockfile'i degistiriyor mu kontrol et; CI'da `flutter pub get` yeni lock uretiyorsa `pubspec.lock` committe eksiktir.
- Flutter plugin iOS pod dependency'si degisirse `ios/Podfile.lock` da senkronlanmali; `pod install` snapshot uyumsuzlugu verirse ilgili pod icin `pod update <PodName>` kullan ve sonucu commit et.
- Dependabot minor/patch bump'lari bile transitive Flutter SDK pinleriyle uyumsuz olabilir; `pubspec.lock`, `ios/Podfile.lock`, local analyze/test ve Xcode Cloud post-clone simülasyonu birlikte kanit sayilir.

## Billing / Runner Failures
- Tum job'lar 0-5 saniyede dusuyorsa: Actions account durumunu kontrol et
- Annotation'larda `billing issue`, `account is locked` ara
- Billing kilidi varken scheduled workflow'lari gecici disable et

## Random Test Ordering
- The `test` job runs with `--test-randomize-ordering-seed random` (enabled 2026-07-13 after the suite was verified order-independent). Each `flutter test` file runs in its own isolate, so leaks are WITHIN-file (test order in one `main()`).
- A red `test` job printing `Some tests failed` under a shuffled order (the log's `Shuffling test order with --test-randomize-ordering-seed=NNNN` line names the seed) is a **new order-dependency, not flakiness** — reproduce locally with `flutter test <file> --test-randomize-ordering-seed <NNNN>` and fix the shared state (test-stability.md #2/#3/#9). Do NOT disable random ordering to go green.
- Common cause: a test that loads real l10n (`pumpTranslatedWidget` / `RealTestAssetLoader`) sharing a file with raw-key assertions — easy_localization caches translations in a process-static per-locale. Fix by moving the real-translation test to its own file (separate isolate). Canonical example: `admin_monitoring_content_translated_test.dart`.

## Workflow Hygiene
- Workflow YAML'i push oncesi local parse et: `ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' .github/workflows/<file>.yml`
- `run:` satirinda `:` iceren komutlari quote et veya block scalar kullan; aksi halde Actions run'i jobs/log olmadan 0 saniyede fail olabilir
- Event/actor/job-level `if:` filtreleri tum job'lari skip edebiliyorsa no-op guard job ekle; GitHub'da kirmizi workflow olusmasin
- Gecici degisiklikler bitince schedule job'larini yeniden enable et
- Tekrar eden failure: once workflow'u duzelt, sonra eski run'lari temizle
- Debug araclari: `gh run list`, `gh run view`, `gh api .../check-runs/.../annotations`
- CI job isimleri degisirse branch protection / required checks'i guncelle
- Supabase Edge Function deploy job'u `edge-functions-test` sonucuna bagli kalmali; function source veya shared helper degistiginde Deno testleri deploy oncesi kosmali
- `deploy-edge-functions` yalniz `supabase/functions/**`, `supabase/config.toml`
  veya `.github/workflows/ci.yml` degistiginde calismali. `docs/**`-only push
  production Edge Function'larini yeniden deploy etmemeli.
- Codecov upload token gerektiriyorsa test job'unu kirmiziya dusurme; `CODECOV_TOKEN` yokken upload adimini intentional skip/no-op yap

## Post-Push Verification
- Push sonrasi sadece GitHub Branches UI rozetine bakma; exact commit SHA icin status ve check-run API'larini birlikte kontrol et
- Zorunlu status ornegi:
  ```bash
  python3 scripts/check_remote_status.py
  ```
- Basari saymak icin: commit **status `success`** VE tum **required `ci.yml` check-run'lari** `completed:success` olmali (bilinen/intentional skipped kabul). Branch UI rozeti (`17/19` gibi) required-olmayan bir check patlayinca da kirmizi olur — tek basina "basarisiz" sayma (bkz. § Non-Required / Transient Checks)
- Main-only deploy veya Xcode Cloud gibi gec gelen check-run'lar sonradan baslayabilir; ilk `success` durumundan sonra script hala unfinished check gosteriyorsa kapanis yapma, poll etmeye devam et
- `in_progress`, `queued`, `failure`, `error`, `action_required` veya conclusion'siz check varken "temiz" ya da "cozuldu" deme
- Workflow UI degisikligi yapildiysa once yeni commit veya clean rebuild ile yeni run baslat; eski run sonucunu yeni ayarin kaniti sayma

### Non-Required / Transient Checks (GitHub Pages `deploy`)
`main` push'unda en sik "sahte kirmizi" kaynagi budur; kod hatasiyla karistirma.
- `pages-build-deployment` (jobs: `build` / `deploy` / `report-build-status`) GitHub'in `docs/` GitHub Pages sitesi icin **otomatik urettigi** workflow'dur — `ci.yml`'de DEGILDIR, **required status check DEGILDIR**, uygulamayi/branch merge'ini bloklamaz. `check_remote_status.py` ciktisinda ci.yml'den **ayri bir run ID** altinda gorunur.
- `deploy` job'i sik sik **gecici** patlar: `Deployment failed, try again later.` (Pages backend) ya da legacy build `building`de asili kalir. **Kod hatasi DEGILDIR:** `docs/` degismediyse deploy edilen icerik oncekiyle birebir ayni ve `build` job'i ✓ gecer.
- Teshis: tek basarisiz check-run **yalnizca** `pages-build-deployment` run'i altindaki `deploy` ise → gecici, gecebilirsin. Legacy build durumu: `gh api repos/<owner>/<repo>/pages -q .status` (`building`de takiliysa GitHub-side hang; `built`/`errored` terminal).
- **Kovalama sinirli:** en fazla **1** `gh run rerun --failed <pages_run_id>` (istersen `gh api -X POST repos/<owner>/<repo>/pages/builds` ile taze build). Hala patliyor + build `building`de asiliysa bu GitHub Pages altyapi sorunudur, repo'dan cozulmez — **saatlerce re-run etme**. Kendiliginden duzelir: backend toparlayinca bir sonraki `main` push'u (veya re-run) temiz deploy eder.
- **Tamamlanma:** commit `status success` + tum required `ci.yml` check'leri yesilse push **dogrulanmis** sayilir; yalniz Pages `deploy`in kirmizi kalmasi bunu gecersizlestirmez — handoff'ta "GitHub-side Pages transient, non-blocking" notu birak.
- `check_remote_status.py` ciktisini otomatik parse ederken **ozet sayaci satirlarini** (`completed:failure: 1`) degil yalniz **check-run girdi satirlarini** (`- <ad> (completed:failure) <url>`) esle ve failure kararinda Pages run ID'sini haric tut; aksi halde Pages transient'i gercek CI hatasi gibi gorunur.

## Deployment Safety
- GitHub Pages, Supabase deploy ve store release job'larini gereksiz birbirine baglama
- Production deploy'da branch ve event filter'lari acik olsun
- Environment/secrets isimlerini workflow dosyasinda belgeleyip kodda hardcode etme
- Xcode Cloud GitHub Actions degildir; kirmizi Xcode Cloud check'lerinde App Store Connect/GitHub check-run detaylarini oku
- Xcode Cloud main workflow build-only kalmali (`Build - iOS`, scheme `Runner`, `Any iOS Simulator`); archive/TestFlight/App Store export ancak Apple signing hesabi ve kayitli fiziksel cihaz/profil gereksinimleri hazir oldugunda acilmali
- Flutter iOS build icin `ios/ci_scripts/ci_post_clone.sh` executable kalmali; clean clone'da `flutter pub get`, `dart run build_runner build` ve `pod install` generated Dart dosyalarini, `Generated.xcconfig`i ve Pods filelist'lerini uretir
- Post-clone Flutter SDK kurulumu **pinned zip'in curl+unzip'i** ile yapilir (arch-aware `flutter_macos[_arm64]_<ver>-stable.zip`); `git clone flutter/flutter` Xcode Cloud'da bilinen intermittent failure'dir (flutter/flutter#163198, 2026-07-09'da tekrarlayan ~40s `Build - iOS` action_required'in gercek koku) — git clone'a GERI DONDURME
- drift_dev'in `Circular error when deserializing drift modules` mesaji **non-fatal WARNING**'dir (maintainer onayi: simolus3/drift#3227); build_runner exit 1 vermez. Post-clone/codegen fail'inin kok nedeni olarak KOVALAMA — gercek fail step'ini bul
- Post-clone `>>> STEP N:` marker'lari korunmali; Xcode Cloud yalniz generic `Running ci_post_clone.sh script failed (exited with code 1)` gosterir, log'daki SON marker fail eden step'i soyler
- Ardisik hizli main push'lari Xcode Cloud'un ARA build'lerini supersede/iptal ettirebilir (`action_required`); ara commit'lerin kirmizisini kod hatasi sayma, EN SON commit'in build sonucuna bak
- Xcode Cloud post-clone script'indeki ag bagimli adimlar retry/backoff ile calismali; `sqlite3` gibi pod kaynak arsivleri dis host DNS/download hatalariyla tek denemede build'i dusurmemeli
- Xcode Cloud post-clone retry helper'i gercek komut exit code'unu korumali; `pod install` gibi dependency hatalari yutulup Xcode build'e eksik Pods filelist'leriyle gecilmemeli
- Xcode Cloud post-clone script'i `pod install` sonrasi `Generated.xcconfig`, `Pods-Runner.*.xcconfig` ve `Pods-Runner-*.xcfilelist` dosyalarini fail-fast dogrulamali

> **Ilgili**: release-ops.md (deploy akisi), branch-workflow.md (branch protection), ai-workflow.md (kalite kapilari)
