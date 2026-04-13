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

## Billing / Runner Failures
- Tum job'lar 0-5 saniyede dusuyorsa: Actions account durumunu kontrol et
- Annotation'larda `billing issue`, `account is locked` ara
- Billing kilidi varken scheduled workflow'lari gecici disable et

## Workflow Hygiene
- Gecici degisiklikler bitince schedule job'larini yeniden enable et
- Tekrar eden failure: once workflow'u duzelt, sonra eski run'lari temizle
- Debug araclari: `gh run list`, `gh run view`, `gh api .../check-runs/.../annotations`
- CI job isimleri degisirse branch protection / required checks'i guncelle

## Deployment Safety
- GitHub Pages, Supabase deploy ve store release job'larini gereksiz birbirine baglama
- Production deploy'da branch ve event filter'lari acik olsun
- Environment/secrets isimlerini workflow dosyasinda belgeleyip kodda hardcode etme

> **Ilgili**: release-ops.md (deploy akisi), branch-workflow.md (branch protection), ai-workflow.md (kalite kapilari)
