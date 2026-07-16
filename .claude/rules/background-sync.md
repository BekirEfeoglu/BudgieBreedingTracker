# Background Sync

Offline-first mimari: kullanıcı her zaman local Drift DB'ye yazar, sync service arka planda Supabase ile uzlaştırır. Network kaybı veri kaybı DEĞİL.

## Akış
```
Local write (Drift) -> per-record SyncMetadata pending row
  -> networkStatusProvider online algılar
  -> SyncOrchestrator (syncOrchestratorProvider) push/pull başlatır
  -> SyncableRepository.pushPendingBatched() -> upsert (idempotent)
  -> Başarılı push SyncMetadata satırını siler
  -> Conflict varsa lastPullConflicts -> conflict_history'ye yaz, UI'da göster
```

## Sync Triggers
| Trigger | Hedef |
|---------|-------|
| Auth init | `fullSync()` = push → incremental/reconcile pull; error'da 3sn sonra tek retry |
| Connectivity online geldi | Auto-sync/Wi-Fi guard sonrası `forceFullSync()` |
| App resume (foreground) | Aktif sync yoksa lightweight `pushChanges()` |
| Home/manual refresh | `forceFullSync()` + derived provider refresh |
| Realtime allowlist event | Son 5 dakikayı kapsayan incremental `pullChanges()` |
| Periodic (15dk timer) | Retry-ready error kayıtları, sonra `fullSync()` |

## SyncMetadata Tablosu
Bekleyen KAYIT başına bir satır — entity-tipi başına değil. `UNIQUE(table_name, record_id)` kısıtı var; başarılı push satırı SİLER (gerçek model: `lib/data/models/sync_metadata_model.dart`):
```dart
@freezed SyncMetadata:
  String id;                // client UUID (PK)
  String table;             // JSON 'table_name' — 'birds', 'eggs', ...
  String userId;
  SyncStatus status;        // pending | pendingDelete | error
                            // (synced fiilen kullanılmaz — başarı satırı siler;
                            //  pendingDelete: hard-delete repoları — incubation,
                            //  notification, growth_measurement)
  String? recordId;         // hangi kayıt
  String? errorMessage;     // son hata
  int? retryCount;          // backoff denemesi
  DateTime? lastSyncedAt; DateTime? createdAt; DateTime? updatedAt;
```

## Retry & Backoff
- Transient hata (network): `RetryScheduler` exponential backoff kullanır
  (`45s * 2^retryCount` + %20 jitter, max 10dk)
- Permanent hata (auth, validation): retry yok, error log + Sentry
- Max attempt 7 — sonrasında error state kalır, kullanıcıya global
  `OfflineBanner` içinde retry CTA gösterilir

```dart
final canRetry = RetryScheduler.shouldRetry(metadata.retryCount ?? 0);
final nextDelay = RetryScheduler.getNextRetryDelay(metadata.retryCount ?? 0);
```

Stale cleanup 24 saatlik davranışını korur. UI pre-warning 20 saat üstü
ve `retryCount >= RetryScheduler.maxRetries` kayıtlar için
`pendingDeletionSyncErrorsProvider` üzerinden gösterilir.

## Idempotency
- Tüm remote write `.upsert()` (NEVER `.insert()`)
- Primary key client-generated `const Uuid().v7()` — server-assigned değil
- Retry replay duplicate oluşturmaz
- Detay: data-layer.md § Write Safety

## ValidatedSyncMixin
FK parent'lı entity'ler push öncesi `validateForeignKeys()` çağırır. Local entity
zaten yoksa yalnız orphan sync metadata temizlenir. FK parent gerçekten yoksa
child sync-error olarak işaretlenip atlanır; parent pending/tombstone ise child
sonraki round'a ertelenir. Validation hatası child local satırını sessizce silmez.

**Zorunlu kullanım:**
- `egg_repository.dart`
- `chick_repository.dart`
- `health_record_repository.dart`
- `breeding_pair_repository.dart`
- `clutch_repository.dart`
- `incubation_repository.dart`
- `event_repository.dart`
- `event_reminder_repository.dart`
- `growth_measurement_repository.dart`

Bird repository root entity, mixin'e gerek yok.

