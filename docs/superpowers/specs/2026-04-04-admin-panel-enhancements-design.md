# Admin Panel Enhancements — Design Spec

**Date**: 2026-04-04
**Approach**: Hybrid — extend existing screens, extract widgets as needed
**Scope**: Dashboard analytics, DB maintenance tools, user detail improvements, quick actions

---

## 1. Analytics Dashboard (Dashboard ekranına yeni section'lar)

### 1.1 Kullanıcı Büyüme Grafiği
- `_UserGrowthChart` widget — Son 30 gün yeni kayıt trendi
- fl_chart `LineChart` kullanır
- Veri kaynağı: `profiles` tablosundan `created_at` ile günlük gruplama
- Provider: `userGrowthDataProvider` (FutureProvider) — RPC veya client query
- X ekseni: tarihler, Y ekseni: yeni kullanıcı sayısı
- Boş veri durumu: `ChartEmpty` widget

### 1.2 Aktif Kullanıcı Grafiği
- `_ActiveUsersChart` widget — Son 30 gün günlük aktif kullanıcı
- fl_chart `LineChart`, ikinci seri olarak büyüme grafiğiyle aynı section'da gösterilebilir
- Veri kaynağı: `admin_logs` veya `profiles.last_sign_in_at` ile günlük gruplama
- Provider: `activeUsersTrendProvider` (FutureProvider)

### 1.3 Platform Dağılımı
- `_PlatformDistributionChart` widget — iOS vs Android pasta grafiği
- fl_chart `PieChart`
- Veri kaynağı: `profiles` tablosundaki platform bilgisi (varsa) veya feedback'lerdeki platform alanı
- Eğer platform verisi yoksa bu section atlanır
- Provider: `platformDistributionProvider` (FutureProvider)

### 1.4 Premium Dönüşüm Kartı
- `_PremiumConversionCard` widget — Free vs Premium kullanıcı sayısı ve oranı
- Basit iki satırlık StatCard tarzı kart, yüzdelik gösterge
- Veri kaynağı: `profiles` tablosunda subscription durumu
- Provider: Mevcut `adminStatsProvider` genişletilir (premiumCount, freeCount eklenir)

### 1.5 Top Kullanıcılar Tablosu
- `_TopUsersTable` widget — En çok entity kaydeden 5 kullanıcı
- Tablo: kullanıcı adı, kuş sayısı, üreme çifti sayısı, toplam kayıt
- Veri kaynağı: RPC veya client-side join query
- Provider: `topUsersProvider` (FutureProvider)

### Dashboard Section Düzeni
Mevcut section'ların altına eklenir:
```
[Mevcut] System Health Banner
[Mevcut] Stats Grid (5 kart)
[Mevcut] Quick Actions Bar
[YENİ]   Premium Conversion Card
[YENİ]   User Growth + Active Users Charts (yan yana veya alt alta)
[YENİ]   Platform Distribution Chart
[YENİ]   Top Users Table
[Mevcut] Dashboard Alerts
[Mevcut] Recent Actions
```

---

## 2. Sistem Bakım Araçları (Database ekranına yeni section'lar)

### 2.1 Orphan Data Tespiti
- `_OrphanDataSection` widget
- Kontrol edilen ilişkiler:
  - Egg → breeding_pairs (parent_id eksik)
  - Chick → eggs (parent_id eksik)
  - EventReminder → events (parent_id eksik)
  - Health records → birds (bird_id eksik)
