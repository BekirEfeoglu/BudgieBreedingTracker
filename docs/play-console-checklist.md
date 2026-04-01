# Google Play Console - Submission Checklist

Bu dokuman, uygulamayi Google Play Store'a gondermeden once Play Console'da
tamamlanmasi gereken beyanlari ve ayarlari icerir.

## 1. App Access (ZORUNLU)

**Konum:** App Content > App access

Uygulama login gerektirdigi icin "All or some functionality is restricted" secilmeli.

### Test Hesabi Bilgileri

```
Email: <see password manager / 1Password>
Password: <see password manager / 1Password>
Premium: Active (RevenueCat test entitlement)
2FA: Disabled (test hesabinda)
```

> **IMPORTANT:** Test credentials must NEVER be committed to the repository.
> Store them in a password manager and share via secure channels only.

### Test Hesabi Olusturma Adimlari
1. Supabase Dashboard > Authentication > Users > "Create user" ile olustur
2. RevenueCat Dashboard > Customers > test user'i bul > "Grant promotional entitlement" ile `budgie_premium` ver
3. Login test: uygulama uzerinden giris yap, premium ozelliklere erisimi dogrula
4. Gondermeden hemen once tekrar test et — hesap kilidini kontrol et

### Reviewer Notlari (App Review Notes)

```
Test credentials:
- Email: <see password manager>
- Password: <see password manager>
- Premium: Active (test entitlement enabled)
- 2FA: Disabled on test account

Core features to test:
1. Bird management (add/edit/delete birds)
2. Breeding pair tracking with egg/chick management
3. Egg & incubation monitoring with notification reminders
4. Genetics calculator (Punnett square for budgie mutations)
5. Statistics & charts (premium feature)
6. Backup/export (PDF, Excel)
7. Community feed (post, comment, like, bookmark)
8. Premium subscription flow (sandbox billing)

Note: SCHEDULE_EXACT_ALARM permission is used for incubation
reminder notifications — a core breeding tracking feature.
The app gracefully falls back to inexact alarms if denied.
```

### Dikkat Edilecekler
- Test hesabi GERCEKTEN calisir olmali (gondermeden once dogrula)
- Premium entitlement RevenueCat sandbox'ta aktif olmali
- Free-tier limitleri bypass edilmis olmali (reviewer tum ozellikleri gormeli)


## 2. Ads Declaration (ZORUNLU)

**Konum:** Store listing > App details

- [x] "Contains ads" = **Yes**

Uygulama Google Mobile Ads SDK (AdMob) kullaniyor:
- Banner reklamlar (ust/alt)
- Interstitial reklamlar (3 dakika cooldown)
- Rewarded reklamlar (premium ozelliklere gecici erisim)

Premium kullanicilar reklam gormez.


## 3. Data Safety Form (ZORUNLU)

**Konum:** App Content > Data safety

### Toplanan Veriler

| Veri Turu | Toplanir | Paylasilir | Amac |
|-----------|----------|------------|------|
| Email address | Evet | Hayir | Account management |
| Name / Username | Evet | Hayir | App functionality |
| Photos | Evet | Hayir | App functionality (bird/egg photos) |
| App interactions | Evet | Hayir | Analytics (Sentry crash reports) |
| Crash logs | Evet | Evet (Sentry) | App functionality / diagnostics |
| Device or other IDs | Evet | Evet (AdMob) | Advertising |
| Purchase history | Evet | Evet (RevenueCat) | App functionality |

### Guvenlik Uygulamalari
- [x] Data is encrypted in transit (HTTPS/TLS)
- [x] Selected sensitive fields encrypted at rest (AES-256-CBC: ring_number, genetic_info, pedigree_info)
- [ ] ⚠️ Full database encryption (sqlcipher) NOT implemented — SQLite DB is unencrypted
- [x] Users can request that their data is deleted
- [x] Data deletion request mechanism: In-app (Settings > Delete Account)

### Ucuncu Parti SDK'lar ve Veri Islemleri

**Google Mobile Ads (AdMob)**
- Toplar: Device identifiers, Ad interaction data
- Paylasilir: Google (reklam amaciyla)
- Amac: Advertising

**Sentry**
- Toplar: Crash logs, device info (OS, model), app version
- sendDefaultPii = false (PII toplanmaz)
- tracesSampleRate = 0.3 (production)
- Paylasilir: Sentry (hata takibi amaciyla)
- Amac: App diagnostics

**RevenueCat**
- Toplar: Purchase history, subscription status
- Paylasilir: RevenueCat (abonelik yonetimi amaciyla)
- Amac: App functionality

**Supabase**
- Toplar: User data (birds, eggs, chicks, photos, etc.)
- Paylasilmaz (birinci taraf backend)
- Amac: App functionality


## 4. Content Rating (ZORUNLU)

**Konum:** App Content > Content rating

IARC Questionnaire cevaplari:

