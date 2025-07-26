# Docker Kurulum Rehberi

## Windows için Docker Desktop Kurulumu

### 1. Docker Desktop İndirme
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) adresinden indirin
- Windows 10/11 için WSL 2 backend gerekli

### 2. WSL 2 Kurulumu (Gerekirse)
```powershell
# PowerShell'i yönetici olarak çalıştırın
wsl --install
```

### 3. Docker Desktop Kurulumu
1. İndirilen .exe dosyasını çalıştırın
2. Kurulum tamamlandıktan sonra bilgisayarı yeniden başlatın
3. Docker Desktop'ı başlatın

### 4. Kurulum Doğrulama
```powershell
docker --version
docker-compose --version
```

### 5. Supabase CLI Kurulumu (Güncellenmiş)

#### ⚠️ ÖNEMLİ: npm ile global kurulum desteklenmiyor!

**Hatalı Yöntem (Kullanmayın):**
```powershell
npm install -g supabase  # ❌ Bu çalışmaz!
```

**Doğru Yöntemler:**

#### A. PowerShell ile Kurulum (Önerilen)
```powershell
# PowerShell'i yönetici olarak çalıştırın
winget install Supabase.CLI
```

#### B. Scoop ile Kurulum
```powershell
# Önce Scoop'u kurun (yoksa)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Sonra Supabase CLI'ı kurun
scoop install supabase
```

#### C. Chocolatey ile Kurulum
```powershell
# Önce Chocolatey'yi kurun (yoksa)
# https://chocolatey.org/install adresinden kurulum yapın

# Sonra Supabase CLI'ı kurun
choco install supabase
```

#### D. Manuel Kurulum
```powershell
# GitHub'dan en son sürümü indirin
# https://github.com/supabase/cli/releases

# İndirilen .exe dosyasını PATH'e ekleyin
```

### 6. Supabase CLI Doğrulama
```powershell
supabase --version
```

### 7. Supabase Projesini Başlatma
```powershell
cd BudgieBreedingTracker
supabase start
```

## Sorun Giderme

### Docker Desktop Başlamıyor
- Windows Hyper-V özelliğini etkinleştirin
- BIOS'ta virtualization'ı etkinleştirin

### WSL 2 Sorunları
```powershell
wsl --update
wsl --shutdown
wsl --start
```

### Supabase CLI Kurulum Sorunları

#### npm Hatası Alırsanız
```powershell
# npm cache'ini temizleyin
npm cache clean --force

# Global npm modüllerini temizleyin
npm uninstall -g supabase

# Yukarıdaki doğru yöntemlerden birini kullanın
```

#### Permission Hatası
```powershell
# PowerShell'i yönetici olarak çalıştırın
# Execution Policy'yi ayarlayın
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### PATH Sorunu
```powershell
# PATH'e manuel ekleme
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages"
```

## Güvenlik Notları
- Docker Desktop'ı sadece geliştirme sırasında çalıştırın
- Production'da Supabase Cloud kullanın
- Supabase CLI'ı güvenilir kaynaklardan indirin

## Alternatif Yöntemler

### Supabase Cloud Kullanımı (Docker Gerektirmez)
```powershell
# Supabase Cloud Dashboard'da proje oluşturun
# https://supabase.com/dashboard

# Sadece client tarafı için gerekli
npm install @supabase/supabase-js
```

### Npx ile Geçici Kullanım
```powershell
# Her seferinde npx kullanın (yavaş ama çalışır)
npx supabase@latest start
npx supabase@latest status
``` 