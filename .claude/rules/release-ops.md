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
- **Sentry'ye map ABI BASINA bir kez yuklenir (3 kez) — bu israf DEGILDIR.**
  `sentry_dart_plugin` haritayi her ABI sembol dosyasiyla eslestirip o binary'nin
  kendi debug id'si altinda kaydeder (`attempted=3, succeeded=3`). Crash hangi
  mimariden geldiyse o debug id'yi tasir; tek yuklemeye indirmek diger iki
  ABI'de de-obfuscation'i bozar. "Optimize" etme. Yuklenen dosya yerel
  haritanin birebir ayni degildir: plugin JSON dizisinin basina iki girdi
  ekler — `"SENTRY_DEBUG_ID_MARKER"` ve eslesen binary'nin debug id'si (compact
  25 + 39 = tam 64 bayt; Sentry'nin bildirdigi boyut farkinin kaynagi budur).
  Kalan girdiler yerel dosyayla bayt bayt aynidir
- `.fvmrc` Flutter `3.41.4` icin tek manifesttir; `release-ready.yml` bunu
  `flutter-version-file` ile, Xcode Cloud post-clone script'i parse ederek
  kullanir. Local FVM/Mise de ayni manifesti okumali;
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
- Xcode Cloud Flutter build temiz clone'da `ios/ci_scripts/ci_post_clone.sh` ile hazirlanir; script `.fvmrc`'yi strict semver olarak okuyup version-scoped pinned zip'i curl+unzip ile kurar (`git clone flutter/flutter` DEGIL — Xcode Cloud'da bilinen flaky, ci-actions.md § Deployment Safety) ve her adimdan once `>>> STEP N:` marker basar
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

**Sentry symbol discovery platforma dar tutulmalidir.**
`sentry_dart_plugin 3.4.x`, `symbols_path` altindaki Flutter sembollerinin
yaninda standart `build/ios` ve Android build koklerini de arar. 2026-08-02'de
`symbols_path: build`, taze iOS `obfuscation.map.json` dosyasini
`build/release-artifacts` altindaki alti eski Android debug ID'siyle yanlis
eslestirdi. Kanonik script her upload'a
`--sentry-define=symbols_path=build/symbols/<platform>` verir; diger platformun
bilinen build koklerini ve `build/release-artifacts` klasorunu ayni filesystem
icindeki gecici karantinaya tasir, upload basarisiz olsa da EXIT trap ile geri
yukler. Bu daraltmayi kaldirma veya tekrar `symbols_path: build` kullanma.

Iki degerin eksikligi build'i KIRMAZ, sessizce bozuk bir release uretir — bu
yuzden script'te loud fail-fast'tirlar:
- `SENTRY_DSN` yoksa: crash reporting'i hic olmayan bir release
- `SENTRY_AUTH_TOKEN` yoksa: kimsenin okuyamadigi obfuscated stack trace'ler

**Pod ayarlarini DOGRULARKEN workspace kullan, `-project Pods.xcodeproj` DEGIL.**
2026-07-26'da olculdu: `xcodebuild -project ios/Pods/Pods.xcodeproj -target <pod>`
calistirmak uretilen projeyi geri yazdi ve 95 hedefin 74'unde
`ENABLE_MODULE_VERIFIER` tekrar `YES` oldu — yani teshis komutunun kendisi
fix'i etkisizlestirdi ve yedi dakika sonraki Archive yine dustu.
`xcodebuild -workspace Runner.xcworkspace -scheme Runner` ile ayni dogrulama
guvenli: once/sonra 285 `NO`, `BUILD SUCCEEDED`.

Bunu ozellikle tehlikeli yapan sey: `ios/Pods/` **gitignored**, dolayisiyla
boyle bir bozulma `git status`'ta HIC gorunmez. Tek onarim `pod install`. Pod
build ayarlarini degistirdikten sonra dogrulamayi
`grep -c 'ENABLE_MODULE_VERIFIER = NO' ios/Pods/Pods.xcodeproj/project.pbxproj`
gibi dogrudan olcumle yap ve derleme sonrasi TEKRAR olc.

**iOS Module Verifier — Podfile'da KAPALI, acma.** Xcode 26 uretilen Pods
projesinde `ENABLE_MODULE_VERIFIER`'i varsayilan olarak acar (222 config `YES`
geldi; ne Podfile ne de Flutter'in `podhelper.rb`'si set ediyor). Verifier her
pod'un umbrella header'ini TEK BASINA derler; o baglamda Flutter framework
arama yollari gecerli olmadigi icin `<Flutter/Flutter.h>` bulunamaz ve
`Flutter/Flutter.h file not found` -> `could not build module '<pod>'` ile
Archive duser.