- Her ilişki için: orphan sayısı göster + "Temizle" butonu
- Provider: `orphanDataProvider` (FutureProvider) — LEFT JOIN IS NULL sorguları
- Temizleme: hard delete (soft-delete'den farklı, çünkü parent yok)
- Onay dialog'u zorunlu

### 2.2 Soft-Delete Temizliği
- `_SoftDeleteCleanupSection` widget
- Gösterim: tablo bazında soft-deleted kayıt sayıları
- Temizleme: X günden (varsayılan 30) eski `is_deleted=true` kayıtları hard delete
- Gün seçimi: dropdown (7, 14, 30, 60, 90 gün)
- Provider: `softDeleteStatsProvider` (FutureProvider) — tablo bazında COUNT
- Toplu temizle butonu + onay dialog'u

### 2.3 Storage Kullanımı
- `_StorageUsageSection` widget
- Bucket bazında: dosya sayısı ve toplam boyut
- Bucket'lar: bird-photos, egg-photos, chick-photos, avatars, backups
- Provider: `storageUsageProvider` (FutureProvider) — Supabase storage API
- Salt okunur bilgi kartları, temizleme yok (tehlikeli)

### 2.4 Sync Durumu Özeti
- `_SyncStatusSection` widget
- Gösterim:
  - Pending sync kayıt sayısı (tablo bazında)
  - Error durumundaki kayıt sayısı
  - En eski pending kaydın yaşı
- Aksiyon: "Stuck kayıtları resetle" butonu — 24 saatten eski error kayıtları sil
- Provider: `syncStatusSummaryProvider` (FutureProvider) — sync_metadata tablosundan
- Onay dialog'u zorunlu

### Database Section Düzeni
Mevcut section'ların altına eklenir:
```
[Mevcut] Database Summary Card
[Mevcut] Global Actions Bar (Backup All / Reset All)
[YENİ]   Sync Status Section
[YENİ]   Soft-Delete Cleanup Section
[YENİ]   Orphan Data Section
[YENİ]   Storage Usage Section
[Mevcut] Tables List
```

---

## 3. Kullanıcı Detay İyileştirmeleri

### 3.1 Entity Özet Tablosu
- `_UserEntitySummary` widget
- Tablo satırları: Kuşlar, Üreme Çiftleri, Yumurtalar, Yavrular, Sağlık Kayıtları, Etkinlikler
- Her satır: entity adı + sayı
- Veri kaynağı: Paralel COUNT sorguları (mevcut `adminUserDetailProvider` genişletilir)
- AdminUserDetail modeline yeni alanlar: pairsCount, eggsCount, chicksCount, healthRecordsCount, eventsCount

### 3.2 Son Aktivite Zaman Çizelgesi
- Mevcut `activityLogs` zaten var ama sınırlı
- İyileştirme: log'lara icon ve renk ekle (action type'a göre)
- `_ActivityTimeline` widget — renkli timeline gösterimi
- Mevcut veri yeterli, sadece UI iyileştirmesi

### 3.3 Kullanıcı Storage Kullanımı
- `_UserStorageInfo` widget
- Kullanıcının bucket bazında fotoğraf sayısı
- Provider: `userStorageUsageProvider(userId)` (FutureProvider)
- Supabase storage list API ile kullanıcı klasörü sorgulanır

### User Detail Section Düzeni
```
[Mevcut] User Profile Header
[Mevcut] Subscription Info
[GÜNCELLENMİŞ] Entity Summary (genişletilmiş tablo)
[YENİ]   User Storage Info
[GÜNCELLENMİŞ] Activity Timeline (renkli)
[Mevcut] Admin Actions
```

---

## 4. Quick Actions İyileştirmeleri (Dashboard)

### 4.1 Sistem Sağlık Özet Kartı
- Mevcut health banner'ı genişlet
- DB boyutu, bağlantı havuzu, cache hit ratio — tek satırda 3 mini badge
- Veri kaynağı: mevcut `serverCapacityProvider`
- Kırmızı/sarı/yeşil renk kodlaması threshold'lara göre

### 4.2 Bekleyen Sync Kartı
- Dashboard stats grid'e 2 yeni kart ekle:
  - Pending Sync sayısı
  - Error Sync sayısı
