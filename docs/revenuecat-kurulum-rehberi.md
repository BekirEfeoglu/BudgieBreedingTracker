# RevenueCat ve Mağaza Kurulum Rehberi

Merhaba! Apple App Store ve Google Play Console panellerine doğrudan müdahale yetkim (giriş şifreleriniz) olmadığı için bu ayarları sizin adınıza otomatik olarak ekleyemiyorum.

Fakat, `premium-pricing-table.md` dosyasında belirlediğiniz kurallara göre kopyala-yapıştır yaparak **10 dakikada** tüm ayarları tamamlayabileceğiniz bu rehberi hazırladım. Adımları sırasıyla takip ederseniz RevenueCat kurulumunuz eksiksiz çalışacaktır.

Uygulamanızın Flutter kodlarını inceledim. Kod tarafında (`lib/domain/services/payment/purchase_service.dart`) RevenueCat ayarlarınız **tamamen doğru yapılandırılmış durumda** (`premium` entitlement, ve standart paket yapıları kodlanmış). Yalnızca panelden bu eşleştirmeleri yapmanız yeterli.

---

## 1. Google Play Console Ayarları

Google Play'de abonelikler bir "Ana Ürün" (Product) altında "Temel Planlar" (Base Plans) olarak oluşturulur. `Lifetime` ise tek seferlik satın alımlarda (In-App Products) yer alır.

### A. Abonelikler (Aylık & Yıllık)
1. Play Console'da uygulamanızı seçin. Soldaki menüden **Kazanma (Monetize) > Ürünler > Abonelikler (Subscriptions)** sayfasına gidin.
2. **Abonelik oluştur (Create subscription)** butonuna tıklayın.
    - **Ürün Kimliği (Product ID):** `budgie_premium`
    - **Ad:** `Budgie Premium`
3. Ürünü kaydettikten sonra içine girin ve aşağıdan **Temel plan ekle (Add base plan)** deyin:
    - **Aylık Plan İçin:**
        - **Temel plan kimliği:** `monthly`
        - **Tür:** `Otomatik yenilenen (Auto-renewing)`
        - **Fiyatlandırma (Türkiye):** `129.99 TRY`
        - **Fiyatlandırma (ABD/Global):** `4.99 USD`
    - **Yıllık Plan İçin:**
        - **Temel plan kimliği:** `yearly`
        - **Tür:** `Otomatik yenilenen (Auto-renewing)`
        - **Fiyatlandırma (Türkiye):** `799.99 TRY`
        - **Fiyatlandırma (ABD/Global):** `34.99 USD`
4. **(ÖNEMLİ) Yıllık Plana Free Trial Ekleme:**
    - Yıllık temel plan (`yearly`) oluştuktan sonra yanındaki ok işaretine basıp içine girin.
    - **Teklif ekle (Add offer)** seçeneğine tıklayın.
    - **Teklif Kimliği:** `7_days_trial`
    - **Faz (Phases):** Ücretsiz deneme (Free trial) seçeneğini işaretleyin ve `7 Gün` olarak ayarlayın.

### B. Tek Seferlik Ürün (Lifetime)
1. Soldaki menüden **Uygulama İçi Ürünler (In-app products)** sayfasına gidin.
2. **Ürün Oluştur (Create product)** butonuna tıklayın.
    - **Ürün Kimliği:** `budgie_premium_lifetime`
    - **Ad:** `Budgie Premium Lifetime`
    - **Fiyat (TRY):** `1999.99 TRY`
    - **Fiyat (USD):** `89.99 USD`
3. Kaydedin ve **Etkinleştir** (Activate) butonuna basmayı unutmayın.

---

## 2. Apple App Store Connect Ayarları

Apple tarafında her ürün ayrı bir (Auto-renewable veya Non-consumable) ürün olarak yaratılır. Aylık ve yıllık plan aynı Abonelik Grubu'nda (Subscription Group) bulunmalıdır.

### A. Abonelikler (Aylık & Yıllık)
1. App Store Connect'te uygulamanıza girin. Soldan **Abonelikler (Subscriptions)** menüsüne tıklayın.
2. İlk olarak **Abonelik Grubu (Subscription Group)** oluşturun:
    - **Ad:** `Premium` (veya `Budgie Premium`)
3. Grubun içine girip ilk ürünü ekleyin:
    - **Aylık Plan İçin:**
        - **Reference Name:** `Premium Monthly`
        - **Product ID:** `budgie_premium_monthly`
        - **Süre (Duration):** 1 Ay
        - **Fiyat:** $4.99 (Türkiye için Tier'ı seçerseniz 129.99 TRY'ye denk gelen fiyat kademesini seçin).
