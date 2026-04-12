# CI & GitHub Actions

## Workflow Design
- Workflow'larda action'lari version tag yerine pinned commit SHA ile kullan.
- `pull_request` ve `pull_request_target` secimini bilincli yap:
  - Fork veya bot PR metadata islemleri icin `pull_request_target`
  - Kod calistiran normal PR validation icin `pull_request`
- Yazma izni gerektirmeyen job'larda minimum permission ver:
  - `contents: read`
  - `pull-requests: read`
- Secrets gerektiren veya deploy yapan job'lari sadece `main` push'ta calistir.

## Dependabot Rules
- Dependabot tetiklemeli workflow'larda auto-merge veya label yazma islemlerine guvenme.
- Dependabot tarafinda `GITHUB_TOKEN` read-only gelebilir; merge/edit/label adimlari kolayca fail olur.
- Dependabot workflow'lari triage veya summary odakli olsun; destructive veya write action kullanma.
- Dependabot PR metadata icin `dependabot/fetch-metadata` kullan, ama sonucu summary/notice seviyesinde tut.

## Billing / Runner Failures
- Tum job'lar 0-5 saniye icinde ayni anda dusuyorsa once repository kodunu degil Actions account durumunu kontrol et.
- Check run annotation'larinda `billing issue`, `account is locked`, `resource not accessible` gibi mesajlari kontrol et.
- Billing kilidi varken surekli fail uretecek scheduled workflow'lari gecici olarak disable et.
- Tarihi failure run'lari temizlemek gerekiyorsa `gh run delete` ile sil, ama kok nedeni not etmeden "duzeldi" varsayma.

## Workflow Hygiene
- Gecici workflow degisiklikleri bittiginde schedule job'larini yeniden enable etmeyi unutma.
- Tekrar eden failure kaynagi bir workflow ise once workflow'u duzelt, sonra eski run'lari temizle.
- `gh run list`, `gh run view`, `gh api .../check-runs/.../annotations` komutlari temel debug araclaridir.
- CI kurali veya job isimleri degisirse branch protection / required checks etkisini kontrol et.

## Repo-Specific Gates
- PR ve `main` push validation akisinda su kontroller bozulmamalidir:
  - `flutter analyze --no-fatal-infos`
  - `flutter test`
  - `python3 scripts/verify_code_quality.py`
  - `python3 scripts/check_l10n_sync.py --strict-keys`
  - `python3 scripts/verify_rules.py --strict`
- `auto-fix-stats` gibi bot commit acan job'lar yalniz `main` push'ta calissin.
- Supabase Edge Function deploy job'lari test/analyze basarisizsa tetiklenmemeli.

## Deployment Safety
- GitHub Pages, Supabase deploy ve store release job'larini ayni workflow icinde gereksiz birbirine baglama.
- Production deploy adimlarinda branch ve event filter'lari acik olsun.
- Deploy job'larinda environment/secrets isimlerini dosyada belgeleyip local kodda hardcode etme.