- Veri kaynağı: `syncStatusSummaryProvider` (DB ekranıyla paylaşılır)
- AdminStats modeline eklenir: pendingSyncCount, errorSyncCount

---

## Teknik Detaylar

### Yeni/Güncellenecek Dosyalar

| Dosya | İşlem | Açıklama |
|-------|-------|----------|
| `admin_models.dart` | Güncelle | AdminStats'a yeni alanlar, yeni analitik modeller |
| `admin_constants.dart` | Güncelle | Yeni sabitler (chart period, cleanup defaults) |
| `admin_dashboard_providers.dart` | Güncelle | Yeni analitik provider'lar |
| `admin_data_providers.dart` | Güncelle | adminStatsProvider genişletme |
| `admin_dashboard_content.dart` | Güncelle | Yeni section'ları ekle |
| `admin_dashboard_sections.dart` | Güncelle | Yeni section widget'ları |
| `admin_dashboard_analytics.dart` | **Yeni** | Chart widget'ları (büyüme, aktif kullanıcı, platform) |
| `admin_database_content.dart` | Güncelle | Bakım section'larını ekle |
| `admin_database_maintenance.dart` | **Yeni** | Orphan, soft-delete, storage, sync widget'ları |
| `admin_database_providers.dart` | **Yeni** | Bakım provider'ları (orphan, soft-delete, storage, sync) |
| `admin_user_detail_content.dart` | Güncelle | Yeni section'lar |
| `admin_user_detail_content_stats.dart` | Güncelle | Genişletilmiş entity tablosu |
| `tr.json` / `en.json` / `de.json` | Güncelle | Yeni l10n anahtarları (~60 yeni key) |

### Yeni Provider'lar

| Provider | Tip | Dosya |
|----------|-----|-------|
| `userGrowthDataProvider` | FutureProvider | admin_dashboard_providers.dart |
| `activeUsersTrendProvider` | FutureProvider | admin_dashboard_providers.dart |
| `platformDistributionProvider` | FutureProvider | admin_dashboard_providers.dart |
| `topUsersProvider` | FutureProvider | admin_dashboard_providers.dart |
| `orphanDataProvider` | FutureProvider | admin_database_providers.dart |
| `softDeleteStatsProvider` | FutureProvider | admin_database_providers.dart |
| `storageUsageProvider` | FutureProvider | admin_database_providers.dart |
| `syncStatusSummaryProvider` | FutureProvider | admin_database_providers.dart |
| `userStorageUsageProvider` | FutureProvider.family | admin_data_providers.dart |

### Yeni Modeller (admin_models.dart'a eklenecek)

```dart
// Günlük veri noktası (chart'lar için)
@freezed
abstract class DailyDataPoint with _$DailyDataPoint {
  const DailyDataPoint._();
  const factory DailyDataPoint({
    required DateTime date,
    required int count,
  }) = _DailyDataPoint;
}

// Platform dağılımı
@freezed
abstract class PlatformDistribution with _$PlatformDistribution {
  const PlatformDistribution._();
  const factory PlatformDistribution({
    @Default(0) int iosCount,
    @Default(0) int androidCount,
    @Default(0) int otherCount,
  }) = _PlatformDistribution;
}

// Orphan data özeti
@freezed
abstract class OrphanDataSummary with _$OrphanDataSummary {
  const OrphanDataSummary._();
  const factory OrphanDataSummary({
    @Default(0) int orphanEggs,
    @Default(0) int orphanChicks,
    @Default(0) int orphanReminders,
    @Default(0) int orphanHealthRecords,
  }) = _OrphanDataSummary;
}

// Soft-delete istatistikleri
@freezed
abstract class SoftDeleteStats with _$SoftDeleteStats {
  const SoftDeleteStats._();
  const factory SoftDeleteStats({
    required String tableName,
    required int deletedCount,
    required int olderThanDaysCount, // seçilen gün eşiğinden eski olanlar
  }) = _SoftDeleteStats;
}

// Storage kullanımı
@freezed
abstract class BucketUsage with _$BucketUsage {
  const BucketUsage._();
  const factory BucketUsage({
    required String bucketName,
    @Default(0) int fileCount,
    @Default(0) int totalSizeBytes,
  }) = _BucketUsage;
}

// Sync durumu özeti
@freezed
abstract class SyncStatusSummary with _$SyncStatusSummary {
  const SyncStatusSummary._();
  const factory SyncStatusSummary({
    @Default(0) int pendingCount,
    @Default(0) int errorCount,
    DateTime? oldestPendingAt,
  }) = _SyncStatusSummary;
}

// Top kullanıcı
@freezed
abstract class TopUser with _$TopUser {
  const TopUser._();
  const factory TopUser({
    required String userId,
    required String fullName,
    @Default(0) int birdsCount,
    @Default(0) int pairsCount,
    @Default(0) int totalEntities,
  }) = _TopUser;
}
```