4. Grupta ikinci ürünü ekleyin:
    - **Yıllık Plan İçin:**
        - **Reference Name:** `Premium Yearly`
        - **Product ID:** `budgie_premium_yearly`
        - **Süre (Duration):** 1 Yıl
        - **Fiyat:** $34.99 (TRY karşılığı 799.99 olan tier)
    - **(ÖNEMLİ) Free Trial:** Yıllık planın ayarlarına girip "Introductory Offers" (Tanıtım Teklifleri) altından **Free Trial (Ücretsiz Deneme) > 7 Gün** seçeneğini ekleyin.

### B. Tek Seferlik Ürün (Lifetime)
1. Soldaki menüden **Uygulama İçi Satın Alımlar (In-App Purchases)** sayfasına gidin.
2. **Yeni Ekle (+) > Tüketilmeyen (Non-Consumable)** seçeneğini işaretleyin.
    - **Reference Name:** `Premium Lifetime`
    - **Product ID:** `budgie_premium_lifetime`
    - **Fiyat:** $89.99 (TRY karşılığı 1999.99 tier)
3. Kaydedin. Eksik uyarılarını (örnek bir ekran görüntüsü yükleme vs.) doldurup ürünü "Review" (İnceleme) aşaması için hazır bırakın.

---

## 3. RevenueCat Ayarları

Mağazalarda ürünler oluştuktan sonra, onları RevenueCat üzerinde eşleştirmeliyiz. Böylece uygulamanızdaki `purchaseService` sorunsuz çalışacaktır.

### A. Uygulama Anahtarlarını (API Keys) Girme
1. Uygulamanızın `.env` dosyasına gidin (Mevcutsa).
2. RevenueCat dashboard'da **API Keys** kısmında yer alan `App Store (iOS)` ve `Play Store (Android)` Public API anahtarlarını `.env` içine şu şekilde yapıştırın (Zaten projenizde bu ayarlar destekleniyor):
   ```env
   REVENUECAT_API_KEY_IOS=appl_xxxxx...
   REVENUECAT_API_KEY_ANDROID=goog_xxxxx...
   ```

### B. Ürünleri (Products) Tanımlama
1. RevenueCat panelinde **Project Settings > Products** sayfasına gidin.
2. **New > Import Products** (veya elle) ekleme yapın:
    - **iOS:** Tek tek şu üç değeri ekleyin: `budgie_premium_monthly`, `budgie_premium_yearly`, `budgie_premium_lifetime`
    - **Android:** Şekli çok önemlidir! RevenueCat Android aboneliklerini `urun:plan` şeklinde algılar.
      - Aylık: `budgie_premium:monthly`
      - Yıllık: `budgie_premium:yearly`
      - Ömür Boyu (Abonelik olmadığı için iki nokta yok): `budgie_premium_lifetime`

### C. Hak (Entitlements) Oluşturma
Burası flutter kodunun (`_entitlementId`) kontrol ettiği yerdir.
1. Soldan **Entitlements** menüsüne gidin.
2. **New** deyin ve **Identifier (Kimlik)** olarak tam olarak şu kelimeyi girin:
    - `premium`
3. Description kısmına `Premium Access` yazabilirsiniz.

### D. Paketler ve Teklifler (Offerings) Eklemek
Burada `premium` havuzunun içine seçenekleri (Aylık, Yıllık, vs.) yerleştireceğiz.
1. Soldan **Offerings** menüsüne gidin.
2. **New** deyin ve **Identifier** olarak şunu girin:
    - `default` (Tanım: Default Offering)
3. Oluşturduğunuz `default` adlı teklifin içine girip üç adet paket ekleyeceğiz:
    - **1. Paket:**
        - **Identifier:** `$rc_monthly` (Monthly)
        - **Bağlanacak Ürünler:** Hem iOS `budgie_premium_monthly` kousunu hem de Android `budgie_premium:monthly` ürünlerini bu pakete ekleyin.
    - **2. Paket:**
        - **Identifier:** `$rc_annual` (Annual)
        - **Bağlanacak Ürünler:** iOS `budgie_premium_yearly` ve Android `budgie_premium:yearly` ekleyin.
    - **3. Paket:**
        - **Identifier:** `$rc_lifetime` (Lifetime)
        - **Bağlanacak Ürünler:** iOS `budgie_premium_lifetime` ve Android `budgie_premium_lifetime` ekleyin.

Tebrikler! Kodunuz zaten yazılmış olduğu için yukarıdaki eşleştirmeleri yaptığınızda ve API anahtarlarınızı uygulamanıza tanımladığınızda sistem otomatik olarak çalışmaya başlayacaktır.
