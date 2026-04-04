# Admin Panel Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the admin dashboard with analytics charts, add database maintenance tools, improve user detail screen with entity counts, and enhance quick actions.

**Architecture:** Hybrid approach — extend existing screens (dashboard, database, user detail) with new sections. New widget files for analytics charts and maintenance tools to keep file sizes under 300 lines. New provider file for database maintenance queries. All data fetched via Supabase client queries (admin-only exception).

**Tech Stack:** Flutter/Dart, Riverpod 3, fl_chart, Supabase PostgREST, easy_localization

**Spec:** `docs/superpowers/specs/2026-04-04-admin-panel-enhancements-design.md`

---

### Task 1: Extend AdminStats model and AdminUserDetail model

**Files:**
- Modify: `lib/features/admin/providers/admin_models.dart`

- [ ] **Step 1: Add new fields to AdminStats**

In `admin_models.dart`, add 4 new fields to the `AdminStats` factory:

```dart
@freezed
abstract class AdminStats with _$AdminStats {
  const AdminStats._();
  const factory AdminStats({
    @Default(0) int totalUsers,
    @Default(0) int activeToday,
    @Default(0) int newUsersToday,
    @Default(0) int totalBirds,
    @Default(0) int activeBreedings,
    @Default(0) int premiumCount,
    @Default(0) int freeCount,
    @Default(0) int pendingSyncCount,
    @Default(0) int errorSyncCount,
  }) = _AdminStats;

  factory AdminStats.fromJson(Map<String, dynamic> json) =>
      _$AdminStatsFromJson(json);
}
```

- [ ] **Step 2: Add new fields to AdminUserDetail**

Add 5 new fields to the `AdminUserDetail` factory:

```dart
@freezed
abstract class AdminUserDetail with _$AdminUserDetail {
  const AdminUserDetail._();
  const factory AdminUserDetail({
    required String id,
    @Default('') String email,
    String? fullName,
    String? avatarUrl,
    required DateTime createdAt,
    @Default(true) bool isActive,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? subscriptionUpdatedAt,
    @Default(0) int birdsCount,
    @Default(0) int pairsCount,
    @Default(0) int eggsCount,
    @Default(0) int chicksCount,
    @Default(0) int healthRecordsCount,
    @Default(0) int eventsCount,
    @Default([]) List<AdminLog> activityLogs,
  }) = _AdminUserDetail;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) =>
      _$AdminUserDetailFromJson(json);
}
```

- [ ] **Step 3: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Build completes successfully, `admin_models.freezed.dart` and `admin_models.g.dart` regenerated.

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/providers/admin_models.dart lib/features/admin/providers/admin_models.freezed.dart lib/features/admin/providers/admin_models.g.dart
git commit -m "feat(admin): extend AdminStats and AdminUserDetail with new fields"
```

---

### Task 2: Add new analytics and maintenance models

**Files:**
- Modify: `lib/features/admin/providers/admin_models.dart`

- [ ] **Step 1: Add DailyDataPoint model**

Append after `AdminSystemSettings` class:

```dart
/// Daily data point for analytics charts.
@freezed
abstract class DailyDataPoint with _$DailyDataPoint {
  const DailyDataPoint._();
  const factory DailyDataPoint({
    required DateTime date,
    @Default(0) int count,
  }) = _DailyDataPoint;

  factory DailyDataPoint.fromJson(Map<String, dynamic> json) =>
      _$DailyDataPointFromJson(json);
}
```

- [ ] **Step 2: Add OrphanDataSummary model**

```dart
/// Orphan data summary for database maintenance.
@freezed
abstract class OrphanDataSummary with _$OrphanDataSummary {
  const OrphanDataSummary._();
  const factory OrphanDataSummary({
    @Default(0) int orphanEggs,
    @Default(0) int orphanChicks,
    @Default(0) int orphanReminders,
    @Default(0) int orphanHealthRecords,
  }) = _OrphanDataSummary;

  factory OrphanDataSummary.fromJson(Map<String, dynamic> json) =>
      _$OrphanDataSummaryFromJson(json);
}
```

- [ ] **Step 3: Add SoftDeleteStats model**

```dart
/// Soft-delete statistics per table.
@freezed
abstract class SoftDeleteStats with _$SoftDeleteStats {
  const SoftDeleteStats._();
  const factory SoftDeleteStats({
    required String tableName,
    @Default(0) int deletedCount,
    @Default(0) int olderThanDaysCount,
  }) = _SoftDeleteStats;

  factory SoftDeleteStats.fromJson(Map<String, dynamic> json) =>
      _$SoftDeleteStatsFromJson(json);
}
```

- [ ] **Step 4: Add BucketUsage model**

```dart
/// Storage bucket usage info.
@freezed
abstract class BucketUsage with _$BucketUsage {
  const BucketUsage._();
  const factory BucketUsage({
    required String bucketName,
    @Default(0) int fileCount,
    @Default(0) int totalSizeBytes,
  }) = _BucketUsage;

