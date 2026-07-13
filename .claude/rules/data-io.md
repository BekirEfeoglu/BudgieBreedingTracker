# Data Import / Export / Backup

Tam veri yedekleme (JSON+AES), Excel import/export, PDF (pedigree) export. `lib/domain/services/backup/`, `export/`, `import/`. Premium özelliği ama backup ücretsiz (data ownership).

## Stack
| İşlev | Servis | Format |
|-------|--------|--------|
| Backup | `BackupService` | `.budgie.zip` (JSON + AES + manifest) |
| Excel export | `ExcelExportService` | `.xlsx` (`excel` package) |
| Excel import | `DataImportService` | `.xlsx` |
| PDF export | `PdfExportService`, `PedigreePdfBuilder` | `.pdf` (`pdf` package) |
| Scheduler | `BackupScheduler` | Periodic auto-backup |

## Backup Format (gerçek — tek JSON dosyası, zip/manifest YOK)
```
budgie_backup_<iso-timestamp>.json       (düz)
budgie_backup_<iso-timestamp>.enc.json   (şifreli — uzantıdan auto-detect)
```

- İçerik: `{version, user_id, created_at, data: {...}}` — version alanı JSON'a gömülü (ayrı manifest yok)
- Şifreleme OPSİYONEL ve **runtime `EncryptionService`** ile yapılır (AES-256-CBC + HMAC, encryption.md spec'i — BBTENC1! magic, IV, MAC); kullanıcı şifresi / PBKDF2 YOK (cihaz-yerel anahtar)
- Sonuç: şifreli backup **taşınabilir değildir** — başka cihazda runtime anahtar olmadığından decrypt edilemez. Kullanıcı-şifreli taşınabilir backup (PBKDF2) bir tasarım hedefidir, shipped değildir (known-gaps.md)
- Attachment/foto backup'a GÖMÜLMEZ
- Cloud upload/list: `BackupService.uploadBackup` → Supabase Storage `backups` bucket'ı

## Backup Triggers
- Manuel: Settings → Backup → Export now
- Periodic (premium): `BackupScheduler` günlük/haftalık/aylık (kullanıcı seçer) — **shipped 2026-07-09**: UI backup_screen'de (`_AutoBackupSection`), tetikleme `app.dart _onAppResumed`'da `runIfScheduled` ile (6h throttle + interval gate); runtime `EncryptionService` ile şifreli (kullanıcı şifresi istemez, cihaz-yerel). Provider'lar `backup_schedule_providers.dart` (settings.md § Backup Screen)
- Pre-migration: app update öncesi otomatik (safety net)
- Path: `getTemporaryDirectory()` (temp dir) + share sheet — kalıcı Documents klasörü YOK, paylaşım sonrası temp cleanup

## Restore Flow (gerçek — merge-upsert, wipe/preview YOK)
```
User picks .json / .enc.json
  -> Uzantıdan encrypted auto-detect
  -> EncryptionService.decrypt (runtime anahtar; FormatException = yanlış anahtar/tamper
     -> backup.error_decrypt_failed, Sentry'ye GİTMEZ — beklenen kullanıcı koşulu)
  -> Gömülü version kontrolü (backup version > app backupVersion -> reject
     'backup.error_unsupported_version')
  -> user_id sahiplik kontrolü (başka kullanıcının backup'ı reddedilir)
  -> Merge: entity başına saveAll upsert (id bazlı — mevcut kayıtlar güncellenir)
```

- Wipe & restore / restore preview / skip-overwrite-rename seçimi YOK — tek strateji merge-upsert (tasarım hedefi olarak preview known-gaps.md'de)
- Restore atomic değil — failure halinde partial state mümkün → progress log

## Excel Export
- Altı sheet: bird, breeding_pair, **incubation**, egg, chick, **health_record** — `importAllFromExcel`'in okuduğu tüm entity'lerle simetrik (round-trip). Incubation id'si TAM yazılır (kırpılmaz) ki egg'in `incubationId` FK'si re-import'ta çözülsün; health kaydı da id-korumalı trailing kolonla yazılır
- Enum alanları (gender/species/status/type) locale-bağımsız enum `.name` token'ı olarak yazılır — parser bunları locale'den bağımsız çözer
- Header: l10n key tabanlı (kullanıcı dilinde)
- Sayı format: locale-aware
- Tarih: ISO-8601 string (Excel parse hatasını engelle)
- Foto: HİÇ (URL yazılır, image embed performans sorunu)

```dart
final excel = Excel.createExcel();
final birdSheet = excel['birds.sheet_name'.tr()];
birdSheet.appendRow([
  'birds.name'.tr().textCellValue(),
  'birds.gender'.tr().textCellValue(),
]);
```

## Excel Import
- Schema validation: header isimleri tr/en/de kabul (i18n input)
- Row başına validation: required field, enum value, date format
- Hata satırı: skip + report (kullanıcıya "5/100 row failed" özet)
- Persist BATCH: geçerli satırlar tek `repo.saveAll` ile yazılır (satır başına HTTP push YOK); FK doğrulaması tek `getAll` haritasından yapılır (satır başına `getById` yok, aynı dosyadaki önce-gelen ebeveyn satırları haritaya eklenir)
- Sheet import SIRASI FK'ye duyarlı: `importAllFromExcel` birds → breeding_pairs → **incubations → eggs** → chicks → health_records sırasında koşar (egg'in `incubationId`'si önce import edilen incubation'a çözülsün)
- Sheet başına all-or-nothing: `saveAll` tek Drift transaction'dır — ortada patlarsa kısmi import KALMAZ; `ImportResult` `importedCount: 0` + sheet-level hata döner
- Duplicate check: ring_number unique → conflict resolution
- Max file size: 10MB (assets-images.md limit consistency)
- Background isolate: 1000+ row parse UI bloklar

## PDF Export — Pedigree
- Family tree (3-5 jenerasyon) visual chart
- `PedigreePdfBuilder` + `PedigreePdfChartBuilder` ile çizim
- Page builders: `pdf_export_page_builders.dart`
- Constants: `pedigree_pdf_constants.dart` (margin, font size, color)
- Foto embed: low-res (300px) — file size budget
- Multi-page: pedigree büyükse split + cross-reference

## Performance Budget
| İşlem | Budget |
|-------|--------|
| Backup 100 bird (no photo) | < 5s |
| Backup 100 bird + photo | < 30s (network/storage) |
| Excel export 1000 row | < 3s |
| Excel import 1000 row | < 10s |
| PDF pedigree 5 gen | < 4s |
| Restore 100 bird | < 10s |

İşlemler heavy isolate'te (`compute()`), progress callback ile UI update.

## Encryption (Backup-Specific — gerçek: runtime EncryptionService)
- Şifreleme runtime `EncryptionService` cihaz anahtarıyla yapılır (encryption.md payload spec'i); decrypt hatası `FormatException` → `backup.error_decrypt_failed` (Sentry'ye gitmez)
- **Trade-off (bilinçli):** cihaz-yerel anahtar → şifreli backup başka cihaza taşınamaz; key rotation eski şifreli backup'ları arşiv anahtarıyla açar (encryption.md § Key Rotation)
- **Kullanıcı-şifreli taşınabilir backup (PBKDF2-SHA256 100K iter + random salt/IV) shipped DEĞİLDİR** — tasarım hedefi, known-gaps.md'de kayıtlı. Eklenirse: PBKDF2 anahtar türetimi + salt'ın dosyada plaintext taşınması + bu bölümün gerçek mekanikle güncellenmesi gerekir

## Backup Validation
- Version compatibility check: gömülü `version` int (`BackupDataCollector.backupVersion`); backup version > app version → reject `backup.error_unsupported_version`
- `user_id` sahiplik kontrolü — başka kullanıcının backup'ı reddedilir
- Bozuk dosya/JSON: graceful error (`backup.error_invalid_format`), no partial restore

## Share Sheet Integration
- iOS: `share_plus` ile native share sheet
- Android: same paket
- File path: temp dir (1 saat sonra OS cleanup veya manuel)
- iCloud/Drive entegrasyonu: share sheet bunu sağlar (in-app feature DEĞİL)

## Free vs Premium
| Özellik | Free | Premium |
|---------|------|---------|
| Manual backup | ✓ | ✓ |
| Restore | ✓ | ✓ |
| Auto-scheduled backup | ✗ | ✓ |
| Backup photo embed | ✗ (foto backup'a gömülmez — URL/path verisi JSON içinde) | ✗ |
| Excel import/export | ✗ | ✓ |
| PDF pedigree | ✗ | ✓ |

Veri sahipliği prensibi: backup her zaman bedava — kullanıcı app'ten ayrılabilir.

## Edge Cases
- Disk full: graceful failure + free space hint
- Network kopuk (cloud backup): retry queue, file local'e yaz
- App killed mid-backup: temp file cleanup on next launch
- Restore mid-progress crash: partial state mümkün — restore idempotent (upsert), yeniden çalıştırmak güvenli

## Testing
- Unit: encryption round-trip (encrypt + decrypt eşit)
- Unit: Excel header i18n (Türkçe header → İngilizce app)
- Integration: full backup + restore round-trip (data parity, merge-upsert)
- E2E: real device share sheet (manual QA)
- Edge: 10MB file, malformed JSON, yanlış cihaz anahtarı (`FormatException` → `backup.error_decrypt_failed`)

```dart
test('backup-restore round trip preserves all entities', () async {
  final original = await seedDatabase();
  final result = await backupService.createBackup(userId, encrypt: true);

  await backupService.restoreBackup(userId, result.filePath!);

  final restored = await fetchAll();
  expect(restored, equals(original)); // merge-upsert: id bazlı eşitlik
});
```

## Anti-Patterns
1. Şifreli backup'ı taşınabilir sanmak (runtime cihaz anahtarı — başka cihazda açılmaz; taşınabilirlik istiyorsan düz `.json` + kullanıcı bilgilendirmesi)
2. PBKDF2/kullanıcı-şifresi akışını shipped varsaymak (known-gaps.md — tasarım hedefi)
3. Restore'un merge-upsert olduğunu unutup "wipe eder" varsaymak (wipe/preview yok)
4. Restore öncesi mevcut veriden yedek almamak (merge yine de veri değiştirir)
5. Excel'e foto embed (file size 50MB+ olur)
6. UI thread'inde 1000+ row import (jank + ANR)
7. PDF'te full-res photo (memory + file size)
8. Backup version forward-compat etmemek (eski app restore fail)
9. Restore'un id-bazlı upsert davranışını değiştirirken kullanıcıya bilgi vermemek (sessiz veri değişimi)
10. Düz `.json` backup'ı hassas veri içerdiğini söylemeden share etmek (şifreleme opsiyonel — kullanıcı bilgilendirmesi zorunlu)
11. Share sheet sonrası temp file cleanup atlamak (cihaz alanı dolar)

> **İlgili**: encryption.md (AES-256-CBC + HMAC, runtime anahtar), data-layer.md (Drift export schema), assets-images.md (10MB limit), premium-revenuecat.md (premium gating), localization.md (Excel header i18n), migrations.md (backup schema compatibility), obsidian-brain/known-gaps.md (PBKDF2 taşınabilir backup — unshipped)
