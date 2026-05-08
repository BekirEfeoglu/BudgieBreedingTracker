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
- [ ] `dart format .` uygulandı
- [ ] `flutter analyze --no-fatal-infos` hatasız geçiyor
- [ ] `python3 scripts/verify_code_quality.py` hatasız geçiyor
- [ ] Testler yazıldı / güncellendi ve ilgili `flutter test ...` komutu geçti
- [ ] Freezed/Drift/JSON/Riverpod değiştiyse `dart run build_runner build --delete-conflicting-outputs` çalıştırıldı
- [ ] Lokalizasyon değiştiyse `python3 scripts/check_l10n_sync.py` geçti
- [ ] Kural/metrik değiştiyse `python3 scripts/verify_rules.py --strict` geçti
- [ ] CI/workflow değiştiyse `.claude/rules/ci-actions.md` güncellendi
- [ ] CI coverage upload değiştiyse token olmayan ortamda job bilinçli skip/no-op davranıyor
- [ ] CI/workflow değiştiyse workflow YAML parse edildi ve push sonrası `python3 scripts/check_remote_status.py` ile exact commit doğrulandı
- [ ] Release artifact davranışı değiştiyse `release-ready.yml`, `CLAUDE.md`, `.claude/rules/release-ops.md` birlikte güncellendi
- [ ] Xcode Cloud/iOS workflow değiştiyse `ios/ci_scripts/ci_post_clone.sh` executable/retry-aware ve `.claude/rules/release-ops.md` güncel