  factory BucketUsage.fromJson(Map<String, dynamic> json) =>
      _$BucketUsageFromJson(json);
}
```

- [ ] **Step 5: Add SyncStatusSummary model**

```dart
/// Sync metadata summary for maintenance dashboard.
@freezed
abstract class SyncStatusSummary with _$SyncStatusSummary {
  const SyncStatusSummary._();
  const factory SyncStatusSummary({
    @Default(0) int pendingCount,
    @Default(0) int errorCount,
    DateTime? oldestPendingAt,
  }) = _SyncStatusSummary;

  factory SyncStatusSummary.fromJson(Map<String, dynamic> json) =>
      _$SyncStatusSummaryFromJson(json);
}
```

- [ ] **Step 6: Add TopUser model**

```dart
/// Top user by entity count for analytics.
@freezed
abstract class TopUser with _$TopUser {
  const TopUser._();
  const factory TopUser({
    required String userId,
    @Default('') String fullName,
    @Default(0) int birdsCount,
    @Default(0) int pairsCount,
    @Default(0) int totalEntities,
  }) = _TopUser;

  factory TopUser.fromJson(Map<String, dynamic> json) =>
      _$TopUserFromJson(json);
}
```

- [ ] **Step 7: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Build succeeds with all new models generated.

- [ ] **Step 8: Commit**

```bash
git add lib/features/admin/providers/admin_models.dart lib/features/admin/providers/admin_models.freezed.dart lib/features/admin/providers/admin_models.g.dart
git commit -m "feat(admin): add analytics and maintenance data models"
```

---

### Task 3: Add new constants

**Files:**
- Modify: `lib/features/admin/constants/admin_constants.dart`

- [ ] **Step 1: Add analytics and maintenance constants**

Add these constants inside `AdminConstants`:

```dart
  // Analytics
  static const int chartPeriodDays = 30;
  static const int topUsersLimit = 5;

  // Maintenance
  static const int defaultCleanupDays = 30;
  static const List<int> cleanupDayOptions = [7, 14, 30, 60, 90];

  // Soft-deletable tables (user data tables with is_deleted column)
  static const List<String> softDeletableTables = [
    'birds',
    'breeding_pairs',
    'nests',
    'clutches',
    'eggs',
    'chicks',
    'events',
    'event_reminders',
    'health_records',
    'notifications',
    'photos',
  ];

  // Storage buckets
  static const List<String> storageBuckets = [
    'bird-photos',
    'egg-photos',
    'chick-photos',
    'avatars',
    'backups',
  ];
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/admin/constants/admin_constants.dart
git commit -m "feat(admin): add analytics and maintenance constants"
```

---

### Task 4: Add localization keys to all 3 language files

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add Turkish keys**

Add these keys inside the `"admin"` object in `tr.json`:

```json
    "analytics_title": "Analitik",
    "user_growth": "Kullanici Buyumesi",
    "active_users_trend": "Aktif Kullanici Trendi",
    "premium_conversion": "Premium Donusum",
    "premium_users": "Premium Kullanicilar",
    "free_users": "Ucretsiz Kullanicilar",
    "conversion_rate": "Donusum Orani",
    "top_users": "En Aktif Kullanicilar",
    "top_users_empty": "Henuz kullanici verisi yok",
    "last_30_days": "Son 30 Gun",
    "new_registrations": "Yeni Kayitlar",
    "daily_active": "Gunluk Aktif",
    "maintenance_tools": "Bakim Araclari",
    "orphan_data": "Sahipsiz Veriler",
    "orphan_eggs": "Sahipsiz Yumurtalar",
    "orphan_chicks": "Sahipsiz Yavrular",
    "orphan_reminders": "Sahipsiz Hatirlatmalar",
    "orphan_health_records": "Sahipsiz Saglik Kayitlari",
    "orphan_found": "{} sahipsiz kayit bulundu",
    "no_orphans": "Sahipsiz veri yok",
    "clean_orphans": "Sahipsiz Verileri Temizle",
    "clean_orphans_confirm": "Bu islem sahipsiz kayitlari kalici olarak silecek. Devam etmek istiyor musunuz?",
    "orphans_cleaned": "Sahipsiz veriler temizlendi",
    "soft_delete_cleanup": "Silinmis Kayit Temizligi",
    "soft_deleted_records": "Silinmis Kayitlar",
    "older_than_days": "{} gunden eski",
    "clean_soft_deleted": "Eski Kayitlari Temizle",
    "clean_soft_deleted_confirm": "Bu islem secilen sureden eski silinmis kayitlari kalici olarak silecek. Devam etmek istiyor musunuz?",
    "soft_deleted_cleaned": "Eski silinmis kayitlar temizlendi",
    "no_soft_deleted": "Silinmis kayit yok",
    "days_label": "gun",
    "storage_usage": "Depolama Kullanimi",
    "bucket_name": "Alan",
    "file_count": "Dosya Sayisi",
    "total_size": "Toplam Boyut",
    "no_storage_data": "Depolama verisi alinamadi",
    "sync_status": "Senkronizasyon Durumu",
    "pending_sync": "Bekleyen",
    "error_sync": "Hatali",
    "oldest_pending": "En Eski Bekleyen",
    "reset_stuck": "Takili Kayitlari Sifirla",
    "reset_stuck_confirm": "24 saatten eski hatali senkronizasyon kayitlari sifirlanacak. Devam etmek istiyor musunuz?",
    "stuck_reset": "Takili kayitlar sifirlandi",
    "no_sync_issues": "Senkronizasyon sorunu yok",
    "entity_summary": "Varlik Ozeti",
    "pairs_count": "Ureme Ciftleri",
    "eggs_count": "Yumurtalar",
    "chicks_count": "Yavrular",
    "health_records_count": "Saglik Kayitlari",
    "events_count": "Etkinlikler",
    "user_storage": "Kullanici Depolamasi",
    "no_user_files": "Dosya bulunamadi"
