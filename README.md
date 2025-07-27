# 🐦 BudgieBreedingTracker

Modern muhabbet kuşu üretim takip uygulaması. Kuluçka, yumurta, yavru ve soy ağacı takibini kolaylaştıran kapsamlı bir platform.

[![React](https://img.shields.io/badge/React-18.3.1-blue.svg)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.5.3-blue.svg)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-5.4.1-purple.svg)](https://vitejs.dev/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4.11-38B2AC.svg)](https://tailwindcss.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Teknolojiler](#-teknolojiler)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Geliştirme](#-geliştirme)
- [Deployment](#-deployment)
- [Katkıda Bulunma](#-katkıda-bulunma)
- [Lisans](#-lisans)

## ✨ Özellikler

### 🐦 Kuş Yönetimi
- Muhabbet kuşlarının detaylı profil takibi
- Renk, cinsiyet ve genetik bilgileri
- Fotoğraf ve belge yükleme desteği
- QR kod ile hızlı tanımlama

### 🥚 Kuluçka Takibi
- Yumurta ve kuluçka süreçlerinin yönetimi
- Otomatik tarih hesaplamaları
- Kuluçka başarı oranı takibi
- Detaylı notlar ve gözlemler

### 🐤 Yavru Takibi
- Yavru kuşların büyüme süreçleri
- Ağırlık ve gelişim grafikleri
- Sağlık kayıtları ve aşı takibi
- Ebeveyn bilgileri ve genetik geçmiş

### 🌳 Soy Ağacı
- İnteraktif aile ağacı görünümü
- Genetik geçmiş ve özellik takibi
- Akrabalık ilişkileri analizi
- PDF raporu oluşturma

### 📊 İstatistikler ve Raporlama
- Detaylı üretim istatistikleri
- Başarı oranları ve trendler
- Excel/PDF formatında raporlar
- Grafik ve tablo görünümleri

### 🔔 Bildirimler
- Önemli olaylar için anlık bildirimler
- Kuluçka ve yavru takip hatırlatıcıları
- Sağlık kontrolü hatırlatmaları

### 📱 Mobil Uyumluluk
- Responsive tasarım
- Capacitor ile native mobil uygulama
- Offline çalışma desteği
- Touch-friendly arayüz

## 🛠️ Teknolojiler

### Frontend
- **React 18** - Modern UI framework
- **TypeScript** - Tip güvenliği
- **Vite** - Hızlı build tool
- **React Router DOM** - Sayfa yönlendirme
- **React Hook Form** - Form yönetimi
- **React Query** - State management

### UI/UX
- **shadcn/ui** - Modern UI bileşenleri
- **Tailwind CSS** - Utility-first CSS framework
- **Radix UI** - Erişilebilir UI primitives
- **Lucide React** - İkon kütüphanesi
- **Sonner** - Toast bildirimleri

### Veri İşleme
- **Zod** - Schema validation
- **date-fns** - Tarih işlemleri
- **Recharts** - Grafik ve istatistikler
- **jsPDF** - PDF rapor oluşturma
- **XLSX** - Excel dosya işlemleri

### Mobil
- **Capacitor** - Cross-platform mobil uygulama
- **Local Notifications** - Yerel bildirimler
- **Camera** - Fotoğraf çekme
- **Dialog** - Native dialog'lar

## 🚀 Kurulum

### Gereksinimler
- Node.js 18+ 
- npm veya yarn
- Git

### Adımlar

```bash
# 1. Repository'yi klonlayın
git clone https://github.com/yourusername/BudgieBreedingTracker.git

# 2. Proje dizinine gidin
cd BudgieBreedingTracker

# 3. Bağımlılıkları yükleyin
npm install

# 4. Geliştirme sunucusunu başlatın
npm run dev
```

Uygulama `http://localhost:5173` adresinde çalışacaktır.

## 📖 Kullanım

### İlk Kurulum
1. Uygulamayı açın
2. İlk kuş profilinizi oluşturun
3. Kuluçka ve yavru takip sistemini yapılandırın
4. Bildirim ayarlarını yapın

### Kuş Ekleme
1. "Kuşlar" sekmesine gidin
2. "Yeni Kuş Ekle" butonuna tıklayın
3. Gerekli bilgileri doldurun
4. Fotoğraf ekleyin (opsiyonel)
5. Kaydedin

### Kuluçka Takibi
1. "Kuluçka" sekmesine gidin
2. Yeni kuluçka kaydı oluşturun
3. Yumurta sayısını ve tarihleri girin
4. Otomatik hesaplamaları takip edin

### Soy Ağacı
1. "Soy Ağacı" sekmesine gidin
2. Kuşları sürükleyip bırakarak ilişki kurun
3. Genetik bilgileri görüntüleyin
4. PDF raporu oluşturun

## 🔧 Geliştirme

### Komutlar

```bash
# Geliştirme sunucusu
npm run dev

# Production build
npm run build

# Build preview
npm run preview

# Linting
npm run lint
npm run lint:fix

# Type checking
npm run type-check
```

### Proje Yapısı

```
src/
├── components/          # UI bileşenleri
│   ├── dashboard/      # Dashboard bileşenleri
│   ├── forms/          # Form bileşenleri
│   ├── genealogy/      # Soy ağacı bileşenleri
│   └── tabs/           # Tab bileşenleri
├── hooks/              # Custom React hooks
├── lib/                # Utility fonksiyonları
├── pages/              # Sayfa bileşenleri
├── stores/             # State management
├── types/              # TypeScript tip tanımları
└── utils/              # Yardımcı fonksiyonlar
```

### Kod Standartları
- TypeScript strict mode
- ESLint kuralları
- Prettier formatı
- Conventional commits

## 🚀 Deployment

### Vercel (Önerilen)
```bash
# Vercel CLI ile
npm install -g vercel
vercel

# GitHub ile otomatik deployment
# Vercel dashboard'dan GitHub repo'yu bağlayın
```

### Netlify
```bash
# Build komutunu ayarlayın
npm run build

# Netlify dashboard'dan deploy edin
# Build command: npm run build
# Publish directory: dist
```

### GitHub Pages
```bash
# GitHub Actions workflow'u ekleyin
# .github/workflows/deploy.yml dosyası oluşturun
```

### Firebase Hosting
```bash
# Firebase CLI kurun
npm install -g firebase-tools

# Firebase'e giriş yapın
firebase login

# Projeyi başlatın
firebase init hosting

# Deploy edin
firebase deploy
```

### Mobil Uygulama
```bash
# Android build
npm run build
npx cap add android
npx cap sync android
npx cap open android

# iOS build
npm run build
npx cap add ios
npx cap sync ios
npx cap open ios
```

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

### Katkı Rehberi
- Kod standartlarına uyun
- Test yazın
- Dokümantasyonu güncelleyin
- Issue template'ini kullanın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 📞 İletişim

- **Proje Sahibi**: Bekir EFEOĞLU
- **GitHub**: [@BekirEfeoglu](https://github.com/BekirEfeoglu)
- **Website**: [https://budgiebreedingtracker.com/](https://budgiebreedingtracker.com/)

## 🙏 Teşekkürler

Bu projeyi mümkün kılan tüm açık kaynak kütüphanelerin geliştiricilerine teşekkürler.

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