```dart
class EggRepository extends BaseRepository<Egg>
    with ValidatedSyncMixin<Egg> {
  @override
  Future<String?> validateForeignKeys(Egg egg) async {
    if (egg.incubationId != null) {
      final incubation = await _incubationsDao.getById(egg.incubationId!);
      if (incubation == null) return 'orphaned egg: incubation missing';
    }
    return null; // null = geçerli, push devam eder
  }
}
```

## Conflict Resolution
- Pull'da server-wins uygulanır
- Conflict tespiti: incoming remote batch locally-PENDING bir satırın üstüne
  yazıyorsa conflict'tir; remote newer/equal/older olması sonucu değiştirmez
- Shared `detectPullConflicts` sonucu `lastPullConflicts` -> `conflict_history`
  (30 gün) kaydına eklenir
- `detectPullConflicts` hem local hem server model JSON snapshot'ını yakalar.
  `SyncConflictStore`, her snapshot'ı `SyncConflictPayloadCodec` ile mevcut
  cihaz anahtarından authenticated-encrypt eder ve server-wins Drift upsert'inden
  **önce** await ederek `conflict_history`'ye yazar. Codec zarfı v1'dir; kimlik
  (`table_name`/`record_id`/`user_id`) doğrular ve snapshot başına 64 KiB sınırı
  uygular. Şifreleme/boyut/DB hatasında pull overwrite'a devam etmez.
- Aynı `(user, table, record)` için recoverable unresolved snapshot zaten varsa
  tekrar pull yeni history eklemez; en eski local snapshot korunur. In-memory
  notifier da aynı unresolved anahtarı deduplicate eder. Resolved eski kayıt,
  sonraki gerçek conflict'i engellemez.
- v29 `conflict_history.local_payload`, `server_payload`, `payload_version`
  nullable kolonlarını ekler. Eski satırlar bilinçli olarak NULL kalır; geçmişte
  kaybedilen alanlar uydurma backfill ile yeniden üretilemez.
- `SyncConflictRecoveryService.retryLocal()` local payload'ı decrypt + kimlik +
  typed model parse ile doğrular; entity'yi typed DAO ile upsert eder,
  `syncMetadataDao.markPendingByRecords` ile metadata'yı tam bir pending satıra
  collapse/reset eder ve conflict `resolved_at` işaretini aynı Drift
  transaction'ında tamamlar. Duplicate/racing retry çağrıları tek active
  future'da birleşir.
- Retry UI, `fullSync()` sonucu success olsa bile restore edilen anahtarları
  tablo bazında `SyncMetadataDao.getByRecords` ile batch doğrular. Tüm metadata
  işaretleri silinmeden "senkronize edildi" göstermez veya sheet'i kapatmaz;
  conflict provider'ı full sync sonrasında yeniden yükler.
- Eski payload'sız veya bozuk/unsupported payload kayıtları local satırı ya da
  resolution durumunu değiştirmez; UI lokalize unavailable/failed/partial uyarısı
  gösterir. Payload içeriği log/Sentry/telemetry'ye gönderilmez; yalnız tablo,
  obfuscated record ID, sonuç kodu ve aggregate sayılar kullanılabilir.
- UI `conflictHistoryProvider` / `persistedConflictCountProvider`
  (`sync_conflict_providers.dart`) üzerinden history/resolution durumunu gösterir;
  resolved conflict recent-count banner'ına dahil edilmez.
- Sessiz overwrite YOK — her conflict kullanıcıya bildirilir

```dart
final conflicts = detectPullConflicts(
  remote: remote,
  localMap: localMap,
  pendingIds: pendingIds,
  idOf: (item) => item.id,
  detailOf: (item) => item.name,
  payloadOf: (item) => item.toJson(),
);
await persistPullConflicts(
  sink: _conflictSink,
  userId: userId,
  tableName: syncTableName,
  conflicts: conflicts,
);
await dao.insertAll(remote); // server-wins
// SyncPullHandler persisted conflict'i in-memory provider'a yansıtır.
```

## Connectivity-Aware
- `networkStatusProvider` (`network_status_provider.dart`) `connectivity_plus` üzerine wrap
- Online geldiğinde otomatik sync kick
- Offline modda global `OfflineBanner` gösterilir; banner
  `syncStatusProvider`, `pendingSyncCountProvider`,
  `pendingDeletionSyncErrorsProvider` ve retry için
  `syncOrchestratorProvider.forceFullSync()` kullanır
- Foreground scheduler ana güvence; opsiyonel OS background sync best-effort ve
  iOS'ta sınırlıdır