```

- [ ] **Step 2: Add English keys**

Add these keys inside the `"admin"` object in `en.json`:

```json
    "analytics_title": "Analytics",
    "user_growth": "User Growth",
    "active_users_trend": "Active Users Trend",
    "premium_conversion": "Premium Conversion",
    "premium_users": "Premium Users",
    "free_users": "Free Users",
    "conversion_rate": "Conversion Rate",
    "top_users": "Top Users",
    "top_users_empty": "No user data yet",
    "last_30_days": "Last 30 Days",
    "new_registrations": "New Registrations",
    "daily_active": "Daily Active",
    "maintenance_tools": "Maintenance Tools",
    "orphan_data": "Orphan Data",
    "orphan_eggs": "Orphan Eggs",
    "orphan_chicks": "Orphan Chicks",
    "orphan_reminders": "Orphan Reminders",
    "orphan_health_records": "Orphan Health Records",
    "orphan_found": "{} orphan records found",
    "no_orphans": "No orphan data",
    "clean_orphans": "Clean Orphan Data",
    "clean_orphans_confirm": "This will permanently delete orphan records. Do you want to continue?",
    "orphans_cleaned": "Orphan data cleaned",
    "soft_delete_cleanup": "Deleted Records Cleanup",
    "soft_deleted_records": "Deleted Records",
    "older_than_days": "Older than {} days",
    "clean_soft_deleted": "Clean Old Records",
    "clean_soft_deleted_confirm": "This will permanently delete records older than the selected period. Do you want to continue?",
    "soft_deleted_cleaned": "Old deleted records cleaned",
    "no_soft_deleted": "No deleted records",
    "days_label": "days",
    "storage_usage": "Storage Usage",
    "bucket_name": "Bucket",
    "file_count": "File Count",
    "total_size": "Total Size",
    "no_storage_data": "Could not retrieve storage data",
    "sync_status": "Sync Status",
    "pending_sync": "Pending",
    "error_sync": "Error",
    "oldest_pending": "Oldest Pending",
    "reset_stuck": "Reset Stuck Records",
    "reset_stuck_confirm": "Error sync records older than 24 hours will be reset. Do you want to continue?",
    "stuck_reset": "Stuck records reset",
    "no_sync_issues": "No sync issues",
    "entity_summary": "Entity Summary",
    "pairs_count": "Breeding Pairs",
    "eggs_count": "Eggs",
    "chicks_count": "Chicks",
    "health_records_count": "Health Records",
    "events_count": "Events",
    "user_storage": "User Storage",
    "no_user_files": "No files found"
```

- [ ] **Step 3: Add German keys**

Add these keys inside the `"admin"` object in `de.json`:

```json
    "analytics_title": "Analytik",
    "user_growth": "Benutzerwachstum",
    "active_users_trend": "Aktive Benutzer Trend",
    "premium_conversion": "Premium Konvertierung",
    "premium_users": "Premium Benutzer",
    "free_users": "Kostenlose Benutzer",
    "conversion_rate": "Konvertierungsrate",
    "top_users": "Top Benutzer",
    "top_users_empty": "Noch keine Benutzerdaten",
    "last_30_days": "Letzte 30 Tage",
    "new_registrations": "Neue Registrierungen",
    "daily_active": "Taeglich Aktiv",
    "maintenance_tools": "Wartungswerkzeuge",
    "orphan_data": "Verwaiste Daten",
    "orphan_eggs": "Verwaiste Eier",
    "orphan_chicks": "Verwaiste Kueken",
    "orphan_reminders": "Verwaiste Erinnerungen",
    "orphan_health_records": "Verwaiste Gesundheitsakten",
    "orphan_found": "{} verwaiste Datensaetze gefunden",
    "no_orphans": "Keine verwaisten Daten",
    "clean_orphans": "Verwaiste Daten bereinigen",
    "clean_orphans_confirm": "Dieser Vorgang loescht verwaiste Datensaetze dauerhaft. Moechten Sie fortfahren?",
    "orphans_cleaned": "Verwaiste Daten bereinigt",
    "soft_delete_cleanup": "Geloeschte Datensaetze bereinigen",
    "soft_deleted_records": "Geloeschte Datensaetze",
    "older_than_days": "Aelter als {} Tage",
    "clean_soft_deleted": "Alte Datensaetze bereinigen",
    "clean_soft_deleted_confirm": "Dieser Vorgang loescht Datensaetze dauerhaft, die aelter als der gewaehlte Zeitraum sind. Moechten Sie fortfahren?",
    "soft_deleted_cleaned": "Alte geloeschte Datensaetze bereinigt",
    "no_soft_deleted": "Keine geloeschten Datensaetze",
    "days_label": "Tage",
    "storage_usage": "Speichernutzung",
    "bucket_name": "Bereich",
    "file_count": "Dateianzahl",
    "total_size": "Gesamtgroesse",
    "no_storage_data": "Speicherdaten konnten nicht abgerufen werden",
    "sync_status": "Sync-Status",
    "pending_sync": "Ausstehend",
    "error_sync": "Fehler",
    "oldest_pending": "Aeltester ausstehend",
    "reset_stuck": "Feststeckende Datensaetze zuruecksetzen",
    "reset_stuck_confirm": "Fehlerhafte Sync-Datensaetze aelter als 24 Stunden werden zurueckgesetzt. Moechten Sie fortfahren?",
    "stuck_reset": "Feststeckende Datensaetze zurueckgesetzt",
    "no_sync_issues": "Keine Sync-Probleme",
    "entity_summary": "Entitaets-Uebersicht",
    "pairs_count": "Zuchtpaare",
    "eggs_count": "Eier",
    "chicks_count": "Kueken",
    "health_records_count": "Gesundheitsakten",
    "events_count": "Ereignisse",
    "user_storage": "Benutzerspeicher",
    "no_user_files": "Keine Dateien gefunden"