### AdminStats Genişletme
Mevcut alanlara ek:
```dart
@Default(0) int premiumCount,
@Default(0) int freeCount,
@Default(0) int pendingSyncCount,
@Default(0) int errorSyncCount,
```

### AdminUserDetail Genişletme
Mevcut alanlara ek:
```dart
@Default(0) int pairsCount,
@Default(0) int eggsCount,
@Default(0) int chicksCount,
@Default(0) int healthRecordsCount,
@Default(0) int eventsCount,
```

### Yeni L10n Anahtarları (tahmini ~60 key)

```
admin.analytics_title
admin.user_growth
admin.active_users_trend
admin.platform_distribution
admin.premium_conversion
admin.premium_users / admin.free_users / admin.conversion_rate
admin.top_users
admin.top_users_empty
admin.last_30_days

admin.maintenance_tools
admin.orphan_data
admin.orphan_eggs / admin.orphan_chicks / admin.orphan_reminders / admin.orphan_health_records
admin.orphan_found / admin.no_orphans
admin.clean_orphans / admin.clean_orphans_confirm
admin.orphans_cleaned

admin.soft_delete_cleanup
admin.soft_deleted_records
admin.older_than_days
admin.clean_soft_deleted / admin.clean_soft_deleted_confirm
admin.soft_deleted_cleaned
admin.no_soft_deleted

admin.storage_usage
admin.bucket_name / admin.file_count / admin.total_size
admin.no_storage_data

admin.sync_status
admin.pending_sync / admin.error_sync / admin.oldest_pending
admin.reset_stuck / admin.reset_stuck_confirm
admin.stuck_reset
admin.no_sync_issues

admin.entity_summary
admin.pairs_count / admin.eggs_count / admin.chicks_count
admin.health_records_count / admin.events_count
admin.user_storage
admin.no_user_files

admin.system_health_details
admin.db_size_label / admin.connections_label / admin.cache_label
```

### Veri Akışı

Tüm yeni provider'lar mevcut `requireAdmin(ref)` pattern'ini kullanır. Supabase sorguları doğrudan `client.from()` ile yapılır (admin-only exception kuralı gereği).

### Chart Kullanımı

fl_chart kütüphanesi zaten projede mevcut. Mevcut chart pattern'leri (statistics feature) referans alınır:
- `ChartEmpty`, `ChartLoading`, `ChartError` widget'ları kullanılır
- `calcChartInterval`, `calcChartMaxY`, `chartGridData` utility'leri kullanılır
- Theme-aware renkler

---

## Kapsam Dışı

- Yeni route eklenmeyecek (mevcut 10 admin route yeterli)
- Admin guard değişmeyecek
- AdminShell / sidebar değişmeyecek
- Community moderasyon (henüz coming soon)
- Push bildirim gönderme (tek admin için gereksiz)
- Yeni Supabase Edge Function eklenmeyecek
- Yeni Drift tablosu eklenmeyecek
