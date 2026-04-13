# Release & Operations

## Release Channels
| Channel | Platform | Purpose |
|---------|----------|---------|
| GitHub Actions | CI | Dogrulama, hafif deployment |
| Codemagic | App Store / Google Play | Production release |
| GitHub Pages | Web | `docs/` deployment |

- App Store / Google Play publish mantigini GitHub Actions'a tasima
- `docs/` deployment mobil app release'lerinden ayri deger

## Version Bump
- `pubspec.yaml` icindeki `version: X.Y.Z+build` formatini kullan
- Semantic versioning: major.minor.patch
  - **major**: breaking changes (nadiren)
  - **minor**: yeni ozellik
  - **patch**: bug fix
- Build number her release'de arttirilmali
- iOS ve Android build numaralari tutarli olmali

## Environment Discipline
- `--dart-define` ile gelen runtime config'i kodda fallback secret gibi kullanma
- `.env` dosyasini source of truth kabul etme; release'de secrets manager kullan
- Eksik env varsa fail-fast davran; sessiz fallback ile production degistirme
- Edge Function deployment secret'lari sadece CI ortaminda

## Supabase Operations
- Edge Function isimleri workflow ve kod referanslarinda birebir tutarli olmali
- Yeni function eklenirse:
  1. `supabase/functions/<name>/` altina kod ekle
  2. Deploy workflow'una ekle
  3. Gerekiyorsa ilgili service/provider katmanini guncelle
- Client code'dan RLS degistirme, migration uydurma, production schema "tamir etme" yapma

## Release Safety
- Release oncesi kalite kapilari gecmeli (bkz. ai-workflow.md § Quality Gates)
- Store release oncesi version bump tutarliligini kontrol et
- iOS ve Android release config'leri birbirinden bagimsiz hata ayiklanabilir tut
- Release branch'i kesmeden once `develop`in temiz oldugunu dogrula

## Documentation Drift
- CI, release veya deploy akisi degisirse ilgili kural dosyalarini guncelle
- Yeni secret, workflow veya adim eklendiginde: rule file + CLAUDE.md + workflow yorumlari birlikte guncellenmeli
- Sayisal metrik drift'i: `python3 scripts/verify_rules.py --fix`

## Operational Anti-Patterns
1. Billing kilidini kod sorunu sanmak
2. Failed workflow'lari silip kok nedeni kaydetmemek
3. Dependabot workflow'larinda write permission varsaymak
4. Secrets gereken deploy job'larini PR event'lerinde calistirmak
5. CI basarisizken release/deploy tetiklemek
6. Release davranisini sadece local test ile dogrulanmis saymak
7. Version bump yapmadan store release gondermek

> **Ilgili**: ci-actions.md (workflow detaylari), branch-workflow.md (merge policy), ai-workflow.md (kalite kapilari)