```

- [ ] **Step 4: Verify l10n sync**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All 3 files in sync, no missing keys.

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(admin): add l10n keys for analytics and maintenance features"
```

---

### Task 5: Create analytics providers

**Files:**
- Modify: `lib/features/admin/providers/admin_dashboard_providers.dart`
- Modify: `lib/features/admin/providers/admin_data_providers.dart`

- [ ] **Step 1: Add analytics providers to admin_dashboard_providers.dart**

Add these providers after existing ones in `admin_dashboard_providers.dart`:

```dart
/// User growth data for the last 30 days (new registrations per day).
final userGrowthDataProvider = FutureProvider<List<DailyDataPoint>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final since = DateTime.now().subtract(const Duration(days: AdminConstants.chartPeriodDays));

  final result = await client
      .from(SupabaseConstants.profilesTable)
      .select('created_at')
      .gte('created_at', since.toUtc().toIso8601String())
      .order('created_at');

  final Map<String, int> grouped = {};
  for (final row in (result as List)) {
    final date = DateTime.parse(row['created_at'] as String);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    grouped[key] = (grouped[key] ?? 0) + 1;
  }

  final points = <DailyDataPoint>[];
  for (var i = AdminConstants.chartPeriodDays - 1; i >= 0; i--) {
    final date = DateTime.now().subtract(Duration(days: i));
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    points.add(DailyDataPoint(date: date, count: grouped[key] ?? 0));
  }
  return points;
});

/// Top users by entity count.
final topUsersProvider = FutureProvider<List<TopUser>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final profiles = await client
      .from(SupabaseConstants.profilesTable)
      .select('id, full_name')
      .eq('is_active', true)
      .limit(200);

  final List<TopUser> users = [];
  for (final p in (profiles as List)) {
    final userId = p['id'] as String;
    final birdsCount = await client
        .from(SupabaseConstants.birdsTable)
        .count()
        .eq('user_id', userId)
        .eq('is_deleted', false);
    final pairsCount = await client
        .from(SupabaseConstants.breedingPairsTable)
        .count()
        .eq('user_id', userId)
        .eq('is_deleted', false);
    if (birdsCount > 0 || pairsCount > 0) {
      users.add(TopUser(
        userId: userId,
        fullName: p['full_name'] as String? ?? '',
        birdsCount: birdsCount,
        pairsCount: pairsCount,
        totalEntities: birdsCount + pairsCount,
      ));
    }
  }

  users.sort((a, b) => b.totalEntities.compareTo(a.totalEntities));
  return users.take(AdminConstants.topUsersLimit).toList();
});
```

Add the necessary import at the top of the file:
```dart
import '../constants/admin_constants.dart';
```

- [ ] **Step 2: Update adminStatsProvider fallback to include premium counts**

In `admin_data_providers.dart`, update the fallback section of `adminStatsProvider` to also count premium users. Replace the fallback return block:

```dart
    // In the catch block, after existing counts:
    final premiumResult = await client
        .from(SupabaseConstants.profilesTable)
        .select('id')
        .eq('is_premium', true);
    final premiumCount = (premiumResult as List).length;

    // Count sync metadata
    final pendingSync = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id')
        .eq('status', 'pending');
    final errorSync = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id')
        .eq('status', 'error');

    return AdminStats(
      totalUsers: usersCount,
      activeToday: 0,
      newUsersToday: 0,
      totalBirds: birdsCount,
      activeBreedings: breedingCount,
      premiumCount: premiumCount,
      freeCount: usersCount - premiumCount,
      pendingSyncCount: (pendingSync as List).length,
      errorSyncCount: (errorSync as List).length,
    );
```