```dart
child: AppUpdatePrompt(
  child: OfflineBanner(child: routedChild),
)
```

## Batch & Batched Push
- `save()` → local yazma + `markPending` + **best-effort** `tryImmediatePush`. Debounce YOK — push başarısız olursa satır pending kalır, sonraki batched push toplar (offline-safe)
- `pushAll` → `SyncableRepository.pushPendingBatched` (`base_repository.dart`): bekleyenler 100'lük chunk'larla gider — chunk başına tek `upsertAll` + tek `SyncMetadataDao.deleteByRecords`. Chunk `AppException` fırlatırsa per-item `push()` fallback (poison-row izolasyonu; hata başına `markError`). 13 syncable reponun tamamı bu yoldan geçer (mixin hook'ları `upsertChunkForSync`/`deleteRemoteForSync` veya inline)
- Batch metadata yardımcıları: `SyncMetadataDao.getByRecords` / `deleteByRecords` / `markPendingByRecords` — pending işaretleme tek statement
- Cascade delete'ler de batch: `EventRepository.removeBy*` → tek `softDeleteByIds` + tek `markPendingByRecords` + tek best-effort `pushAll`; `GrowthMeasurementRepository.removeByChickIds` → tek `hardDeleteByIds` + batch `pendingDelete` tombstone + tek `deleteByIds` (remote hata → tombstone'lar sonraki sync'e kalır)
- `PushStats.pushed` yalnız GERÇEK başarıyı sayar; telemetri amaçlıdır (log satırları) — kontrol akışında KULLANMA
- Drift `batch()` ile toplu local write — tek transaction

## Sync UI Indicators
| Durum | Gösterim |
|-------|----------|
| Idle | Görünür değil |
| Syncing | Header'da spinner + "Senkronize ediliyor" |
| Conflict | Banner + "Çakışmaları gör" CTA |
| Failed (after retries) | Error banner + retry button |
| Offline | "Çevrimdışı — değişiklikleriniz kaydedildi" |
| Stale pre-warning | 20h+ failed records için cleanup öncesi retry banner |

## Background Sync (iOS / Android)
- iOS: `BGTaskScheduler` short tasks (30 saniye) — sınırlı, opportunistic
- Android: WorkManager periodic (15dk min interval)
- Foreground sync güvenilir, background sadece "best effort"
- Kritik veri için kullanıcı app'i açtığında sync güvence
- Background task telemetry zorunlu: `background_sync_skipped` ve
  `background_sync_run` olayları `durationMs`, `taskBudgetSeconds=30`,
  `success`/skip reason alanlarını içerir. iOS güvenilirliği bu metriklerden
  foreground sync ile karşılaştırılır; background sync hiçbir zaman tek
  güvence mekanizması sayılmaz.

## Testing
```dart
test('retries network failure with backoff', () async {
  var attempts = 0;
  when(() => mockRemote.upsert(any())).thenAnswer((_) async {
    attempts++;
    if (attempts < 3) throw NetworkException('flaky');
    return;
  });

  await birdRepository.pushPendingBatched();
  expect(attempts, 3);
});

test('marks conflict on any incoming overwrite of a pending local edit', () async {
  // ... fixture: pending local bird + incoming remote row;
  // remote timestamp order conflict kaydını bastırmamalı
  await syncOrchestrator.pullChanges();
  final conflicts = container.read(conflictHistoryProvider);
  expect(conflicts.map((c) => c.tableName), contains('birds'));
});
```

## Anti-Patterns
1. `.insert()` kullanmak (anti-pattern: idempotency kaybı)
2. ValidatedSyncMixin olmadan FK parent'lı entity push (orphan)
3. Sessiz conflict overwrite (kullanıcı veri kaybını fark etmez)
4. Retry'da auth hatasını sonsuza dek denemek (5xx vs 4xx ayırt et)
5. Background sync'e kritik veri güvenmek (iOS engelleyebilir)
6. Sync state'i UI'a göstermemek (kullanıcı belirsizlikte)
7. Periodic sync timer'ı offline'da çalıştırmak (battery drain)
8. Conflict kaydını local/server timestamp sırasına bağlamak (clock skew sessiz overwrite üretir; pending overwrite her zaman kaydedilir)

> **İlgili**: data-layer.md (Drift + Supabase), error-handling.md (NetworkException, retry), observability.md (sync logging), performance.md (batch)
