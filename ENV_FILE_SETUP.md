# 🔧 Manuel Environment Dosyası Kurulumu

Environment variables hala yüklenmiyor. Manuel olarak dosyayı oluşturalım.

## 📁 Adım 1: Dosyayı Manuel Olarak Oluşturun

### Windows'ta:
1. **File Explorer'ı açın**
2. **Proje dizinine gidin**: `C:\Users\Bekir\Documents\BudgieBreedingTracker`
3. **Yeni metin dosyası oluşturun**
4. **Adını değiştirin**: `.env.local` (uzantısız)
5. **"Dosya uzantılarını göster" seçeneğini açın** (View > File name extensions)

### Alternatif Yöntem:
1. **Notepad'i açın**
2. **Aşağıdaki içeriği kopyalayın**
3. **Farklı Kaydet** > **Dosya adı**: `.env.local` > **Dosya türü**: Tüm Dosyalar (*.*)
4. **Proje dizinine kaydedin**

## 📝 Adım 2: Dosya İçeriği

`.env.local` dosyasına şu içeriği ekleyin:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhsanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE

# Custom Domain (Ionos.com)
VITE_APP_URL=https://www.budgiebreedingtracker.com

# Development Settings
VITE_APP_ENV=development
VITE_DEBUG_MODE=true
```

## 🔍 Adım 3: Dosya Kontrolü

### PowerShell'de kontrol edin:
```powershell
Get-Content .env.local
```

### Dosya yapısı şöyle olmalı:
```
BudgieBreedingTracker/
├── package.json
├── .env.local          ← Bu dosya burada olmalı
├── src/
├── public/
└── ...
```

## 🚀 Adım 4: Development Server'ı Yeniden Başlatın

### 1. Mevcut server'ı durdurun:
```bash
# Terminal'de Ctrl+C
```

### 2. Cache'i temizleyin:
```bash
Remove-Item -Recurse -Force node_modules\.vite -ErrorAction SilentlyContinue
```

### 3. Yeniden başlatın:
```bash
npm run dev -- --force
```

## 🧪 Adım 5: Test Edin

### Console'da göreceğiniz loglar:
```
🔑 Supabase URL: https://etkvuonkmmzihsjwbcrl.supabase.co
🔑 Supabase Key Length: 151
🔑 Supabase Key Starts With: eyJhbGciOiJIUzI1NiIs
🔑 Environment Variables: {
  VITE_SUPABASE_URL: "https://etkvuonkmmzihsjwbcrl.supabase.co",
  VITE_SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhsanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE",
  MODE: "development",
  DEV: true,
  PROD: false
}
```

## 🔧 Alternatif Çözümler

### 1. .env Dosyası Deneyin
Eğer `.env.local` çalışmazsa, `.env` dosyası oluşturun:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhsanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE
```

### 2. Hardcode Deneyin
Geçici olarak client.ts'de hardcode edin:

```typescript
const SUPABASE_URL = "https://etkvuonkmmzihsjwbcrl.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhsanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE";
```

## 🚨 Yaygın Sorunlar

### 1. Dosya Adı Yanlış
```
.env.local (doğru)
.env_local (yanlış)
.envlocal (yanlış)
.env.local.txt (yanlış)
```

### 2. Dosya Konumu Yanlış
```
✅ BudgieBreedingTracker/.env.local
❌ BudgieBreedingTracker/src/.env.local
❌ BudgieBreedingTracker/public/.env.local
```

### 3. Encoding Sorunu
- Dosyayı UTF-8 encoding ile kaydedin
- BOM (Byte Order Mark) olmamalı

### 4. Git Ignore Sorunu
`.gitignore` dosyasında `.env.local` olmalı:

```gitignore
# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
```

## 📞 Vite Destek

Eğer sorun devam ederse:

1. **Vite Documentation**: https://vitejs.dev/guide/env-and-mode.html
2. **Environment Variables**: https://vitejs.dev/guide/env-and-mode.html#env-files
3. **Troubleshooting**: https://vitejs.dev/guide/troubleshooting.html

---

**💡 İpucu**: Environment variables değişiklikleri sadece development server yeniden başlatıldıktan sonra etkili olur!

**🎯 Hedef**: Environment variables yüklendikten sonra "Invalid API key" hatası almayacaksınız. 