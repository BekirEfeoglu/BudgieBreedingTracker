# Admin Panel — Activity Feed, Error Tracking, User Notifications

**Date**: 2026-04-04
**Scope**: 3 features extending existing admin dashboard and user management

---

## 1. Real-Time Activity Feed (Dashboard Section)

### Purpose
Show the last 24 hours of user activity on the dashboard so the admin can see what's happening without checking individual users.

### Data Source
Query the 4 main entity tables for recently created records:
- `birds` — `created_at` in last 24h, grouped by user_id
- `breeding_pairs` — `created_at` in last 24h, grouped by user_id  
- `eggs` — `created_at` in last 24h, grouped by user_id
- `chicks` — `created_at` in last 24h, grouped by user_id

Join with `profiles` to get user name/avatar.

### Provider
`recentUserActivityProvider` (FutureProvider) — Returns `List<UserActivity>`:

```dart
@freezed
abstract class UserActivity with _$UserActivity {
  const UserActivity._();
  const factory UserActivity({
    required String userId,
    @Default('') String fullName,
    String? avatarUrl,
    required String entityType, // 'bird', 'breeding_pair', 'egg', 'chick'
    required int count,
    required DateTime latestAt,
  }) = _UserActivity;
}
```

Query approach: 4 parallel queries, merge client-side, sort by latestAt desc, limit 20.

### Widget
`DashboardActivityFeedSection` — Card with timeline-style list:
- Each row: CircleAvatar + "User X added N birds" + relative time
- Empty state: "No recent activity"
- Location: After analytics section, before alerts section

### L10n Keys
```
admin.recent_activity — "Son Aktiviteler"
admin.no_recent_activity — "Son 24 saatte aktivite yok"
admin.activity_birds — "{} kus ekledi"
admin.activity_pairs — "{} ureme cifti olusturdu"
admin.activity_eggs — "{} yumurta kaydetti"
admin.activity_chicks — "{} yavru kaydetti"
admin.last_24_hours — "Son 24 Saat"
```

---

## 2. Error Summary Card (Dashboard Section)

### Purpose
Quick overview of recent errors without leaving the admin panel or opening Sentry.

### Data Source
- `security_events` table — count events in last 24h by severity
- `admin_logs` table — count entries with action containing 'error' in last 24h

No Sentry API integration (YAGNI — would require API key management).

### Provider
`recentErrorsSummaryProvider` (FutureProvider) — Returns `ErrorSummary`:

```dart
@freezed
abstract class ErrorSummary with _$ErrorSummary {
  const ErrorSummary._();
  const factory ErrorSummary({
    @Default(0) int totalErrors,
    @Default(0) int highSeverity,
    @Default(0) int mediumSeverity,
    @Default(0) int lowSeverity,
    @Default([]) List<SecurityEvent> recentEvents,
  }) = _ErrorSummary;
}
```

### Widget
`DashboardErrorSummaryCard` — Compact card:
- Header: "Hatalar (24h)" + total count badge
- 3 severity mini-stats (high/medium/low) with color coding
- Last 3 events as brief list items
- If totalErrors == 0: green "No errors" state
- Location: Right after system health banner (critical info at top)

### L10n Keys
```
admin.error_summary — "Hata Ozeti"
admin.errors_24h — "Hatalar (24s)"
admin.no_errors — "Son 24 saatte hata yok"
admin.high_severity_count — "{} yuksek"
admin.medium_severity_count — "{} orta"
admin.low_severity_count — "{} dusuk"
admin.recent_errors — "Son Hatalar"
```

---

## 3. In-App Notification Sending

### Purpose
Admin can send in-app notifications to individual users or bulk selected users.

### Data Flow
Admin fills title + message → INSERT into `notifications` table → user sees it when they open the app.

### Notifications Table Schema (existing)
Uses existing `notifications` table with fields:
- `id` (uuid)
- `user_id` (uuid)
- `title` (text)
- `body` (text)  
- `type` (text) — will use `'admin_message'`
- `is_read` (boolean, default false)
- `created_at` (timestamp)

### Action Methods
Add to `AdminActionsNotifier`:

```dart
Future<void> sendNotification(String targetUserId, String title, String body)
Future<void> sendBulkNotification(List<String> userIds, String title, String body)
```

Both methods:
1. INSERT into notifications table
2. Log to admin_logs with action 'notification_sent'
3. Update state with success/error

### UI: Notification Bottom Sheet
`AdminNotificationSheet` — Modal bottom sheet with:
- Title TextField (required, max 100 chars)
- Message TextField (required, max 500 chars, multiline)
- Send button with loading state
- Character counters
- Shared between single-user and bulk flows

### UI: Single User
`AdminUserDetailScreen` — Add "Send Notification" button to AppBar popup menu.

### UI: Bulk
`_BulkActionBar` — Add "Send Notification" action to the existing bulk actions. Opens the same bottom sheet, sends to all selected users.

### L10n Keys
```
admin.send_notification — "Bildirim Gonder"
admin.notification_title — "Bildirim Basligi"
admin.notification_message — "Bildirim Mesaji"
admin.notification_title_required — "Baslik zorunludur"
admin.notification_message_required — "Mesaj zorunludur"
admin.notification_sent — "Bildirim gonderildi"
admin.notification_sent_bulk — "{} kullaniciya bildirim gonderildi"
admin.send — "Gonder"
admin.bulk_send_notification — "Toplu Bildirim Gonder"
admin.notification_title_hint — "Bildirim basligi girin"
admin.notification_message_hint — "Bildirim mesaji girin"
```

---

## Files Changed/Created

| File | Action | Purpose |
|------|--------|---------|
| `admin_models.dart` | Modify | Add UserActivity, ErrorSummary models |
| `admin_dashboard_providers.dart` | Modify | Add activity + error providers |
| `admin_dashboard_activity.dart` | **Create** | Activity feed + error summary widgets |
| `admin_notification_sheet.dart` | **Create** | Notification sending bottom sheet |
| `admin_actions_provider.dart` | Modify | Add notification methods |
| `admin_dashboard_content.dart` | Modify | Insert new sections |
| `admin_user_detail_screen.dart` | Modify | Add notification menu item |
| `admin_users_screen_bulk_actions.dart` | Modify | Add bulk notification action |
| `tr.json` / `en.json` / `de.json` | Modify | ~25 new keys |

## Out of Scope
- Push notifications (FCM/APNs) — in-app only
- Sentry API integration — uses local security_events/admin_logs only
- New routes — all within existing screens
- New Drift tables — uses existing notifications table via Supabase
- Notification read tracking — existing is_read field handles this
