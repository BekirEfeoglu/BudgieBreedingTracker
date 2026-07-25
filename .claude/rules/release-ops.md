# Release & Operations

## Release Channels
| Channel | Platform | Purpose |
|---------|----------|---------|
| GitHub Actions | CI | Dogrulama, hafif deployment |
| Xcode Cloud | iOS | Build-only status check — release yolu DEGIL |
| GitHub Actions `release-ready.yml` | Android | Manual signed AAB + Sentry symbol artifact; store'a hicbir sey publish ETMEZ |
| `scripts/build_release.sh android` | Android | Ayni build'in local karsiligi (dogrulama) |
| `scripts/build_release.sh ios` | iOS | `build/ios/archive/Runner.xcarchive`; dagitim Xcode Organizer ile manuel |
| GitHub Pages | Web | `docs/` deployment |

**Codemagic 2026-07-25'te kaldirildi** (`codemagic.yaml` silindi). Artik hosted
bir release pipeline'i YOK; hicbir sey otomatik olarak store'a publish etmez.
Store yuklemesi her iki platformda da manuel bir kullanici islemidir.

- App Store / Google Play publish mantigini GitHub Actions'a tasima
- Main push CI'si release artifact uretmemeli; signed AAB icin manuel
  `Release Ready` workflow'unu kullan
- `release-ready.yml` signed AAB + Sentry symbol'lerini **artifact** olarak
  uretir; publishing blogu veya Google Play credential referansi EKLEME —
  artifact'i indirip Play'e kendin yuklersin
- `android-symbols-<sha>` artifact'i native debug symbol'lerinin YANINDA
  `build/app/obfuscation.map.json`'u da tasir. **Bu harita `flutter symbolize`
  girdisi DEGILDIR** — `flutter symbolize --help`'e gore o komut yalniz
  `--debug-info` (split-debug-info sembol dosyasi) + `--input` (stack trace)
  alir; stack frame cozumu sembol dosyasiyla yapilir. Harita, obfuscate edilmis
  *identifier adlarinin* ayri JSON eslemesidir ve `pubspec.yaml` icindeki
  `sentry: dart_symbol_map_path` ile Sentry tarafindan okunur. Artifact'a
  konmasinin sebebi: bu eslemeyi tasiyan tek build ciktisi odur ve Sentry
  upload'i kaybolursa offline bir kopya kalir. Iki path verildigi icin artifact
  koku `build/`'dir: girdiler `symbols/android/...` ve
  `app/obfuscation.map.json` olarak acilir
- `release-ready.yml` ve Xcode Cloud Flutter SDK'sini `3.41.4`'e pinli tutar;
  `stable` kanal drift'ini release aninda kabul etme. 2026-07-18'de bir release
  builder `stable` uzerinden 3.44.6'ya kaydi ve locked `lucide_icons 0.257.0`
  (`IconData` final oldu) release compile'ini bozdu. SDK ve locked dependency
  uyumlulugunu koordine edip tum builder'lari birlikte yukselt.
- **Google Play version code paket genelinde benzersizdir.** `pubspec.yaml`
  build numarasi TUM track'ler ve artifact library'deki en yuksek koddan buyuk
  olmali. Bu eskiden Codemagic tarafindan otomatik cozuluyordu; artik release
  oncesi **manuel** sorumluluktur — hedef track'e bakip kullanilmis bir kodu
  yeniden secme.