- [ ] **Step 3: Update adminUserDetailProvider with new counts**

In `admin_data_providers.dart`, add parallel queries for new entity counts inside `adminUserDetailProvider`. Add these futures alongside existing parallel queries:

```dart
  final pairsCountFuture = client
      .from(SupabaseConstants.breedingPairsTable)
      .count()
      .eq('user_id', userId);
  final eggsCountFuture = client
      .from(SupabaseConstants.eggsTable)
      .count()
      .eq('user_id', userId);
  final chicksCountFuture = client
      .from(SupabaseConstants.chicksTable)
      .count()
      .eq('user_id', userId);
  final healthRecordsCountFuture = client
      .from(SupabaseConstants.healthRecordsTable)
      .count()
      .eq('user_id', userId);
  final eventsCountFuture = client
      .from(SupabaseConstants.eventsTable)
      .count()
      .eq('user_id', userId);
```

Update the `.wait` destructuring to include these, and add the values to the returned `AdminUserDetail`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/providers/admin_dashboard_providers.dart lib/features/admin/providers/admin_data_providers.dart
git commit -m "feat(admin): add analytics and extended stats providers"
```

---

### Task 6: Create database maintenance providers

**Files:**
- Create: `lib/features/admin/providers/admin_database_providers.dart`

- [ ] **Step 1: Create the maintenance providers file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Sync metadata summary (pending + error counts).
final syncStatusSummaryProvider = FutureProvider<SyncStatusSummary>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final pendingResult = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id, created_at')
        .eq('status', 'pending');
    final errorResult = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id')
        .eq('status', 'error');

    final pendingList = pendingResult as List;
    DateTime? oldestPending;
    for (final row in pendingList) {
      final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (createdAt != null &&
          (oldestPending == null || createdAt.isBefore(oldestPending))) {
        oldestPending = createdAt;
      }
    }

    return SyncStatusSummary(
      pendingCount: pendingList.length,
      errorCount: (errorResult as List).length,
      oldestPendingAt: oldestPending,
    );
  } catch (e, st) {
    AppLogger.error('syncStatusSummaryProvider', e, st);
    return const SyncStatusSummary();
  }
});

/// Soft-delete statistics per table.
final softDeleteStatsProvider =
    FutureProvider.family<List<SoftDeleteStats>, int>((ref, olderThanDays) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));

  final stats = <SoftDeleteStats>[];
  for (final table in AdminConstants.softDeletableTables) {
    try {
      final allDeleted = await client
          .from(table)
          .select('id')
          .eq('is_deleted', true);
      final olderDeleted = await client
          .from(table)
          .select('id')
          .eq('is_deleted', true)
          .lt('updated_at', cutoff.toUtc().toIso8601String());

      stats.add(SoftDeleteStats(
        tableName: table,
        deletedCount: (allDeleted as List).length,
        olderThanDaysCount: (olderDeleted as List).length,
      ));
    } catch (e) {
      AppLogger.warning('softDeleteStats', 'Failed for $table: $e');
    }
  }
  return stats;
});

/// Orphan data detection.
final orphanDataProvider = FutureProvider<OrphanDataSummary>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    // Eggs without a valid clutch
    final orphanEggs = await client.rpc('admin_count_orphan_eggs');
    // Chicks without a valid egg
    final orphanChicks = await client.rpc('admin_count_orphan_chicks');
    // Event reminders without a valid event
    final orphanReminders = await client.rpc('admin_count_orphan_reminders');
    // Health records without a valid bird
    final orphanHealthRecords = await client.rpc('admin_count_orphan_health_records');

    return OrphanDataSummary(
      orphanEggs: (orphanEggs as int?) ?? 0,
      orphanChicks: (orphanChicks as int?) ?? 0,
      orphanReminders: (orphanReminders as int?) ?? 0,
      orphanHealthRecords: (orphanHealthRecords as int?) ?? 0,
    );
  } catch (e, st) {
    AppLogger.error('orphanDataProvider', e, st);
    // RPC not available — return zeros
    return const OrphanDataSummary();
  }
});

/// Storage bucket usage.
final storageUsageProvider = FutureProvider<List<BucketUsage>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final usages = <BucketUsage>[];
  for (final bucket in AdminConstants.storageBuckets) {
    try {
      final files = await client.storage.from(bucket).list(
        path: '',
        searchOptions: const StorageSearchOptions(limit: 1000),
      );
      var totalSize = 0;
      for (final file in files) {
        totalSize += file.metadata?['size'] as int? ?? 0;
      }
      usages.add(BucketUsage(
        bucketName: bucket,
        fileCount: files.length,
        totalSizeBytes: totalSize,
      ));
    } catch (e) {
      AppLogger.warning('storageUsage', 'Failed for $bucket: $e');
      usages.add(BucketUsage(bucketName: bucket));
    }
  }
  return usages;
});
```

Note: The `StorageSearchOptions` import comes from `supabase_flutter`. Add this import:
```dart
import 'package:supabase_flutter/supabase_flutter.dart' show StorageSearchOptions;
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/admin/providers/admin_database_providers.dart
git commit -m "feat(admin): add database maintenance providers"
```

