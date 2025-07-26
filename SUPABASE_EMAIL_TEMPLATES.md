# 📧 Supabase Email Template'leri

Ionos.com domain'iniz için özelleştirilmiş email template'leri.

## 🎯 Email Template'leri

### 1. Email Onaylama Template'i

**Template Adı**: `Confirm signup`

**HTML İçeriği**:
```html
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Email Onaylama</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background-color: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            width: 80px;
            height: 80px;
            background-color: #3b82f6;
            border-radius: 50%;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 24px;
            font-weight: bold;
        }
        .title {
            color: #1f2937;
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #6b7280;
            font-size: 16px;
        }
        .content {
            margin-bottom: 30px;
        }
        .button {
            display: inline-block;
            background-color: #3b82f6;
            color: white;
            text-decoration: none;
            padding: 14px 28px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            margin: 20px 0;
            transition: background-color 0.3s;
        }
        .button:hover {
            background-color: #2563eb;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            color: #6b7280;
            font-size: 14px;
        }
        .warning {
            background-color: #fef3c7;
            border: 1px solid #f59e0b;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
            color: #92400e;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🐦</div>
            <h1 class="title">BudgieBreedingTracker</h1>
            <p class="subtitle">Email Adresinizi Onaylayın</p>
        </div>
        
        <div class="content">
            <p>Merhaba!</p>
            
            <p>BudgieBreedingTracker hesabınızı oluşturduğunuz için teşekkür ederiz. Hesabınızı aktifleştirmek için aşağıdaki butona tıklayın:</p>
            
            <div style="text-align: center;">
                <a href="{{ .ConfirmationURL }}" class="button">
                    Email Adresimi Onayla
                </a>
            </div>
            
            <div class="warning">
                <strong>⚠️ Önemli:</strong> Bu link 24 saat geçerlidir. Süre dolduktan sonra yeni bir onaylama linki talep etmeniz gerekecektir.
            </div>
            
            <p>Eğer bu hesabı siz oluşturmadıysanız, bu emaili görmezden gelebilirsiniz.</p>
        </div>
        
        <div class="footer">
            <p>Bu email otomatik olarak gönderilmiştir. Lütfen yanıtlamayın.</p>
            <p>© 2024 BudgieBreedingTracker. Tüm hakları saklıdır.</p>
        </div>
    </div>
</body>
</html>
```

**Text İçeriği**:
```
BudgieBreedingTracker - Email Onaylama

Merhaba!

BudgieBreedingTracker hesabınızı oluşturduğunuz için teşekkür ederiz. 
Hesabınızı aktifleştirmek için aşağıdaki linke tıklayın:

{{ .ConfirmationURL }}

⚠️ ÖNEMLİ: Bu link 24 saat geçerlidir.

Eğer bu hesabı siz oluşturmadıysanız, bu emaili görmezden gelebilirsiniz.

© 2024 BudgieBreedingTracker
```

### 2. Magic Link Template'i

**Template Adı**: `Magic Link`

**HTML İçeriği**:
```html
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Giriş Linki</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background-color: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            width: 80px;
            height: 80px;
            background-color: #10b981;
            border-radius: 50%;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 24px;
            font-weight: bold;
        }
        .title {
            color: #1f2937;
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #6b7280;
            font-size: 16px;
        }
        .content {
            margin-bottom: 30px;
        }
        .button {
            display: inline-block;
            background-color: #10b981;
            color: white;
            text-decoration: none;
            padding: 14px 28px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            margin: 20px 0;
            transition: background-color 0.3s;
        }
        .button:hover {
            background-color: #059669;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            color: #6b7280;
            font-size: 14px;
        }
        .warning {
            background-color: #fef3c7;
            border: 1px solid #f59e0b;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
            color: #92400e;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🔐</div>
            <h1 class="title">BudgieBreedingTracker</h1>
            <p class="subtitle">Güvenli Giriş Linki</p>
        </div>
        
        <div class="content">
            <p>Merhaba!</p>
            
            <p>BudgieBreedingTracker hesabınıza giriş yapmak için aşağıdaki güvenli linke tıklayın:</p>
            
            <div style="text-align: center;">
                <a href="{{ .ConfirmationURL }}" class="button">
                    Giriş Yap
                </a>
            </div>
            
            <div class="warning">
                <strong>⚠️ Güvenlik:</strong> Bu link 1 saat geçerlidir ve sadece bir kez kullanılabilir.
            </div>
            
            <p>Eğer bu giriş isteğini siz yapmadıysanız, bu emaili görmezden gelebilirsiniz.</p>
        </div>
        
        <div class="footer">
            <p>Bu email otomatik olarak gönderilmiştir. Lütfen yanıtlamayın.</p>
            <p>© 2024 BudgieBreedingTracker. Tüm hakları saklıdır.</p>
        </div>
    </div>
</body>
</html>
```

**Text İçeriği**:
```
BudgieBreedingTracker - Güvenli Giriş Linki

Merhaba!

BudgieBreedingTracker hesabınıza giriş yapmak için aşağıdaki güvenli linke tıklayın:

{{ .ConfirmationURL }}

⚠️ GÜVENLİK: Bu link 1 saat geçerlidir ve sadece bir kez kullanılabilir.

Eğer bu giriş isteğini siz yapmadıysanız, bu emaili görmezden gelebilirsiniz.

© 2024 BudgieBreedingTracker
```

