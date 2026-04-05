# Push Notifications Setup

Bu proje artık gerçek push hattısı için istemci ve Edge Function iskeleti içeriyor. Canlı çalışması için aşağıdaki adımlar gerekir.

## 1. Firebase Projesi

- Firebase Console'da Android ve iOS app kayıtlarını oluşturun.
- Cloud Messaging'i etkinleştirin.
- Android için `google-services.json` dosyasını `android/app/google-services.json` altına koyun.
- iOS için `GoogleService-Info.plist` dosyasını Xcode Runner target'ına ekleyin.

## 2. iOS

- Apple Developer hesabında Push Notifications capability açın.
- APNs Auth Key üretin ve Firebase Console'a yükleyin.
- Xcode içinde Runner target için `Push Notifications` ve `Background Modes > Remote notifications` açık olmalı.

## 3. Android

- `android/app/google-services.json` mevcut olduğunda Gradle otomatik olarak `com.google.gms.google-services` plugin'ini uygular.
- Android 13+ için bildirim runtime izni uygulamada zaten isteniyor.
- Tam zamanlı teslimat için kullanıcıdan pil optimizasyonunu kapatması istenebilir.

## 4. Supabase Secrets

`send-push` Edge Function için şu secret'ları tanımlayın:

- `FIREBASE_PROJECT_ID`
- `GOOGLE_SERVICE_ACCOUNT_JSON`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Örnek:

```bash
supabase secrets set FIREBASE_PROJECT_ID=your-project-id
supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON="$(cat service-account.json)"
```

## 5. Deploy

```bash
supabase functions deploy send-push
```

## 6. Beklenen Mesaj Veri Alanları

Push mesajı şu alanları taşımalıdır:

- `payload`: `type:id` formatında derin link
- veya `type` + `entity_id`

Örnek:

```json
{
  "title": "Yeni sağlık kontrolü",
  "body": "Yarın için bir kayıt var",
  "payload": "health_check:record-123"
}
```

## Not

Firebase yapılandırma dosyaları olmadan uygulama derlenebilir, ancak push servisi log üretip devre dışı kalır. Bu bilinçli davranıştır.