---

### Task 7: Create maintenance action methods

**Files:**
- Modify: `lib/features/admin/providers/admin_actions_provider.dart`

- [ ] **Step 1: Add maintenance methods to AdminActionsNotifier**

Add these methods inside the `AdminActionsNotifier` class, in a new section after the existing "Security & Audit" section:

```dart
  // ── Maintenance Operations ───────────────────────────

  /// Clean soft-deleted records older than [days] days from all soft-deletable tables.
  Future<void> cleanSoftDeletedRecords(int days) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final cutoff = DateTime.now().subtract(Duration(days: days));

      var totalCleaned = 0;
      for (final table in AdminConstants.softDeletableTables) {
        try {
          final result = await client
              .from(table)
              .delete()
              .eq('is_deleted', true)
              .lt('updated_at', cutoff.toUtc().toIso8601String())
              .select('id');
          totalCleaned += (result as List).length;
        } catch (e) {
          AppLogger.warning('cleanSoftDeleted', 'Failed for $table: $e');
        }
      }

      await logAdminAction(
        client,
        ref.read(currentUserIdProvider),
        'soft_delete_cleanup',
        details: {'days': days, 'cleaned': totalCleaned},
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.soft_deleted_cleaned'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.cleanSoftDeletedRecords', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }

  /// Reset stuck sync metadata records (error status older than 24h).
  Future<void> resetStuckSyncRecords() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));

      await client
          .from(SupabaseConstants.syncMetadataTable)
          .delete()
          .eq('status', 'error')
          .lt('created_at', cutoff.toUtc().toIso8601String());

      await logAdminAction(
        client,
        ref.read(currentUserIdProvider),
        'sync_stuck_reset',
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.stuck_reset'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.resetStuckSyncRecords', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }
```

Add the missing import for `AdminConstants`:
```dart
import '../constants/admin_constants.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/admin/providers/admin_actions_provider.dart
git commit -m "feat(admin): add maintenance action methods"
```

---

### Task 8: Create analytics chart widgets

**Files:**
- Create: `lib/features/admin/widgets/admin_dashboard_analytics.dart`

- [ ] **Step 1: Create the analytics widgets file**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../statistics/utils/chart_utils.dart';
import '../../statistics/widgets/chart_states.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_models.dart';
import '../providers/admin_providers.dart';

