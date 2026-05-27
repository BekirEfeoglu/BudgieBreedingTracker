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

## Backup Format
```
backup.budgie.zip
├── manifest.json (version, created_at, app_version, encrypted: bool)
├── data.enc (AES-256-CBC + HMAC encrypted JSON)
└── attachments/ (photos, opsiyonel)
```

- Manifest plaintext (version check için)
- `data.enc`: encryption.md spec'i ile (BBTENC1! magic, IV, MAC)
- AES key: kullanıcı şifresinden PBKDF2 (100k iterasyon) — NOT runtime master key
- Backup ≠ live encryption; ayrı key, ayrı flow

## Backup Triggers
- Manuel: Settings → Backup → Export now
- Periodic (premium): `BackupScheduler` günlük/haftalık (kullanıcı seçer)
- Pre-migration: app update öncesi otomatik (safety net)
- Path: cihaz Documents/budgie-backups/ + share sheet

## Restore Flow
```
User picks .budgie.zip
  -> Parse manifest, version check
  -> Decrypt data.enc with user password
  -> Validate schema (current vs backup version)
  -> Show preview (X bird, Y egg, Z chick...)
  -> User confirms -> wipe current data OR merge
  -> Restore: Drift batch insert + Storage attachment upload
```

- Wipe & restore: full replace (destructive — type-to-confirm)
- Merge: conflict resolution (skip / overwrite / rename)
- Restore atomic değil — failure halinde partial state mümkün → progress log + resume

## Excel Export
- Tüm bird, egg, chick, breeding_pair sheet'leri
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

## Encryption (Backup-Specific)
- User password → PBKDF2-SHA256 100K iter → 32-byte key
- Salt: 16 byte random, manifest'te plaintext (decrypt için gerekli)
- IV: 16 byte random per backup
- HMAC: integrity (manifest tamper detection)
- Asla runtime encryption key kullanma — backup taşınabilir olmalı

```dart
// PBKDF2 from user password
final salt = SecureRandom(16);
final key = Pbkdf2(
  password: userPassword,
  salt: salt,
  iterations: 100000,
  keyLength: 32,
).derive();
```

## Backup Validation
- Version compatibility check (backup v2 → app v3 OK, app v3 → backup v5 reject)
- Schema migration: backup v2 (older) → app current → migrate during restore
- Backup version > app version → blocked, "Update app to restore"
- Corrupted ZIP: graceful error, no partial restore

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
| Backup photo embed | ✓ (limited) | ✓ (full) |
| Excel import/export | ✗ | ✓ |
| PDF pedigree | ✗ | ✓ |

Veri sahipliği prensibi: backup her zaman bedava — kullanıcı app'ten ayrılabilir.

## Edge Cases
- Disk full: graceful failure + free space hint
- Network kopuk (cloud backup): retry queue, file local'e yaz
- App killed mid-backup: temp file cleanup on next launch
- Restore mid-progress crash: resume capability (manifest checkpoint)

## Testing
- Unit: encryption round-trip (encrypt + decrypt eşit)
- Unit: Excel header i18n (Türkçe header → İngilizce app)
- Integration: full backup + wipe + restore (data parity)
- E2E: real device share sheet (manual QA)
- Edge: 10MB file, malformed ZIP, wrong password

```dart
test('backup-restore round trip preserves all entities', () async {
  final original = await seedDatabase();
  final backupPath = await backupService.export(password: 'test123');

  await database.wipeAll();
  await backupService.restore(backupPath, password: 'test123');

  final restored = await fetchAll();
  expect(restored, equals(original));
});
```

## Anti-Patterns
1. Runtime encryption key'i backup için kullanmak (encryption.md key rotation kırılır)
2. PBKDF2 iteration düşük (< 100K — brute force riski)
3. Salt'ı kod'a hardcode (backup farklı kullanıcılarda aynı key)
4. Restore'da wipe öncesi backup'tan yedek almamak (geri dönüşsüz)
5. Excel'e foto embed (file size 50MB+ olur)
6. UI thread'inde 1000+ row import (jank + ANR)
7. PDF'te full-res photo (memory + file size)
8. Backup version forward-compat etmemek (eski app restore fail)
9. Restore conflict resolution'ı sessiz overwrite (kullanıcı veri kaybı)
10. Backup file'ı encrypted şifre olmadan share etmek (default sıfır şifre tehlikeli)
11. Share sheet sonrası temp file cleanup atlamak (cihaz alanı dolar)

> **İlgili**: encryption.md (AES-256-CBC + HMAC + PBKDF2), data-layer.md (Drift export schema), assets-images.md (10MB limit), premium-revenuecat.md (premium gating), localization.md (Excel header i18n), migrations.md (backup schema compatibility)
