## Değişiklik Özeti
<!-- Bu PR ne yapıyor? Kısa açıklama -->

## Değişiklik Tipi
- [ ] Yeni özellik (feature)
- [ ] Hata düzeltme (bugfix)
- [ ] Genetik hesaplama güncellemesi
- [ ] UI/UX iyileştirme
- [ ] Veritabanı (Drift/Supabase) değişikliği
- [ ] Senkronizasyon iyileştirmesi
- [ ] Test ekleme/güncelleme
- [ ] Refactoring
- [ ] Dokümantasyon

## Platform Testi
- [ ] Android'de test edildi
- [ ] iOS'ta test edildi
- [ ] Windows'ta test edildi (gerekiyorsa)
- [ ] macOS'ta test edildi (gerekiyorsa)

## Offline/Online Testi
- [ ] Offline modda çalışıyor
- [ ] Online modda çalışıyor
- [ ] Offline → Online geçişte senkronizasyon doğru

## Veritabanı
- [ ] Migration eklendi (gerekiyorsa)
- [ ] RLS politikaları güncellendi (gerekiyorsa)
- [ ] Drift schema değişikliği var mı? Evet / Hayır

## Ekran Görüntüleri
<!-- Varsa ekleyin -->

## Kontrol Listesi
- [ ] PR hedef branch'i `main`; geçici remote branch merge sonrası silinecek
- [ ] `dart format .` uygulandı
- [ ] `flutter analyze --no-fatal-infos` hatasız geçiyor
- [ ] `python3 scripts/verify_code_quality.py` hatasız geçiyor
- [ ] Testler yazıldı / güncellendi ve ilgili `flutter test ...` komutu geçti
- [ ] Yeni/kalıcı `skip:`, `@Skip` veya tag-based test exclusion yok; varsa issue/reason/alternatif coverage yazıldı
- [ ] Edge Function değiştiyse `deno test --allow-env --allow-net supabase/functions` geçti
- [ ] Freezed/Drift/JSON/Riverpod değiştiyse `dart run build_runner build --delete-conflicting-outputs` çalıştırıldı
- [ ] Dependency bump varsa `pubspec.lock`; iOS plugin/pod etkisi varsa `ios/Podfile.lock` senkron ve `pod install` geçti
- [ ] Lokalizasyon değiştiyse `python3 scripts/check_l10n_sync.py` geçti
- [ ] Kural/metrik değiştiyse `python3 scripts/verify_rules.py --strict` geçti
- [ ] CI/workflow değiştiyse `.claude/rules/ci-actions.md` ve `.github/pull_request_template.md` güncellendi
- [ ] Edge deploy akışı değiştiyse source/config/workflow path guard'ı korunuyor; `docs/**`-only push deploy etmiyor
- [ ] CI coverage upload değiştiyse token olmayan ortamda job bilinçli skip/no-op davranıyor
- [ ] CI/workflow değiştiyse workflow YAML parse edildi ve push sonrası `python3 scripts/check_remote_status.py` ile exact commit doğrulandı
- [ ] Release artifact davranışı değiştiyse `release-ready.yml`, `CLAUDE.md`, `.claude/rules/release-ops.md` birlikte güncellendi
- [ ] Release secret sözleşmesi değiştiyse GitHub Actions secret'ları ve `.env` senkron, eksik-secret fail-fast kontrolü test edildi
- [ ] `scripts/build_release.sh` değiştiyse DSN/token fail-fast, `--obfuscate`/`--split-debug-info` ve `sentry_dart_plugin` symbol upload sözleşmesi `scripts/test_ci_workflow_contract.py` + `scripts/verify_security.py` ile doğrulandı
- [ ] `release-ready.yml` değiştiyse `publishing`/Google Play credential içermediği ve `pubspec.yaml` build numarasını kullandığı korunuyor (store'a publish eden job EKLENMEDİ)
- [ ] Android sürümlemesi değiştiyse `pubspec.yaml` build numarasının package-wide Play maksimumunu aştığı elle doğrulandı (otomatik çözüm yok)
- [ ] Flutter SDK ayarı değiştiyse `release-ready.yml`, GitHub Actions ve Xcode Cloud aynı doğrulanmış sürüme pinli; `stable` kanal drift'i yok
- [ ] Xcode Cloud/iOS workflow değiştiyse `ios/ci_scripts/ci_post_clone.sh` executable/retry-aware, Pods filelist fail-fast doğrulaması korunuyor ve `.claude/rules/release-ops.md` güncel
