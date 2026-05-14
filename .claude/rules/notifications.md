# Notifications

Bildirimler iki kanal üzerinden gelir: **FCM push** (sunucu kaynaklı) ve **local notifications** (zamanlanmış cihaz-içi). Her ikisi de deeplink payload'ı taşıyabilir.

## Stack
| Tür | Paket | Trigger |
|-----|-------|---------|
| Push (remote) | `firebase_messaging` | Sunucu — `send-push` edge function |
| Local | `flutter_local_notifications` | Cihaz — schedule API |
| Permission | `permission_handler` (iOS) | İlk launch + Settings |

## FCM Push Flow
```
Domain event (egg hatching, marketplace sale)
  -> Trigger calls send-push edge function with userIds + payload
  -> Edge fn validates JWT, reads user FCM tokens from DB
  -> Sends to FCM REST API in batches (500 tokens/batch)
  -> FCM delivers to devices
  -> App handles foreground/background/terminated states
```

## Permission Flow
- iOS: zorunlu `requestPermission()` — kullanıcı reddederse settings deeplink göster
- Android 13+: `POST_NOTIFICATIONS` runtime permission
- İlk açılışta DEĞİL — kullanıcı bildirim ayarlarına girdiğinde veya feature flow'da kontekstli iste ("Kuluçka hatırlatması için bildirim izni gerekli")
- Permission denied state'i provider'da takip et (`notificationPermissionProvider`)

## FCM Token Management
- Token Supabase'de `user_fcm_tokens` tablosuna kaydedilir (multi-device)
- Token refresh'te eski token'ı sil, yeniyi ekle
- Logout'ta tüm cihaz token'larını sil (cross-device security)
- iOS APNs token + FCM token eşleştirmesi otomatik

```dart
// Token registration
FirebaseMessaging.instance.onTokenRefresh.listen((token) {
  ref.read(fcmTokenServiceProvider).register(token);
});

// Logout cleanup
await ref.read(fcmTokenServiceProvider).unregisterAll();
```

## Foreground / Background / Terminated
| State | Handler | UI |
|-------|---------|----|
| Foreground | `FirebaseMessaging.onMessage` | In-app banner (don't auto-navigate) |
| Background | `FirebaseMessaging.onMessageOpenedApp` | Navigate via deeplink |
| Terminated | `getInitialMessage()` on app start | Navigate after splash |

## Deeplink Payload
Push payload `data` field'ı standart şema:
```json
{
  "type": "egg_hatching",
  "entity_id": "uuid",
  "route": "/eggs/uuid",
  "extra": "json string optional"
}
```
- `route` GoRouter path'i (deep link uyumlu olmalı)
- Handler: type'a göre validate et, sonra `context.push(route)`
- Bilinmeyen type → `AppLogger.warning` + ana ekran fallback

## Local Notifications (Scheduling)
- Kuluçka hatırlatması, etkinlik reminder vb.
- `IncubationReminderService` schedule yönetir
- Notification ID'leri deterministik (`'egg_${eggId}_day_${day}'.hashCode`)
- Cancel + reschedule pattern: insert/update'te eski ID'leri iptal et, yenilerini ekle
- Timezone-aware: `tz.TZDateTime` kullan, naive `DateTime` değil

```dart
// Schedule
await flutterLocalNotifications.zonedSchedule(
  notificationId,
  title,
  body,
  tz.TZDateTime.from(scheduledTime, tz.local),
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
);
```

## Notification Categories (iOS) / Channels (Android)
| ID | Amaç | Importance |
|----|------|------------|
| `incubation` | Kuluçka hatırlatma | High |
| `breeding` | Çiftleştirme etkinlik | Default |
| `marketplace` | İlan eşleşme/mesaj | High |
| `community` | Mention, reply | Default |
| `system` | Bakım, güncelleme | Low |

Channel'lar `lib/data/services/notification_service.dart` içinde initialize edilir.

## Quiet Hours / Preferences
- Kullanıcı kategori bazlı bildirim açma/kapama (`profile.notification_preferences`)
- Sunucu tarafı `send-push` çağrı öncesi tercihi kontrol eder
- Cihaz Do Not Disturb'a ek olarak app-level quiet hours desteği (gece bildirim yok)

## Testing
- Unit: `NotificationService` mock'lanır
- Integration: `send-push` edge fn test (auth + payload + FCM mock)
- Manual: iOS Simulator local notification (push gerçek cihaz gerektirir)
- Background handler test'i ayrı isolate'te çalışır — test setup'ta dikkat

## Anti-Patterns
1. İlk açılışta context'siz permission istemek (kullanıcı reddeder, geri dönüş yok)
2. FCM token'ı logout'ta temizlememek (eski hesaba bildirim gider)
3. Deeplink payload'ını validate etmeden navigate etmek (crash riski)
4. Foreground'da otomatik navigation (kullanıcı işini bölme)
5. `DateTime.now()` ile schedule (timezone bug — `tz.TZDateTime` zorunlu)
6. Notification ID çakışması (deterministik hash kullan)
7. Send-push edge fn'i atlayıp doğrudan FCM REST çağrısı (JWT verify bypass)
8. Bildirim içeriğinde PII (kuş adı OK, doğum tarihi NO)

> **İlgili**: edge-functions.md (send-push), security.md (FCM token), datetime-format.md (timezone), localization.md (notification copy)
