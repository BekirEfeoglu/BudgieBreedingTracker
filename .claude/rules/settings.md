# Settings

Ayarlar hub'ı: tema, dil, bildirim, sync, gizlilik/güvenlik, yedekleme ve yasal dokümanlar. `lib/features/settings/`. Bu ekran bir **yönlendirme yüzeyidir** — her toggle'ın davranış sözleşmesi kendi kural dosyasındadır; bir ayarı değiştirirken SAHİBİ olan rule'a bak (Settings'te görünen kopya davranışı tek başına düzeltme — 2026-07-02 audit'inin "sibling path" dersi).

## Bölüm Haritası (settings_screen.dart)
| Bölüm | İçerik | Sözleşme sahibi |
|-------|--------|-----------------|
| Display | Theme (light/dark/system), compact view | bu dosya |
| Language & Region | Locale (tr/en/de), tarih formatı | localization.md, datetime-format.md |
| Accessibility | Font boyutu (`fontScaleProvider`), animasyon azaltma, haptic feedback (`AccessibilitySection`) | accessibility.md |
| Notifications | Master toggle + detay ekranı linki | notifications.md |
| Data Storage | Auto/WiFi-only/background/realtime sync toggle'ları, manuel sync, sync health, conflict history, cache clear | background-sync.md, feature-flags.md § Sync Runtime Flags |
| Privacy & Security | Leaderboard görünürlüğü, şifre değiştirme, 2FA, oturumlar, GDPR export, yasal linkler, hesap silme | security.md, profile.md, gamification.md |
| About | Versiyon, build, linkler | — |

## Persistence Pattern
- Tema: `themeModeProvider` → `AppPreferences.keyThemeMode` (`PrefNotifier` tabanlı; legacy int key'den migration var). Default `ThemeMode.system`
- Dil: `appLocaleProvider` (`AppLocale`: turkish/english/german) → `AppPreferences.keyLanguage` (ISO kodu) + `context.setLocale()` ile easy_localization senkronu — İKİSİ birlikte, sadece pref yazma
- Bildirim master: `keyNotificationsEnabled`, default `true`
- Tüm toggle'lar `AppPreferences` wrapper üzerinden — raw `SharedPreferences` çağrısı EKLEME (data-layer.md § Cache)

## Privacy & Security Bölümü
- `showInLeaderboard` toggle'ı `profileRepository` üzerinden yazar (profil alanı — gamification.md leaderboard opt-out)
- **Okundu bilgisi (read receipts) toggle'ı** `readReceiptsEnabledProvider` (AppPreferences, local) — resiprokal messaging gizlilik ayarı (messaging.md § Read Receipts sahibi; sözleşmeyi orada düzelt, burada sadece kopya)
- Şifre değiştirme sheet'i MFA challenge destekler — hesap silme akışındaki AAL2 pattern'inin kardeşi (profile.md); birini değiştirirken diğerini kontrol et
- Aktif oturumlar: per-session listeleme YOK — açıklama dialog'u + "tüm oturumları kapat" aksiyonu (bilinen sınırlama, over-promise etme)
- GDPR kişisel veri export'u (Excel) **free** — premium export gate'inden ayrı yol (veri sahipliği prensibi, data-io.md)

## Backup Screen & Export
- `BackupScreen`: PDF tam rapor / Excel tam veri / hızlı kuş PDF'i + Excel import — `exportActionsProvider` (`ExportActions`)
- Gate: `effectivePremiumProvider` VEYA `isExportRewardActiveProvider` (ads.md rewarded export)
- In-flight guard: `exportLoadingProvider` — eşzamanlı export/import bloklanır
- Paylaşım `SharePlus`; temp dosya paylaşımdan sonra silinir (data-io.md § Share Sheet)
- `lastExportDateProvider` in-session — persist edilmez
- **Otomatik yedekleme — shipped (2026-07-09):** backup_screen'de premium-gated frekans seçici (`_AutoBackupSection`, Günlük/Haftalık/Aylık/Kapalı) + son otomatik yedekleme zamanı. Frekans `BackupScheduler` (SharedPreferences) ile persist edilir; yedekleme `app.dart _onAppResumed`'da `backupSchedulerProvider.runIfScheduled` ile due olunca çalışır (6h throttle + interval gate). `backupServiceProvider`/`backupSchedulerProvider`/`backupScheduleControllerProvider` `backup_schedule_providers.dart`'ta. Free kullanıcı upsell tile görür. Runtime `EncryptionService` ile şifreli, cihaz-yerel (kullanıcı şifresi istemez — data-io.md § Backup Triggers)

## Legal Documents
- `LegalDocumentScreen` + `LegalDocumentType` (`privacyPolicy, termsOfService, communityGuidelines`)
- İçerik **l10n çevirilerinden** (`legal.*` anahtarları) — remote fetch YOK; yasal metin değişikliği 3 dilde çeviri güncellemesidir (localization.md workflow)
- Community guidelines özel kart layout'u ile ayrı görünüm

## Debug / Dev Menu
- Shipped settings'te gizli geliştirici menüsü YOK — feature-flags.md § Experimental Features ile tutarlı; eklenirse `kDebugMode` guard + iki dosyanın güncellenmesi zorunlu

## Testing
- `test/helpers/test_settings_notifiers.dart` (toggle override helper'ları), sync toggle'ları `test/domain/services/sync/sync_settings_providers_test.dart`
- Ekran bazlı `settings_screen_test` YOK — ayar davranışları sahip feature'ların testlerinde; yeni toggle eklerken testi SAHİBİ alana yaz

## Anti-Patterns
1. Toggle davranışını sadece Settings kopyasında düzeltmek (sahip rule + tüm sibling path'ler — audit dersi)
2. Raw `SharedPreferences` çağrısı (her şey `AppPreferences` üzerinden)
3. Dil değişiminde `context.setLocale()` veya pref yazımından birini atlamak (yarım senkron)
4. Settings toggle'ını güvenlik sınırı sanmak (feature-flags.md — RLS/server değişmez)
5. Yasal dokümanı hardcode/remote'a taşıyıp l10n workflow'unu kırmak
6. GDPR export'unu premium gate arkasına almak (free kalmalı — veri sahipliği)
7. Yeni bölüm ekleyip bölüm haritasını ve sahip rule'u güncellememek

> **İlgili**: profile.md (güvenlik + hesap silme), background-sync.md (sync toggle'ları), feature-flags.md (runtime flags), data-io.md (export/backup), notifications.md (bildirim ayarları), gamification.md (leaderboard opt-out), localization.md (legal l10n)
