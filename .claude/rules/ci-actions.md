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
| `test` | Unit + widget tests, optional Codecov when `CODECOV_TOKEN` exists | PR merge |
| `golden-test` | Visual regression (Linux) | PR merge |
| `edge-functions-test` | `deno test --allow-env --allow-net supabase/functions` | PR merge + Edge deploy |
| `scripts-test` | Python script tests (>=98% cov) | PR merge |
| `l10n-sync` | Translation key parity | PR merge |
| `code-quality` | Anti-pattern scan | PR merge |
| `rules-sync` | CLAUDE.md stats verification | PR merge |
| `auto-fix-stats` | Auto-PR for stats drift | main only |
| `deploy-edge-functions` | Supabase Edge Function deploy | main only, needs analyze+test+edge-functions-test |

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

## Billing / Runner Failures
- Tum job'lar 0-5 saniyede dusuyorsa: Actions account durumunu kontrol et
- Annotation'larda `billing issue`, `account is locked` ara
- Billing kilidi varken scheduled workflow'lari gecici disable et

## Workflow Hygiene
- Workflow YAML'i push oncesi local parse et: `ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' .github/workflows/<file>.yml`
- `run:` satirinda `:` iceren komutlari quote et veya block scalar kullan; aksi halde Actions run'i jobs/log olmadan 0 saniyede fail olabilir
- Event/actor/job-level `if:` filtreleri tum job'lari skip edebiliyorsa no-op guard job ekle; GitHub'da kirmizi workflow olusmasin
- Gecici degisiklikler bitince schedule job'larini yeniden enable et
- Tekrar eden failure: once workflow'u duzelt, sonra eski run'lari temizle
- Debug araclari: `gh run list`, `gh run view`, `gh api .../check-runs/.../annotations`
- CI job isimleri degisirse branch protection / required checks'i guncelle
- Supabase Edge Function deploy job'u `edge-functions-test` sonucuna bagli kalmali; function source veya shared helper degistiginde Deno testleri deploy oncesi kosmali
- Codecov upload token gerektiriyorsa test job'unu kirmiziya dusurme; `CODECOV_TOKEN` yokken upload adimini intentional skip/no-op yap

## Post-Push Verification
- Push sonrasi sadece GitHub Branches UI rozetine bakma; exact commit SHA icin status ve check-run API'larini birlikte kontrol et
- Zorunlu status ornegi:
  ```bash
  python3 scripts/check_remote_status.py
  ```
- Basari saymak icin status state `success`, tum check-run'lar `completed` olmali; yalnizca bilinen/intentional skipped job kabul edilir
- `in_progress`, `queued`, `failure`, `error`, `action_required` veya conclusion'siz check varken "temiz" ya da "cozuldu" deme
- Workflow UI degisikligi yapildiysa once yeni commit veya clean rebuild ile yeni run baslat; eski run sonucunu yeni ayarin kaniti sayma

## Deployment Safety
- GitHub Pages, Supabase deploy ve store release job'larini gereksiz birbirine baglama
- Production deploy'da branch ve event filter'lari acik olsun
- Environment/secrets isimlerini workflow dosyasinda belgeleyip kodda hardcode etme
- Xcode Cloud GitHub Actions degildir; kirmizi Xcode Cloud check'lerinde App Store Connect/GitHub check-run detaylarini oku
- Xcode Cloud main workflow build-only kalmali (`Build - iOS`, scheme `Runner`, `Any iOS Simulator`); archive/TestFlight/App Store export ancak Apple signing hesabi ve kayitli fiziksel cihaz/profil gereksinimleri hazir oldugunda acilmali
- Flutter iOS build icin `ios/ci_scripts/ci_post_clone.sh` executable kalmali; clean clone'da `flutter pub get`, `dart run build_runner build` ve `pod install` generated Dart dosyalarini, `Generated.xcconfig`i ve Pods filelist'lerini uretir
- Xcode Cloud post-clone script'indeki ag bagimli adimlar retry/backoff ile calismali; `sqlite3` gibi pod kaynak arsivleri dis host DNS/download hatalariyla tek denemede build'i dusurmemeli

> **Ilgili**: release-ops.md (deploy akisi), branch-workflow.md (branch protection), ai-workflow.md (kalite kapilari)