| Soru | Cevap |
|------|-------|
| Does the app allow users to interact or exchange content? | **Yes** (community posts, comments) |
| Does the app share the user's current location? | **No** |
| Does the app contain violence? | **No** |
| Does the app contain sexual content? | **No** |
| Does the app contain substances? | **No** |
| Does the app contain gambling? | **No** |
| Does the app contain ads? | **Yes** |
| Does the app allow purchases? | **Yes** (premium subscription) |

Beklenen rating: **Everyone / PEGI 3 / USK 0**


## 5. Target Audience (ZORUNLU)

**Konum:** App Content > Target audience and content

- Hedef yas grubu: **13+** (kayit sirasinda 13+ onay checkbox'u var)
- Uygulama cocuklara hitap ETMEZ
- Families program'a basvuru GEREKMEZ

NOT: Yas onay mekanizmasi `register_screen.dart`'ta mevcut:
```
auth.age_confirm: "13 yasindan buyuk oldugunuzu onayliyorsunuz"
```


## 6. Permissions Declaration (ZORUNLU)

**Konum:** Policy and programs > Permissions declaration

### SCHEDULE_EXACT_ALARM Beyani

- Kullanim amaci: **Alarm/timer/reminder**
- Aciklama: "Incubation (kulucka) hatirlatma bildirimleri icin kesin
  zamanlama kullanilir. Muhabbet kusu yumurtalari 18 gunluk kulucka
  surecinde gunluk cevirme hatirlatmalari ve kulucka donumu bildirimleri
  gerektirir. Izin reddedilirse uygulama yaklasik zamanlama moduna
  otomatik olarak gecer."

### POST_NOTIFICATIONS (Android 13+)

- Runtime'da istenir (uygulamanin ana ekrani gosterdikten 3 saniye sonra)
- Reddedilirse bildirimler devre disi kalir, uygulama calismaya devam eder

### RECEIVE_BOOT_COMPLETED

- Kullanim amaci: Cihaz yeniden baslatildiktan sonra zamanlanmis bildirimlerin yeniden kaydedilmesi
- Kullanici aksiyonu gerektirmez (otomatik)


## 7. Privacy Policy URL (ZORUNLU)

**Konum:** Store listing > App details > Privacy policy

URL: `https://budgiebreedingtracker.online/privacy-policy.html`

Durum: Canli (HTTP 200 OK - dogrulanmis)


## 8. Store Listing Kontrol Listesi

**Konum:** Store listing

- [ ] Uygulama adi: Max 30 karakter, yaniltici olmamali
- [ ] Kisa aciklama: Max 80 karakter, ucretsiz/premium ayrimi net
- [ ] Tam aciklama: Max 4000 karakter, tum ozellikler dogru yansimali
- [ ] "Community" ozelligi aciklamada varsa, gercekten calisiyor (EVET - aktif)
- [ ] Ekran goruntuleri gercek uygulamayi yansitiyor
- [ ] Feature graphic yuklu
- [ ] Kategori dogru secilmis (Tools / Lifestyle)
- [ ] Iletisim emaili ekli


## 9. Beyan Ozet Tablosu

| Beyan | Durum | Aksiyon |
|-------|-------|---------|
| App Access | EKSIK | Test hesabi olustur ve gir |
| Ads declaration | EKSIK | "Contains ads" = Yes isaretle |
| Data Safety | EKSIK | Yukaridaki tabloyu kullanarak doldur |
| Content Rating | EKSIK | IARC questionnaire'i tamamla |
| Target audience | EKSIK | 13+ sec |
| Permissions | EKSIK | SCHEDULE_EXACT_ALARM + RECEIVE_BOOT_COMPLETED beyan et |
| Privacy Policy | KONTROL ET | URL girildi mi dogrula |
| News declaration | GEREKMEZ | Haber uygulamasi degil |
| Financial features | GEREKMEZ | Finansal uygulama degil |
| Health apps | GEREKMEZ | Saglik uygulamasi degil |
| Government apps | GEREKMEZ | Devlet uygulamasi degil |


## 10. Gonderim Oncesi Son Kontroller

- [ ] Test hesabi calisiyor (login + premium erisim)
- [ ] Hesap silme akisi end-to-end calisiyor
- [ ] Tum deep linkler dogru calisiyor
- [ ] Pre-launch report crash/ANR oranlarini kontrol et
- [ ] Release build'de debug/test izi yok
- [ ] ProGuard/R8 mapping dosyasi yuklendi (Play Console > App bundle explorer)
  - `flutter build appbundle` sonrasi `build/app/outputs/mapping/release/mapping.txt` olusur
  - Play Console > App bundle explorer > Downloads > "ReTrace mapping file" ile yukle
- [ ] Imza anahtari Google Play App Signing ile eslestirildi
  - Ilk upload'da Play Console otomatik signing key olusturur
  - `android/app/build.gradle` release signingConfig dogru ayarli olmali
  - `key.properties` dosyasi `.gitignore`'da olmali (COMMIT ETME)