- `docs/` deployment mobil app release'lerinden ayri deger
- Xcode Cloud Flutter build temiz clone'da `ios/ci_scripts/ci_post_clone.sh` ile hazirlanir; script Flutter SDK'yi pinned zip'in curl+unzip'i ile kurar (`git clone flutter/flutter` DEGIL — Xcode Cloud'da bilinen flaky, ci-actions.md § Deployment Safety) ve her adimdan once `>>> STEP N:` marker basar
- Xcode Cloud main workflow build-only olmalidir; archive/TestFlight/App Store export ancak Apple signing hesabi, Development/Ad Hoc profil ihtiyaci ve kayitli fiziksel cihazlar hazirsa acilir

## Version Bump
- `pubspec.yaml` icindeki `version: X.Y.Z+build` formatini kullan
- Semantic versioning: major.minor.patch
  - **major**: breaking changes (nadiren)
  - **minor**: yeni ozellik
  - **patch**: bug fix
- Build number her release'de arttirilmali
- iOS ve Android build numaralari tutarli olmali
- Android'de build numarasi package-wide Play maksimumundan buyuk olmali
  (§ Release Channels — artik otomatik cozulmuyor)

## Release Build (`scripts/build_release.sh`)
Kanonik release build'i: `scripts/build_release.sh <ios|android>`.

Sirasiyla: `.env` icinde `SENTRY_DSN` ve ortamda `SENTRY_AUTH_TOKEN` yoksa
**fail-fast** -> `flutter pub get` + `build_runner` -> (iOS'ta ayrica
`scripts/generate_ios_env.sh`) -> `flutter build ipa|appbundle --release
--dart-define-from-file=.env --obfuscate --split-debug-info=...
--extra-gen-snapshot-options=--save-obfuscation-map=...` -> `dart run
sentry_dart_plugin` ile symbol upload. `--save-obfuscation-map` bir `flutter
build` bayragi DEGILDIR; yalniz `--extra-gen-snapshot-options` uzerinden Dart
native compiler'a gecirilir (`flutter build appbundle --help` ile dogrulandi).
Uretilen harita `build/app/obfuscation.map.json`; `pubspec.yaml` icindeki
`sentry: dart_symbol_map_path` ayni yolu gostermeli, aksi halde Dart stack
trace'leri obfuscated kalir.
`SENTRY_RELEASE` platform basina runtime `PackageInfo` adlandirmasini birebir
yansitir (`com.budgiebreeding.tracker` / `com.budgiebreeding.budgie_breeding_tracker`).

Iki degerin eksikligi build'i KIRMAZ, sessizce bozuk bir release uretir — bu
yuzden script'te loud fail-fast'tirlar:
- `SENTRY_DSN` yoksa: crash reporting'i hic olmayan bir release
- `SENTRY_AUTH_TOKEN` yoksa: kimsenin okuyamadigi obfuscated stack trace'ler

**Xcode'dan dogrudan Archive ALMA.** `ios/Flutter/DartDefines.xcconfig`
gitignored'dir ve yalnizca bir `flutter build` tarafindan yeniden yazilir;
Archive ne bulursa onu okur. Repo'da bulunan bayat bir kopya legacy Google web
client ID'sini tasiyordu ve `SENTRY_DSN` HIC yoktu — yani Archive o an
tamamen crash-reporting'siz bir release uretirdi. Script'i once calistirmak bu
dosyayi `.env`'den yeniden uretir; hazard'in tek yapisal savunmasi budur.

Dagitim: iOS'ta `build/ios/archive/Runner.xcarchive` -> Xcode Organizer
(Distribute App). `flutter build ipa` yerelde arsivde durur; export-options
plist ureten bir sey yok (Codemagic bunu `xcode-project use-profiles` ile
sagliyordu). Script hangi artefakt olustuysa onu bildirir.
Android'de tercih `release-ready.yml` (temiz checkout); script local dogrulama icin.

## Environment Discipline
- `--dart-define` ile gelen runtime config'i kodda fallback secret gibi kullanma
- `.env` dosyasini source of truth kabul etme; release'de secrets manager kullan
- Eksik env varsa fail-fast davran; sessiz fallback ile production degistirme
- Production Android/iOS release'leri `SENTRY_DSN` olmadan uretilmemeli;
  GitHub Actions secret'i (`release-ready.yml`) ile local `.env` senkron kalmali
  ve `scripts/build_release.sh` bunu fail-fast kontrol eder
- Obfuscated release build'i `obfuscation.map.json` uretmeli ve
  `sentry_dart_plugin` ile symbol upload tamamlanmadan publish'e gecmemeli;
  `SENTRY_AUTH_TOKEN` yalniz `org:ci` kapsamli organizasyon token'i olmali
- Symbol upload `SENTRY_RELEASE`/`SENTRY_DIST` degerleri runtime
  `PackageInfo` adlandirmasiyla ayni package/bundle ID ve gercek build numarasini
  kullanmali; Dart package name varsayimina birakma
- Edge Function deployment secret'lari sadece CI ortaminda
- Edge Function deploy'u Edge source/config/deploy-workflow path guard'i ile
  sinirla; `docs/**`-only main push'ta production function'larini yeniden deploy etme

## Supabase Operations
- Yerel e-posta yakalama ayari `[local_smtp]` bolumunu kullanmali;
  Supabase CLI'nin deprecated `[inbucket]` alias'ini geri getirme
- Edge Function isimleri workflow ve kod referanslarinda birebir tutarli olmali
- Yeni function eklenirse:
  1. `supabase/functions/<name>/` altina kod ekle
  2. `supabase/config.toml` altina explicit `verify_jwt` ayari ekle
  3. Deno test dosyasi ekle
  4. Deploy workflow'una ekle
  5. Gerekiyorsa ilgili service/provider katmanini guncelle
- Client code'dan RLS degistirme, migration uydurma, production schema "tamir etme" yapma

## Release Safety
- Release oncesi kalite kapilari gecmeli (bkz. ai-workflow.md § Quality Gates)
- Manuel `Release Ready` calistirmadan once main'in remote status'u `python3 scripts/check_remote_status.py` ile temiz olmali
- Store release oncesi version bump tutarliligini kontrol et
- iOS ve Android release config'leri birbirinden bagimsiz hata ayiklanabilir tut
- Release branch'i gerekiyorsa guncel `main`den kisa sureli kes; release tamamlaninca remote branch'i sil
- Xcode Cloud build hatalarinda once generated Dart dosyalari, `Generated.xcconfig` ve `Pods-Runner-*.xcfilelist` uretilmis mi kontrol et; bu dosyalari commit etme, post-clone script'i duzelt
- Xcode Cloud archive/export hatalarinda `Development` veya `Ad Hoc` export gorulurse once Apple Developer hesabinda kayitli fiziksel cihaz ve provisioning profile gereksinimlerini dogrula
- Xcode Cloud `pod install` hatalarinda ag/DNS kaynakli pod arsivi indirme sorunlarini ayir; transient indirme hatalari icin `ios/ci_scripts/ci_post_clone.sh` retry/backoff davranisini koru
- Xcode Cloud `pod install` dependency/lock uyumsuzlugu hata verirse retry helper gercek exit code ile fail etmeli; basarisiz pod kurulumundan sonra "dependencies ready" yazip Xcode build'e gecmemeli
- Xcode Cloud iOS dependency bump'larinda `pubspec.lock` ve `ios/Podfile.lock` birlikte senkron kalmali; temiz clone'da post-clone script'i Pods filelist dogrulamasindan gecmeli

## Release Verification Closure
- Release/CI duzeltmesi ancak exact commit uzerinde GitHub status `success` ve check-run ozeti tamamen `completed:success` veya kabul edilen `completed:skipped` ise kapanmis sayilir
- Path-gated `Deploy Edge Functions` skip'i yalniz ayni committeki `Edge Function Changes` dedektoru basariliysa kabul edilir; exact-SHA script'i bu kosulu dogrular
- Xcode Cloud icin App Store Connect status context'i ve `BudgieBreedingTracker | Default | Build - iOS` check-run'i ayni committe `success` olmali
- Main-only deploy/build job'lari sonradan tetiklenebilir; final durum icin tum gec gelen check-run'lar da tamamlanana kadar bekle
- Bir run'da export/provisioning hatasi gorulurse build-only workflow ayarini degistirme; once fiziksel cihaz/profil hazirligini kanitla

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
8. Eski commit/run yesil oldugu icin yeni commit'i dogrulanmis saymak
9. Xcode Cloud `action_required` durumunu warning kabul edip kapatmak
10. Android build numarasini tek track'ten okuyup baska track/artifact'ta
    kullanilmis version code'u yeniden secmek (artik otomatik cozum yok —
    package-wide maksimumu elle dogrula)
11. `scripts/build_release.sh`'i atlayip Xcode'dan dogrudan Archive almak
    (bayat `DartDefines.xcconfig` -> DSN'siz/yanlis client ID'li release,
    § Release Build)
12. Store'a publish eden bir job/pipeline geri eklemek — release-ready.yml
    ve script bilincli olarak yalniz artifact uretir; yukleme manuel

> **Ilgili**: ci-actions.md (workflow detaylari), branch-workflow.md (merge policy), ai-workflow.md (kalite kapilari)
