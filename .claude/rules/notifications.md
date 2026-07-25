# Notifications

Bildirimler iki kanal üzerinden gelir: **FCM push** (sunucu kaynaklı) ve **local notifications** (zamanlanmış cihaz-içi). Her ikisi de deeplink payload'ı taşıyabilir.

## Stack
| Tür | Paket | Trigger |
|-----|-------|---------|
| Push (remote) | `firebase_messaging` | Sunucu — `send-push` edge function |
| Local | `flutter_local_notifications` | Cihaz — schedule API |
| Permission | `flutter_local_notifications` + platform settings | Contextual feature/settings CTA |

## FCM Push Flow
```
Domain event (egg hatching, marketplace sale)
  -> Trigger calls send-push edge function with userIds + payload
  -> Edge fn validates JWT, reads user FCM tokens from DB
  -> Token listesi dedupe + MAX_TOKENS=500'e clamp'lenir (toplam alıcı tavanı)
  -> FCM REST API'ye BATCH_SIZE=50'lik gruplar hâlinde gönderilir (push_core.ts)
  -> FCM delivers to devices
  -> App handles foreground/background/terminated states
```

## Permission Flow
- iOS: `requestPermission()` yalnızca contextual CTA ile çağrılır; kullanıcı reddederse app settings deeplink gösterilir
- Android 13+: `POST_NOTIFICATIONS` runtime permission yalnızca contextual CTA/feature flow ile istenir
- İlk açılışta DEĞİL — kullanıcı bildirim ayarlarına girdiğinde veya feature flow'da kontekstli iste ("Kuluçka hatırlatması için bildirim izni gerekli")
- Permission denied state'i `notificationPermissionGrantedProvider` ile takip et; provider gerçek platform status'u okunana kadar `false` başlar
- `NotificationSettingsScreen` sadece status refresh yapar; prompt üretmez. CTA `notificationPermissionRequestControllerProvider` üzerinden çalışır

## FCM Token Management
- Token Supabase'de `fcm_tokens` tablosuna kaydedilir (multi-device)
- Token refresh'te eski token'ı sil, yeniyi ekle
- Logout'ta yalnız BU cihazın aktif token'ı deaktive edilir (`PushNotificationService.deactivateCurrentToken` → `FcmTokenRemoteSource.deactivateToken`) — per-device, `unregisterAll` DEĞİL. Bu çağrı `auth.signOut()`'tan **ÖNCE** koşar (`AuthActions.signOut` ilk adım): `fcm_tokens` UPDATE'i RLS için geçerli bir `auth.uid()` ister; sonraya alınırsa sessizce başarısız olur (auth.md § Logout Zinciri). Diğer cihazların oturumu açıksa onların token'ı korunur; deaktive edilen cihaz artık eski hesabın push'unu almaz. `deactivateCurrentToken` ayrıca `_currentUserId`'yi null'lar, böylece geç gelen `onTokenRefresh` token'ı eski kullanıcıya yeniden yazmaz
- iOS APNs token + FCM token eşleştirmesi otomatik
- FCM kaydı splash'i BLOKLAMAZ: `appInitializationProvider` local kanal init + rate limiter'ı await eder, `pushNotificationService.init` (token fetch/register, ağ) `InitStep.ready` sonrası deferred microtask'te koşar — kalıcı `onTokenRefresh` dinleyicisi geç kaydı telafi eder. Bu init'i kritik yola geri TAŞIMA

```dart
// Token register/refresh — dinleyici PushNotificationService.init içinde bağlanır;
// refresh'te token _currentUserId için fcm_tokens'a upsert edilir (_upsertToken)
FirebaseMessaging.instance.onTokenRefresh.listen((token) {
  // service._upsertToken(_currentUserId, token)
});

// Logout cleanup — yalnız bu cihazın aktif token'ı deaktive edilir
await ref.read(pushNotificationServiceProvider).deactivateCurrentToken();
```