/// Premium conversion card showing free vs premium ratio.
class DashboardPremiumConversionCard extends StatelessWidget {
  final AdminStats stats;
  const DashboardPremiumConversionCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.totalUsers;
    final premium = stats.premiumCount;
    final rate = total > 0 ? (premium / total * 100) : 0.0;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.premium_conversion'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'admin.premium_users'.tr(),
                    value: '$premium',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    label: 'admin.free_users'.tr(),
                    value: '${stats.freeCount}',
                    color: AppColors.neutral400,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    label: 'admin.conversion_rate'.tr(),
                    value: '${rate.toStringAsFixed(1)}%',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// User growth line chart (last 30 days).
class DashboardUserGrowthChart extends ConsumerWidget {
  const DashboardUserGrowthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(userGrowthDataProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'admin.user_growth'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'admin.last_30_days'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: dataAsync.when(
                loading: () => const ChartLoading(isLineChart: true),
                error: (e, _) => ChartError(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(userGrowthDataProvider),
                ),
                data: (data) {
                  final hasData = data.any((d) => d.count > 0);
                  if (!hasData) return const ChartEmpty();
                  return _buildLineChart(context, data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<DailyDataPoint> data) {
    final theme = Theme.of(context);
    final maxVal = data.fold<int>(0, (max, d) => d.count > max ? d.count : max).toDouble();
    final interval = calcChartInterval(maxVal);
    final maxY = calcChartMaxY(maxVal, interval);

    return LineChart(
      LineChartData(
        gridData: chartGridData(context, interval: interval),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                final date = data[index].date;
                return Text(
                  '${date.day}/${date.month}',
                  style: theme.textTheme.labelSmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].count.toDouble()),
            ),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top users table.
class DashboardTopUsersTable extends ConsumerWidget {
  const DashboardTopUsersTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(topUsersProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.top_users'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString(), style: theme.textTheme.bodySmall),
              data: (users) {
                if (users.isEmpty) {
                  return Text(
                    'admin.top_users_empty'.tr(),
                    style: theme.textTheme.bodySmall,
                  );
                }
                return Column(
                  children: users.map((u) => _TopUserRow(user: u)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUserRow extends StatelessWidget {
  final TopUser user;
  const _TopUserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: theme.textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              user.fullName.isNotEmpty ? user.fullName : 'admin.no_name'.tr(),
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${user.totalEntities}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/admin/widgets/admin_dashboard_analytics.dart
git commit -m "feat(admin): add analytics chart widgets"
```

---

### Task 9: Create database maintenance widgets

**Files:**
- Create: `lib/features/admin/widgets/admin_database_maintenance.dart`

- [ ] **Step 1: Create the maintenance widgets file**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../constants/admin_constants.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_database_providers.dart';
import '../providers/admin_models.dart';

/// Sync status summary section.
class DatabaseSyncStatusSection extends ConsumerWidget {
  const DatabaseSyncStatusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncAsync = ref.watch(syncStatusSummaryProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.sync_status'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            syncAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString(), style: theme.textTheme.bodySmall),
              data: (summary) {
                if (summary.pendingCount == 0 && summary.errorCount == 0) {
                  return Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('admin.no_sync_issues'.tr(), style: theme.textTheme.bodyMedium),
                    ],
                  );
                }
                return Column(
                  children: [
                    _SyncStatRow(
                      label: 'admin.pending_sync'.tr(),
                      count: summary.pendingCount,
                      color: AppColors.warning,
                    ),
                    _SyncStatRow(
                      label: 'admin.error_sync'.tr(),
                      count: summary.errorCount,
                      color: AppColors.error,
                    ),
                    if (summary.oldestPendingAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          '${'admin.oldest_pending'.tr()}: ${_formatAge(summary.oldestPendingAt!)}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    if (summary.errorCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _resetStuck(context, ref),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: Text('admin.reset_stuck'.tr()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatAge(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ${'admin.days_label'.tr()}';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }

  Future<void> _resetStuck(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.reset_stuck'.tr(),
      message: 'admin.reset_stuck_confirm'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    await ref.read(adminActionsProvider.notifier).resetStuckSyncRecords();
    ref.invalidate(syncStatusSummaryProvider);
  }
}

class _SyncStatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SyncStatRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft-delete cleanup section.
class DatabaseSoftDeleteSection extends ConsumerStatefulWidget {
  const DatabaseSoftDeleteSection({super.key});

  @override
  ConsumerState<DatabaseSoftDeleteSection> createState() => _DatabaseSoftDeleteSectionState();
}

class _DatabaseSoftDeleteSectionState extends ConsumerState<DatabaseSoftDeleteSection> {
  int _selectedDays = AdminConstants.defaultCleanupDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(softDeleteStatsProvider(_selectedDays));

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'admin.soft_delete_cleanup'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedDays,
                  underline: const SizedBox.shrink(),
                  items: AdminConstants.cleanupDayOptions.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text('$d ${'admin.days_label'.tr()}'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedDays = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(e.toString(), style: theme.textTheme.bodySmall),
              data: (stats) {
                final totalOld = stats.fold<int>(0, (s, t) => s + t.olderThanDaysCount);
                if (totalOld == 0) {
                  return Text('admin.no_soft_deleted'.tr(), style: theme.textTheme.bodyMedium);
                }
                return Column(
                  children: [
                    ...stats.where((s) => s.deletedCount > 0).map((s) => _SoftDeleteRow(stat: s)),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _cleanUp(context),
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: Text('admin.clean_soft_deleted'.tr()),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cleanUp(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.clean_soft_deleted'.tr(),
      message: 'admin.clean_soft_deleted_confirm'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    await ref.read(adminActionsProvider.notifier).cleanSoftDeletedRecords(_selectedDays);
    ref.invalidate(softDeleteStatsProvider(_selectedDays));
  }
}

class _SoftDeleteRow extends StatelessWidget {
  final SoftDeleteStats stat;
  const _SoftDeleteRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(stat.tableName, style: theme.textTheme.bodyMedium)),
          Text(
            '${stat.deletedCount}',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.neutral400),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${stat.olderThanDaysCount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: stat.olderThanDaysCount > 0 ? AppColors.error : null,
              fontWeight: stat.olderThanDaysCount > 0 ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Storage usage section.
class DatabaseStorageSection extends ConsumerWidget {
  const DatabaseStorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storageAsync = ref.watch(storageUsageProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.storage_usage'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            storageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('admin.no_storage_data'.tr(), style: theme.textTheme.bodySmall),
              data: (buckets) {
                if (buckets.isEmpty) {
                  return Text('admin.no_storage_data'.tr(), style: theme.textTheme.bodyMedium);
                }
                return Column(
                  children: buckets.map((b) => _BucketRow(bucket: b)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  final BucketUsage bucket;
  const _BucketRow({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(LucideIcons.hardDrive, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(bucket.bucketName, style: theme.textTheme.bodyMedium)),
          Text('${bucket.fileCount}', style: theme.textTheme.bodySmall),
          const SizedBox(width: AppSpacing.lg),
          Text(_formatBytes(bucket.totalSizeBytes), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/admin/widgets/admin_database_maintenance.dart
git commit -m "feat(admin): add database maintenance widgets"
```

---

### Task 10: Integrate analytics into dashboard

**Files:**
- Modify: `lib/features/admin/widgets/admin_dashboard_content.dart`

- [ ] **Step 1: Add import for analytics widgets**

Add this import at the top:
```dart
import 'admin_dashboard_analytics.dart';
```

- [ ] **Step 2: Add new sections to DashboardContent build method**

In the `DashboardContent.build()` method, add these widgets after the Quick Actions Row and before `DashboardAlertsSection`:

```dart
          const SizedBox(height: AppSpacing.xxl),
          DashboardPremiumConversionCard(stats: stats),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'admin.analytics_title'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          const DashboardUserGrowthChart(),
          const SizedBox(height: AppSpacing.lg),
          const DashboardTopUsersTable(),
```

The existing `DashboardAlertsSection` and `DashboardRecentActionsSection` remain below these.

- [ ] **Step 3: Add sync status cards to DashboardStatsGrid**

Add 2 new stat cards to the grid's children list (after the active breedings card):

```dart
            DashboardStatCard(
              icon: Semantics(label: 'admin.pending_sync'.tr(), child: const Icon(LucideIcons.refreshCw)),
              label: 'admin.pending_sync'.tr(),
              value: '${stats.pendingSyncCount}',
              color: stats.pendingSyncCount > 0 ? AppColors.warning : AppColors.success,
            ),
            DashboardStatCard(
              icon: Semantics(label: 'admin.error_sync'.tr(), child: const Icon(LucideIcons.alertTriangle)),
              label: 'admin.error_sync'.tr(),
              value: '${stats.errorSyncCount}',
              color: stats.errorSyncCount > 0 ? AppColors.error : AppColors.success,
            ),
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/widgets/admin_dashboard_content.dart
git commit -m "feat(admin): integrate analytics sections into dashboard"
```

---

### Task 11: Integrate maintenance tools into database screen

**Files:**
- Modify: `lib/features/admin/widgets/admin_database_content.dart`

- [ ] **Step 1: Add import for maintenance widgets**

Add this import at the top:
```dart
import 'admin_database_maintenance.dart';
```

- [ ] **Step 2: Add maintenance sections to DatabaseContent**

In the `DatabaseContent.build()` method, add these widgets after the `DatabaseGlobalActionsBar` and before the tables title:

```dart
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'admin.maintenance_tools'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          const DatabaseSyncStatusSection(),
          const SizedBox(height: AppSpacing.md),
          const DatabaseSoftDeleteSection(),
          const SizedBox(height: AppSpacing.md),
          const DatabaseStorageSection(),
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/widgets/admin_database_content.dart
git commit -m "feat(admin): integrate maintenance tools into database screen"
```

---

### Task 12: Enhance user detail stats

**Files:**
- Modify: `lib/features/admin/widgets/admin_user_detail_content_stats.dart`

- [ ] **Step 1: Replace UserDetailStatsRow with expanded entity grid**

Replace the entire `UserDetailStatsRow` class with a new version that shows all entity counts:

```dart
/// Stats grid showing all entity counts.
class UserDetailStatsRow extends StatelessWidget {
  final AdminUserDetail detail;
  const UserDetailStatsRow({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.entity_summary'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.bird),
                color: AppColors.budgieGreen,
                value: '${detail.birdsCount}',
                label: 'admin.birds'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.breedingActive),
                color: AppColors.budgieYellow,
                value: '${detail.pairsCount}',
                label: 'admin.pairs_count'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.egg),
                color: AppColors.info,
                value: '${detail.eggsCount}',
                label: 'admin.eggs_count'.tr(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.chick),
                color: AppColors.accent,
                value: '${detail.chicksCount}',
                label: 'admin.chicks_count'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.health),
                color: AppColors.error,
                value: '${detail.healthRecordsCount}',
                label: 'admin.health_records_count'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.calendar),
                color: AppColors.primary,
                value: '${detail.eventsCount}',
                label: 'admin.events_count'.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/admin/widgets/admin_user_detail_content_stats.dart
git commit -m "feat(admin): enhance user detail with full entity summary grid"
```

---

### Task 13: Export new providers from admin_providers barrel

**Files:**
- Modify: `lib/features/admin/providers/admin_providers.dart`

- [ ] **Step 1: Add export for new providers file**

Read the file first, then add this export line:
```dart
export 'admin_database_providers.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/admin/providers/admin_providers.dart
git commit -m "feat(admin): export database maintenance providers"
```

---

### Task 14: Verify build and run quality checks

**Files:** None (verification only)

- [ ] **Step 1: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Build completes with no errors.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors. Warnings/infos are acceptable.

- [ ] **Step 3: Run l10n sync check**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All 3 language files in sync.

- [ ] **Step 4: Run code quality check**

Run: `python3 scripts/verify_code_quality.py`
Expected: No anti-pattern violations in new/modified files.

- [ ] **Step 5: Run existing tests**

Run: `flutter test --exclude-tags golden`
Expected: All existing tests pass. New code does not break existing functionality.

- [ ] **Step 6: Fix any issues found**

If any check fails, fix the issue before proceeding.

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "chore(admin): fix any remaining issues from quality checks"
```

(Skip this commit if no issues were found.)

---

### Task 15: Update CLAUDE.md stats if needed

**Files:**
- Possibly modify: `CLAUDE.md`

- [ ] **Step 1: Verify stats**

Run: `python3 scripts/verify_rules.py`
Expected: Check if any stat (source files, l10n keys, etc.) is out of date.

- [ ] **Step 2: Auto-fix if needed**

Run: `python3 scripts/verify_rules.py --fix`

- [ ] **Step 3: Commit if changed**

```bash
git add CLAUDE.md
git commit -m "chore: update CLAUDE.md stats table"
```
