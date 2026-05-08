# CI & GitHub Actions

## Workflow Design
- Action'lari version tag yerine pinned commit SHA ile kullan
- `pull_request` vs `pull_request_target` secimini bilincli yap:
  - Fork veya bot PR metadata islemleri: `pull_request_target`
  - Kod calistiran normal PR validation: `pull_request`
- Minimum permission ver: `contents: read`, `pull-requests: read`
- Secrets gerektiren veya deploy yapan job'lar sadece `main` push'ta calissin

## CI Jobs (bkz. CLAUDE.md § CI/CD Pipeline)
| Job | Gate | Blocker |
|-----|------|---------|
| `analyze` | `flutter analyze --no-fatal-infos` | PR merge |
| `test` | Unit + widget tests, Codecov | PR merge |
| `golden-test` | Visual regression (Linux) | PR merge |
| `scripts-test` | Python script tests (>=98% cov) | PR merge |
| `l10n-sync` | Translation key parity | PR merge |
| `code-quality` | Anti-pattern scan | PR merge |
| `rules-sync` | CLAUDE.md stats verification | PR merge |
| `auto-fix-stats` | Auto-PR for stats drift | main only |
| `deploy-edge-functions` | Supabase Edge Function deploy | main only, needs analyze+test |

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

## Deployment Safety
- GitHub Pages, Supabase deploy ve store release job'larini gereksiz birbirine baglama
- Production deploy'da branch ve event filter'lari acik olsun
- Environment/secrets isimlerini workflow dosyasinda belgeleyip kodda hardcode etme
- Xcode Cloud GitHub Actions degildir; kirmizi Xcode Cloud check'lerinde App Store Connect/GitHub check-run detaylarini oku
- Xcode Cloud main workflow build-only kalmali (`Build - iOS`, scheme `Runner`, `Any iOS Simulator`); archive/TestFlight/App Store export ancak Apple signing hesabi ve kayitli fiziksel cihaz/profil gereksinimleri hazir oldugunda acilmali
- Flutter iOS build icin `ios/ci_scripts/ci_post_clone.sh` executable kalmali; clean clone'da `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs` ve `pod install` generated Dart dosyalarini, `Generated.xcconfig`i ve Pods filelist'lerini uretir
- Xcode Cloud post-clone script'indeki ag bagimli adimlar retry/backoff ile calismali; `sqlite3` gibi pod kaynak arsivleri dis host DNS/download hatalariyla tek denemede build'i dusurmemeli

> **Ilgili**: release-ops.md (deploy akisi), branch-workflow.md (branch protection), ai-workflow.md (kalite kapilari)