Olculdu 2026-07-26, kontrollu deney: ayni pod hedefi
`ENABLE_MODULE_VERIFIER=YES` ile **BUILD FAILED**, Podfile fix'iyle (`NO`)
**BUILD SUCCEEDED**. Tek bir pod'a ozgu degil — `package_info_plus`,
`share_plus` ve `sqflite_darwin` ucu de ayni hatayla dustu, yani Xcode hangisine
once ulasirsa onu raporlar. Bu yuzden ayar pod hedeflerinin TAMAMINA uygulanir.
Uygulama hedefi etkilenmez; verifier yalnizca bizim kontrol etmedigimiz ucuncu
taraf header'larinin modul hijyenini dogrular, uretilen binary'yi degistirmez.

**iOS build'i TAKIPLI dosyalari degistirebilir — build sonrasi `git status` oku.**
2026-07-26'da olculdu: `flutter build ios --config-only` yerel Xcode
toolchain'iyle `ios/Runner/Runner.entitlements` ve
`ios/Runner.xcodeproj/project.pbxproj` dosyalarini yeniden yazdi. Entitlements
yeniden yazimi `com.apple.security.application-groups` degerini BOSALTTI
(`group.com.budgiebreeding.tracker` -> `<array/>`). O app group, Flutter tarafi
(`HomeWidgetService.appGroupId`) ile widget extension'in paylasilan
konteyneridir; bos haliyle commit edilirse home widget veri alamaz
(home-widget.md). pbxproj degisikligi zararsizdi ("Embed App Extensions" ->
"Embed Foundation Extensions" yeniden adlandirma).

`scripts/build_release.sh ios` de bir `flutter build` calistirdigi icin ayni
sey gercek bir release turunda olabilir. Build sonrasi `git status --short`
oku; bu iki dosyada istenmeyen yeniden yazim varsa `git checkout --` ile geri
al (git-rules.md § Working Tree Organization). Tek gozlem — mekanizmasi
dogrulanmadi, ama kontrolu ucuz ve kaybi buyuk.

**Xcode'dan dogrudan Archive ALMA.** iOS dart-define'lari gitignored, uretilen
xcconfig'lerde durur ve yalnizca bir `flutter build` onlari tazeler; Archive ne
bulursa onu okur. Guncel Flutter bunlari `Generated.xcconfig` icine base64
`DART_DEFINES` olarak yazar — eski surumlerin kullandigi
`ios/Flutter/DartDefines.xcconfig`'e YAZMAZ. `Release.xcconfig` o eski dosyayi
`Generated.xcconfig`'ten SONRA include ettigi icin arta kalan bir kopya taze
define'lari sessizce EZER. 2026-07-26'da tam boyle bir kopya bulundu: dort ay
bayat, legacy Google projesini tasiyor ve `SENTRY_DSN` HIC yok — yani script'in
onlemek icin var oldugu release'in ta kendisi. Silindi. Yeniden olusursa
guvenme, sil.

Dagitim: iOS'ta `build/ios/archive/Runner.xcarchive` -> Xcode Organizer
(Distribute App). `flutter build ipa` yerelde arsivde durur; export-options
plist ureten bir sey yok (Codemagic bunu `xcode-project use-profiles` ile
sagliyordu). Script hangi artefakt olustuysa onu bildirir.
Android'de tercih `release-ready.yml` (temiz checkout); script local dogrulama icin.

## Environment Discipline
- `--dart-define` ile gelen runtime config'i kodda fallback secret gibi kullanma
- Client Supabase config'inde `SUPABASE_PUBLISHABLE_KEY` kullan; legacy
  `SUPABASE_ANON_KEY` yalniz mevcut release ortamlarinin gecis fallback'idir
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
    (bayat, artik yazilmayan `DartDefines.xcconfig` taze define'lari ezer ->
    DSN'siz/yanlis client ID'li release,
    § Release Build)
12. Store'a publish eden bir job/pipeline geri eklemek — release-ready.yml
    ve script bilincli olarak yalniz artifact uretir; yukleme manuel

> **Ilgili**: ci-actions.md (workflow detaylari), branch-workflow.md (merge policy), ai-workflow.md (kalite kapilari)