## Foreground / Background / Terminated
| State | Handler | UI |
|-------|---------|----|
| Foreground | `FirebaseMessaging.onMessage` | In-app banner (don't auto-navigate) |
| Background | `FirebaseMessaging.onMessageOpenedApp` | Navigate via deeplink |
| Terminated | `getInitialMessage()` on app start | Navigate after splash |

## Deeplink Payload
Push ve local bildirim **aynı payload tipini** paylaşır: tek bir
`'<type>:<id>'` string'i. `route` diye bir alan taşınmaz — rota client'ta
türetilir.

`PushNotificationService._payloadFromMessage` FCM `data`'sından bunu üretir:
- `data['payload']` doluysa aynen kullanılır
- yoksa `type` (`type` | `reference_type`) + entity id (`entity_id` |
  `related_entity_id` | `reference_id` | `id`) birleştirilip `'$type:$entityId'`
  olur; ikisinden biri yoksa payload `null` (deeplink yok)

Rota çözümü `NotificationChannelConfig.payloadToRoute`:

| `type` | Rota |
|--------|------|
| `breeding`, `incubation` | `/breeding/<id>` |
| `bird` | `/birds/<id>` |
| `chick`, `chick_care`, `banding` | `/chicks/<id>` |
| `egg`, `egg_turning` | `/breeding` (id KULLANILMAZ — payload egg id'si taşır, pair id'si değil; `/eggs/<id>` rotası yoktur) |
| `health_check` | `/health-records/<id>` |
| `event`, `event_reminder`, `calendar` | `/calendar` |
| `notification` | `/notifications` |
| diğer | `null` |

- Id enjekte eden rotalarda `isValidRouteId(id)` doğrulaması zorunlu; geçersizse
  payload reddedilir (`AppLogger.warning`) ki crafted payload NotFound ekranı
  flash'lamasın
- Bilinmeyen tip → `null` → navigation yok (ana ekranda kalınır)

## Local Notifications (Scheduling)
- Kuluçka hatırlatması, etkinlik reminder vb.
- `NotificationScheduler` (`lib/domain/services/notifications/notification_scheduler.dart`) schedule yönetir
- Notification ID'leri deterministik, `NotificationIds.generate()` ile — raw `.hashCode` DEĞİL, FNV-1a hash + partition'lanmış ID alanı (bkz. calendar.md § ID Stability)
- Cancel + reschedule pattern: insert/update'te eski ID'leri iptal et, yenilerini ekle
- Timezone-aware: `tz.TZDateTime` kullan, naive `DateTime` değil
- Feature side-effect'leri schedule etmeden önce `await ref.read(notificationToggleSettingsReadyProvider.future)` kullanmalı; doğrudan `notificationToggleSettingsProvider` okumak kayıtlı kapalı toggle'lar yüklenmeden default `true` ile schedule oluşturabilir
- App-start/reboot reschedule akışı `NotificationRescheduler` üzerinden `NotificationSettingsDao.getByUser()` snapshot'ını scheduler'a geçirmeli; kullanıcı kapattığı kategoriler yeniden kurulmaz
- Local notification background tap callback'i payload'ı kalıcı kuyruğa yazar; `NotificationService.init()`/restore bu payload'ları `onNotificationTap` ile işler

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
Kanal ID'lerinin tek kaynağı `NotificationChannelConfig`
(`lib/domain/services/notifications/notification_channel_config.dart`).
Tanımlı **beş** sabit + `_ =>` dalının ürettiği literal `'default'`:

| ID | Sabit | Kullanan |
|----|-------|----------|
| `egg_turning` | `eggTurningChannelId` | `NotificationScheduler` yumurta çevirme |
| `incubation` | `incubationChannelId` | `NotificationScheduler` kuluçka milestone'ları |
| `chick_care` | `chickCareChannelId` | Yavru bakım/tartım + banding hatırlatmaları |
| `health_check` | `healthCheckChannelId` | Sağlık kaydı takip hatırlatması |
| `streak` | `streakChannelId` | `StreakReminderScheduler` |
| `default` | (literal) | `NotificationProcessor` fallback — `_channelForType` eşleşmeyen tip |

`breeding`, `marketplace`, `community`, `system` diye kanal YOKTUR; bunlar
önceki bir tasarım hedefiydi. Yeni kanal eklemek `NotificationChannelConfig`'e
sabit + `channelName`/`channelDescription` dallarını + üç dilde
`notifications.channel_*_name/_desc` anahtarlarını gerektirir.

**Per-channel importance YOK:** ayrı bir `AndroidNotificationChannel(...)`
oluşturma çağrısı yoktur (repoda hiç geçmiyor). Kanal, gönderim anında
`AndroidNotificationDetails` ile implicit oluşur ve
`NotificationService._buildNotificationDetails` HER kanal için sabit
`importance: Importance.high` + `priority: Priority.high` verir. Kanal başına
farklı importance istiyorsan önce gerçek kanal oluşturma adımı eklenmeli
(mevcut kurulumlarda Android importance'ı sonradan kodla değiştirilemez).

### Streak Reminder (`streak` kanalı)
`StreakReminderScheduler` (`lib/domain/services/notifications/streak_reminder_scheduler.dart`)
her `runDailyCheckin` sonrası (no-op check-in dahil) yeniden koşar: `NotificationToggleSettings.streakReminder`
toggle'ı açık VE kullanıcının güncel streak'i **≥3** ise, deterministik ID'yle
(`NotificationIds.streakReminderBaseId = 900000`) **tek** bir hatırlatmayı yarın
saat **20:00 local**'e (`tz.TZDateTime`, field-addition gün offset'i — datetime-format.md)
schedule eder; her seferinde önce cancel sonra (koşullu) schedule — kullanıcı
uygulamayı bugün açtıysa yarının reminder'ı otomatik günceli yansıtır. Toggle
`allEnabled`'a DAHİL DEĞİL (opt-out, varsayılan açık). Detay: gamification.md § Streak Sistemi.

## Quiet Hours / Preferences
**Server-side enforcement eklendi (2026-07-03, §5.2):** `send-push` artık alıcının
quiet-hours penceresini honor edebiliyor. Saf mantık `push_core.ts`'te
(`isWithinQuietHours` — client `NotificationRateLimiter.isDoNotDisturbActive`
wraparound'unu birebir yansıtır; `localHourInZone` alıcının IANA timezone'unda
yerel saati hesaplar; `isSuppressedByQuietHours` **fail-open**). `index.ts`
alıcının `profiles.quiet_hours` (JSONB `{enabled,startHour,endHour,timeZone}`,
migration `20260703044503`) penceresini okuyup, quiet penceresi içindeki
alıcıları teslimattan düşürür.

Emniyet by-construction: bastırma **opt-in** — sadece push isteği
`respectQuietHours: true` gönderirse çalışır. Kritik/incubation bildirimleri bu
flag'i set etmez ve asla bastırılamaz. Ayrıca herhangi bir eksik/geçersiz config
(NULL pref, geçersiz saat/tz, lookup hatası) → teslim et.

Client DND penceresi `NotificationToggleSettingsNotifier.setDndHours()` ile
local rate limiter'a ve `profiles.quiet_hours` kolonuna birlikte yazılır. Admin
panelinden gönderilen manuel kullanıcı/bulk bildirimleri non-kritik kabul edilir
ve `respectQuietHours: true` ile gönderilir. Yeni non-kritik `send-push`
caller'ları bu flag'i bilinçli olarak set etmeli; sistem sağlığı, inkübasyon,
güvenlik ve hesap kritik bildirimleri flag'i set etmemeli.
- Kullanıcı kategori bazlı bildirim açma/kapama (`profile.notification_preferences`) — client-side UI var

## Testing
- Unit: `NotificationService` mock'lanır
- Integration: `send-push` edge fn test (auth + payload + FCM mock)
- Manual: iOS Simulator local notification (push gerçek cihaz gerektirir)
- Background local tap persistence için `SharedPreferences.setMockInitialValues({})` kullan; callback payload'ı restore edilene kadar kaybolmamalı

## Anti-Patterns
1. İlk açılışta context'siz permission istemek (kullanıcı reddeder, geri dönüş yok)
2. FCM token'ı logout'ta temizlememek (eski hesaba bildirim gider)
3. Deeplink payload'ını validate etmeden navigate etmek (crash riski)
4. Foreground'da otomatik navigation (kullanıcı işini bölme)
5. `DateTime.now()` ile schedule (timezone bug — `tz.TZDateTime` zorunlu)
6. Notification ID çakışması (deterministik hash kullan)
7. Send-push edge fn'i atlayıp doğrudan FCM REST çağrısı (JWT verify bypass)
8. Bildirim içeriğinde PII (kuş adı OK, doğum tarihi NO)

> **İlgili**: edge-functions.md (send-push), security.md (FCM token), datetime-format.md (timezone), localization.md (notification copy), gamification.md (streak sistemi, streak reminder tetikleme)
