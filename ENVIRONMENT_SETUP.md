# Environment Variables Kurulum Rehberi

## Gerekli Environment Variables

### 1. Supabase Configuration
```bash
# .env.local dosyasına ekleyin
NEXT_PUBLIC_SUPABASE_URL=https://jxbfdgyusoehqybxdnii.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4YmZkZ3l1c29laHF5YnhkbmlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMjY5NTksImV4cCI6MjA2NjgwMjk1OX0.aBMXWV0yeW8cunOtrKGGakLv_7yZi1vbV1Q1fXsJJeg
```

### 2. Email Configuration (Opsiyonel)
```bash
# Gmail SMTP için
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Resend API (Alternatif)
RESEND_API_KEY=re_your-resend-api-key
```

### 3. Development Settings
```bash
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 4. Security Settings
```bash
NEXT_PUBLIC_ENABLE_DEBUG=false
NEXT_PUBLIC_ENABLE_ANALYTICS=false
```

### 5. Backup Settings
```bash
NEXT_PUBLIC_BACKUP_ENABLED=true
NEXT_PUBLIC_BACKUP_FREQUENCY_HOURS=24
```

### 6. Notification Settings
```bash
NEXT_PUBLIC_PUSH_NOTIFICATIONS_ENABLED=true
NEXT_PUBLIC_EMAIL_NOTIFICATIONS_ENABLED=true
```

## Güvenlik Notları

### 1. Environment Variables Güvenliği
- `.env.local` dosyasını asla git'e commit etmeyin
- Production'da environment variables'ları güvenli şekilde ayarlayın
- API key'leri düzenli olarak rotate edin

### 2. SMTP Güvenliği
- Gmail için App Password kullanın (normal şifre değil)
- SMTP bilgilerini environment variables'da saklayın
- Production'da güvenli SMTP servisleri kullanın

### 3. Supabase Güvenliği
- Anon key'i public olabilir ama service role key'i asla public etmeyin
- RLS (Row Level Security) politikalarını aktif tutun
- Database şifreleme kullanın

## Kurulum Adımları

### 1. Local Development
```bash
# Proje klasöründe .env.local dosyası oluşturun
cp .env.example .env.local

# Gerekli değerleri düzenleyin
nano .env.local
```

### 2. Production Deployment
```bash
# Vercel için
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY

# Netlify için
netlify env:set NEXT_PUBLIC_SUPABASE_URL "your-url"
netlify env:set NEXT_PUBLIC_SUPABASE_ANON_KEY "your-key"
```

### 3. Supabase Edge Functions
```bash
# Supabase Dashboard'da environment variables ayarlayın
supabase secrets set SMTP_HOST=smtp.gmail.com
supabase secrets set SMTP_PORT=587
supabase secrets set SMTP_USERNAME=your-email@gmail.com
supabase secrets set SMTP_PASSWORD=your-app-password
```

## Sorun Giderme

### Environment Variables Yüklenmiyor
```bash
# Next.js development server'ı yeniden başlatın
npm run dev

# Cache'i temizleyin
rm -rf .next
npm run dev
```

### SMTP Bağlantı Sorunları
```bash
# Gmail App Password oluşturun
# 1. Google Account Settings > Security
# 2. 2-Step Verification > App passwords
# 3. Generate new app password
```

### Supabase Bağlantı Sorunları
```bash
# Supabase status kontrolü
npx supabase status

# Connection test
curl https://jxbfdgyusoehqybxdnii.supabase.co/rest/v1/
``` 