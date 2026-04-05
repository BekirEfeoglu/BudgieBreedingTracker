# Background Notifications Fix Design

> Uygulama kapalıyken bildirimlerin gelmeme sorununu çözmek için tasarım.

## Problem

Uygulama kapalıyken (terminated) veya cihaz yeniden başlatıldığında zamanlanmış bildirimler tetiklenmiyor. Sorun hem `zonedSchedule` ile planlanan bildirimleri hem de veritabanındaki bekleyen hatırlatmaları etkiliyor.

## Kök Nedenler

1. **Boot receiver eksik**: AndroidManifest'te `RECEIVE_BOOT_COMPLETED` izni var ama `ScheduledNotificationBootReceiver` kayıtlı değil. Cihaz yeniden başlatıldığında tüm zamanlanmış alarmlar kayboluyor.
2. **Uygulama güncellemesi sonrası kayıp**: `MY_PACKAGE_REPLACED` action'ı dinlenmiyor, uygulama güncellendiğinde alarmlar siliniyor.
3. **Agresif pil yönetimi**: Samsung, Xiaomi, Huawei gibi üreticiler arka plan süreçlerini öldürüyor, zamanlanmış alarmlar iptal ediliyor.
4. **Re-schedule mekanizması yok**: Kaybolan bildirimler için kurtarma mekanizması mevcut değil.

## Kapsam

- Android manifest düzeltmeleri (boot receiver)
- Uygulama açılışında re-schedule mekanizması (her iki platform)
- Pil optimizasyonu uyarı banner'ı (Android, paket eklemeden)
- Debug loglama iyileştirmesi
- iOS: Ek değişiklik gerekmez (mevcut yapı yeterli)

## Kapsam Dışı

- `workmanager` ile arka plan periyodik görev
- FCM/push notification entegrasyonu
- Veritabanı tabanlı bildirimlerin arka planda işlenmesi (NotificationProcessor)

## Yaklaşım: Boot Receiver + Uygulama Açılışında Re-schedule

### 1. Android Manifest Düzeltmeleri

`android/app/src/main/AndroidManifest.xml` dosyasına boot receiver eklenir:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

- `BOOT_COMPLETED`: Cihaz yeniden başlatıldığında zamanlanmış bildirimleri geri yükler
- `MY_PACKAGE_REPLACED`: Uygulama güncellendiğinde bildirimleri korur
- `QUICKBOOT_POWERON`: Samsung/HTC hızlı açılış desteği

Mevcut `SCHEDULE_EXACT_ALARM` izni ve `inexactAllowWhileIdle` fallback'i korunur.

### 2. Uygulama Açılışında Re-schedule Mekanizması

Yeni metod: `NotificationScheduler.rescheduleAll(String userId)`

**Akış:**
1. Uygulama açılışında `_initNotifications()` tamamlandıktan sonra çağrılır
2. Aktif entityleri DAO'lardan sorgular (offline-first, network gerektirmez):
   - Aktif kuluçkalar (devam eden breeding pair'lar)
   - Incubating durumundaki yumurtalar
   - Sütten kesilmemiş yavrular
   - Gelecekteki sağlık kontrol hatırlatmaları
3. Her entity için mevcut bildirimleri iptal edip yeniden planlar
4. Sadece gelecekteki bildirimleri planlar (geçmiş olanları atlar)

**Performans koruması:**
- Splash ekranını bloklamaz — `Future.microtask()` ile defer edilir
- Sadece aktif entityler sorgulanır (completed/cancelled atlanır)

**Çağrılma noktası:**
- `auth_providers.dart` → `_initNotifications()` sonrası, `Future.microtask()` içinde

**Veri kaynağı (DAO'lar):**
- `BreedingPairsDao` — aktif çiftleştirmeler
- `EggsDao` — incubating yumurtalar
- `ChicksDao` — sütten kesilmemiş yavrular
- `HealthRecordsDao` — gelecekteki kontroller

**Mevcut scheduler metodları kullanılır:**
- `scheduleEggTurningReminders()`
- `scheduleIncubationMilestones()`
- `scheduleChickCareReminders()`
- `scheduleHealthCheckReminders()`

### 3. Pil Optimizasyonu Uyarı Banner'ı

Paket eklemeden, bildirim ayarları ekranında bilgilendirici banner:

- **Konum**: Bildirim ayarları ekranının üstünde
- **Widget**: `InfoCard` (mevcut shared widget)
- **Metin**: Lokalize — "Bildirimlerin zamanında gelmesi için cihaz ayarlarından pil optimizasyonunu kapatın"
- **"Bir daha gösterme"**: `AppPreferences` ile persist
- **Platform**: Sadece Android'de gösterilir (`Platform.isAndroid`)

Yeni l10n key'leri:
- `notifications.battery_optimization_warning` — banner metni
- `notifications.battery_optimization_dismiss` — "Bir daha gösterme" butonu

### 4. Debug Loglama

Mevcut `AppLogger` pattern'ı takip ederek:

**Planlama anında:**
```dart
AppLogger.info('notifications', 'Scheduled: id=$id, title=$title, at=$scheduledDate');
```

**Re-schedule anında:**
```dart
AppLogger.info('notifications', 'Reschedule started for user $userId');
AppLogger.info('notifications', 'Reschedule complete: $count notifications for $entityCount entities');
```

**İptal anında:**
```dart
AppLogger.debug('notifications', 'Cancelling notifications for entity $entityId');
```

## Etkilenen Dosyalar

| Dosya | Değişiklik |
|-------|-----------|
| `android/app/src/main/AndroidManifest.xml` | Boot receiver ekleme |
| `lib/domain/services/notifications/notification_scheduler.dart` | `rescheduleAll()` metodu |
| `lib/domain/services/notifications/notification_service.dart` | Loglama iyileştirmesi |
| `lib/features/auth/providers/auth_providers.dart` | Re-schedule çağrısı |
| `lib/features/notifications/screens/notification_settings_screen.dart` | Pil uyarı banner'ı |
| `assets/translations/tr.json` | Yeni l10n key'leri |
| `assets/translations/en.json` | Yeni l10n key'leri |
| `assets/translations/de.json` | Yeni l10n key'leri |

## Test Stratejisi

- `rescheduleAll()` unit test: mock DAO'lar döndüğünde doğru scheduler metodları çağrılıyor mu
- Pil uyarı banner'ı widget test: Android'de gösteriliyor, iOS'ta gizli
- "Bir daha gösterme" widget test: tercihi persist ediyor
- Mevcut notification testleri kırılmıyor
