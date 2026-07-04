# Health Records (Sağlık Kayıtları)

Kuş sağlık olayları: kontrol, hastalık, aşı, ilaç, ölüm kaydı + takip hatırlatmaları. `lib/features/health_records/` + offline-first `HealthRecordRepository`. Sağlık verisi hassastır — içerik asla log/Sentry'ye gitmez.

## Stack
| Bileşen | Yer |
|---------|-----|
| Model | `HealthRecord` (`lib/data/models/health_record_model.dart`) |
| Repository | `HealthRecordRepository` (offline-first + `ValidatedSyncMixin`) |
| Form | `HealthRecordFormNotifier` (`health_record_form_providers.dart`) |
| Reminder | `NotificationScheduler.scheduleHealthCheckReminder` |
| Filter | `HealthRecordFilterBar` → `filteredHealthRecordsProvider` |

## Entity Şekli
- Alanlar: `id, date, type, title, userId, birdId?, description?, treatment?, veterinarian?, notes?, weight?, cost?, followUpDate?, isDeleted`
- `HealthRecordType` enum: `checkup, illness, injury, vaccination, medication, death, unknown` — server-side enum, `unknown` case zorunlu (anti-pattern #15/#16)
- FK parent: `birdId` **nullable**, Supabase'de `ON DELETE SET NULL` — kayıt kuşsuz yaşayabilir
- **Bilinen sınırlama:** `health_record_animal_selector` dropdown'ı chick de listeler ama model yalnız `birdId` taşır — chick seçimi kayıtta TUTULMAZ. Chick FK eklemek şema + migration + mixin işi, sessizce "düzeltme"
- Ağırlık takibi ayrı: `GrowthMeasurementRepository` chick büyüme ölçümüdür, HealthRecord.weight tek-nokta kayıttır — karıştırma

## Sync Doğrulaması (ValidatedSyncMixin)
`validateForeignKeys` push öncesi üç kontrol yapar (`health_record_repository.dart`):
1. `birdId != null` ise kuş local'de var ve soft-delete değil
2. Kuş pending-delete tombstone değil
3. Kuş remote'a zaten sync'lenmiş (pending değil) — parent'tan önce child push edilmez

Orphan push engeli background-sync.md § ValidatedSyncMixin sözleşmesinin parçası; mixin'i bu repodan KALDIRMA.

## Follow-Up Hatırlatmaları
- `followUpDate` set + `birdId != null` → `scheduleHealthCheckReminder(recordId, birdId, hour: 9, durationDays)`
- Süre: `date_utils.DateUtils.dayDiff(now, followUpDate).clamp(1, 30)` — max 30 gün, dayDiff prefix'li import (datetime-format.md)
- `followUpDate` yoksa create'ten itibaren 7 gün varsayılan pencere
- Update'te `birdId`/`followUpDate` değişimi algılanır → eski ID'ler cancel + yeniden schedule (calendar.md cancel+reschedule pattern'i)
- Delete → `cancelHealthCheckReminders()` (zombie notification engeli)
- Kullanıcının bildirim toggle'ı honored (`notificationToggleSettingsProvider`)

## Kapsam Dışı (shipped değil — varsayma)
- Fotoğraf eki YOK: modelde alan yok, özel bucket yok (assets-images.md'deki `bird-photos` kuş profil fotoğrafları içindir)
- Takvimde otomatik event üretimi YOK: calendar.md'deki `health_check` tipi KULLANICI-manuel event'tir, health record insert'i event üretmez
- Free-tier limiti YOK: `validate-free-tier-limit` health record saymaz

## Filter & Liste
- Filtre: `all` + tip bazlı chip'ler (`FadeScrollableChipBar`), `filteredHealthRecordsProvider` tek geçiş
- Boş liste: `health_records.no_records` + ekleme CTA; filter-empty ayrı mesaj (empty-loading-error-states.md)

## Privacy
- Veteriner adı, teşhis, tedavi metni PII/hassas — Sentry'ye ve log'a İÇERİK yazma, sadece `id` (observability.md)
- local-ai.md kuralı geçerli: sağlık kaydı ham metni AI prompt'una anonimizasyonsuz GİRMEZ

## Testing
- 8 feature test dosyası (`test/features/health_records/`) + repository/model testleri + `test/e2e/health_records_flow_test.dart`
- Kritik senaryolar: reminder schedule/cancel/reschedule, mixin FK doğrulaması, `unknown` enum fallback, filter mantığı

## Anti-Patterns
1. `ValidatedSyncMixin`'i atlayıp health record push etmek (orphan risk)
2. Chick seçimini kaydediyormuş gibi UI sunmak (bilinen sınırlama — şema işi olmadan çözülmez)
3. Reminder'ı `DateTime.now()` ile schedule etmek (`tz.TZDateTime`, notifications.md)
4. Delete'te reminder cancel atlamak (zombie notification)
5. Health içeriğini Sentry/log'a yazmak (PII)
6. `followUpDate` gün hesabını `.difference().inDays` ile yapmak (`dayDiff` zorunlu, DST)
7. HealthRecord.weight'i growth measurement yerine kullanmak (ayrı sistemler)
8. Takvim event'i üretmeye başlayıp calendar.md sözleşmesini güncellememek

> **İlgili**: background-sync.md (ValidatedSyncMixin), notifications.md (scheduler, tz), datetime-format.md (dayDiff), breeding-eggs.md (chick zinciri), observability.md (PII), calendar.md (manuel health_check event)