### 3. Şifre Sıfırlama Template'i

**Template Adı**: `Reset password`

**HTML İçeriği**:
```html
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Şifre Sıfırlama</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f8fafc;
        }
        .container {
            background-color: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            width: 80px;
            height: 80px;
            background-color: #ef4444;
            border-radius: 50%;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 24px;
            font-weight: bold;
        }
        .title {
            color: #1f2937;
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #6b7280;
            font-size: 16px;
        }
        .content {
            margin-bottom: 30px;
        }
        .button {
            display: inline-block;
            background-color: #ef4444;
            color: white;
            text-decoration: none;
            padding: 14px 28px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 16px;
            text-align: center;
            margin: 20px 0;
            transition: background-color 0.3s;
        }
        .button:hover {
            background-color: #dc2626;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            color: #6b7280;
            font-size: 14px;
        }
        .warning {
            background-color: #fef3c7;
            border: 1px solid #f59e0b;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
            color: #92400e;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🔒</div>
            <h1 class="title">BudgieBreedingTracker</h1>
            <p class="subtitle">Şifre Sıfırlama</p>
        </div>
        
        <div class="content">
            <p>Merhaba!</p>
            
            <p>BudgieBreedingTracker hesabınız için şifre sıfırlama talebinde bulundunuz. Yeni şifrenizi belirlemek için aşağıdaki linke tıklayın:</p>
            
            <div style="text-align: center;">
                <a href="{{ .ConfirmationURL }}" class="button">
                    Şifremi Sıfırla
                </a>
            </div>
            
            <div class="warning">
                <strong>⚠️ Güvenlik:</strong> Bu link 1 saat geçerlidir. Eğer şifre sıfırlama talebinde bulunmadıysanız, bu emaili görmezden gelebilirsiniz.
            </div>
            
            <p>Yeni şifrenizi belirledikten sonra eski şifreniz artık geçerli olmayacaktır.</p>
        </div>
        
        <div class="footer">
            <p>Bu email otomatik olarak gönderilmiştir. Lütfen yanıtlamayın.</p>
            <p>© 2024 BudgieBreedingTracker. Tüm hakları saklıdır.</p>
        </div>
    </div>
</body>
</html>
```

**Text İçeriği**:
```
BudgieBreedingTracker - Şifre Sıfırlama

Merhaba!

BudgieBreedingTracker hesabınız için şifre sıfırlama talebinde bulundunuz. 
Yeni şifrenizi belirlemek için aşağıdaki linke tıklayın:

{{ .ConfirmationURL }}

⚠️ GÜVENLİK: Bu link 1 saat geçerlidir.

Eğer şifre sıfırlama talebinde bulunmadıysanız, bu emaili görmezden gelebilirsiniz.

© 2024 BudgieBreedingTracker
```

## ⚙️ Kurulum Adımları

### 1. Supabase Dashboard'da Template'leri Ayarlayın

1. [Supabase Dashboard](https://supabase.com/dashboard)'a gidin
2. `etkvuonkmmzihsjwbcrl` projenizi seçin
3. **Authentication** > **Email Templates** bölümüne gidin
4. Her template için yukarıdaki HTML ve Text içeriklerini kopyalayın

### 2. Template Ayarları

**Confirm signup**:
- HTML: Email onaylama HTML içeriği
- Text: Email onaylama Text içeriği

**Magic Link**:
- HTML: Magic link HTML içeriği
- Text: Magic link Text içeriği

**Reset password**:
- HTML: Şifre sıfırlama HTML içeriği
- Text: Şifre sıfırlama Text içeriği

### 3. Test Etme

1. Yeni bir kullanıcı kaydı yapın
2. Email adresinize gelen onaylama emailini kontrol edin
3. Email'in tasarımını ve linklerin çalıştığını doğrulayın

## 🎨 Özelleştirme

### Renk Teması Değiştirme

Template'lerdeki renk kodlarını değiştirerek markanıza uygun hale getirebilirsiniz:

- **Mavi tema**: `#3b82f6` (Email onaylama)
- **Yeşil tema**: `#10b981` (Magic link)
- **Kırmızı tema**: `#ef4444` (Şifre sıfırlama)

### Logo Değiştirme

Logo bölümündeki emoji'yi kendi logonuzla değiştirebilirsiniz:

```html
<div class="logo">
    <img src="https://your-domain.com/logo.png" alt="Logo" style="width: 60px; height: 60px;">
</div>
```

### Domain Adı Değiştirme

Template'lerdeki "BudgieBreedingTracker" metnini kendi domain adınızla değiştirin.

## ✅ Kontrol Listesi

- [ ] Email template'leri Supabase Dashboard'a eklendi
- [ ] HTML ve Text içerikleri doğru kopyalandı
- [ ] Test email gönderildi
- [ ] Email tasarımı kontrol edildi
- [ ] Linkler doğru çalışıyor
- [ ] Custom domain yönlendirmesi çalışıyor

---

**💡 İpucu**: Template'leri test etmek için önce kendi email adresinizle kayıt olun! 