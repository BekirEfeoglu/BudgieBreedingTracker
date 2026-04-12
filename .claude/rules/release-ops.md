# Release & Operations

## Release Channels
- GitHub Actions CI, dogrulama ve hafif deployment icindir.
- Codemagic production release icindir; App Store / Google Play publish mantigini GitHub Actions'a tasima.
- `docs/` ve Pages deployment mobil app release'lerinden ayri degerlendirilmelidir.

## Environment Discipline
- `--dart-define` ile gelen runtime config'i kodda fallback secret gibi kullanma.
- `.env` dosyasini source of truth kabul etme; release sistemlerinde secrets manager kullan.
- Eksik env varsa fail-fast davran; sessiz fallback ile production davranisini degistirme.
- Edge Function deployment icin gereken secret'lar sadece CI ortaminda kullanilsin.

## Supabase Operations
- Edge Function isimleri workflow ve kod referanslarinda birebir tutarli olmali.
- Yeni function eklenirse:
  - `supabase/functions/<name>/` altina kod ekle
  - deploy workflow'una ekle
  - gerekiyorsa ilgili service/provider katmanini guncelle
- Client code'dan RLS degistirme, migration uydurma veya production schema "tamir etme" girisimi yapma.

## Release Safety Checks
- Release oncesi en az su kontrol seti gecmis olmali:
  - analyze
  - test
  - l10n sync
  - code quality
- Store release veya deploy oncesi build numarasi / version bump tutarliligini kontrol et.
- iOS ve Android release konfigurasyonlarini birbirinden bagimsiz hata ayiklanabilir tut.

## Documentation Drift
- CI, release veya deploy akisi degisirse ilgili kural/dokuman dosyalarini da guncelle.
- Yeni secret, workflow veya release adimi eklendiginde:
  - ilgili rule file
  - README veya CLAUDE.md
  - workflow icindeki acik yorumlar
  birlikte guncellenmeli.
- Sayisal metrik drift'i varsa `python3 scripts/verify_rules.py --fix` calistir.

## Operational Anti-Patterns
1. Billing kilidini kod sorunu sanmak
2. Failed workflow'lari silip kok nedeni kaydetmemek
3. Dependabot workflow'larinda write permission varsaymak
4. Secrets gereken deploy job'larini PR event'lerinde calistirmak
5. CI basarisizken release/deploy tetiklemek
6. Release davranisini sadece local test ile dogrulanmis saymak
