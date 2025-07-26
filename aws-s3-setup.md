# AWS S3 Kurulum Rehberi

## 1. AWS Hesabı Oluşturma
1. https://aws.amazon.com adresine gidin
2. "Create an AWS Account" butonuna tıklayın
3. E-posta, şifre ve hesap adı girin
4. Kredi kartı bilgilerinizi girin (ücretsiz katman için)
5. Telefon doğrulaması yapın

## 2. S3 Bucket Oluşturma
1. AWS Console'a giriş yapın
2. "S3" servisini arayın ve tıklayın
3. "Create bucket" butonuna tıklayın
4. Bucket adı: `budgie-breeding-backups-[UNIQUE-ID]`
5. Region: `eu-west-1` (Avrupa)
6. "Block all public access" seçeneğini işaretleyin
7. "Create bucket" butonuna tıklayın

## 3. IAM Kullanıcısı Oluşturma
1. AWS Console'da "IAM" servisini arayın
2. "Users" > "Create user" tıklayın
3. Username: `budgie-backup-user`
4. "Programmatic access" seçin
5. "Attach existing policies directly" seçin
6. "AmazonS3FullAccess" policy'sini ekleyin
7. "Create user" butonuna tıklayın
8. **Access Key ID** ve **Secret Access Key**'i kaydedin

## 4. Bucket Yapısı
```
budgie-breeding-backups/
├── daily/
│   ├── 2024-01-15/
│   │   ├── birds.sql
│   │   ├── chicks.sql
│   │   ├── eggs.sql
│   │   └── metadata.json
│   └── 2024-01-16/
├── weekly/
├── monthly/
└── manual/
```

## 5. Güvenlik Ayarları
- Bucket encryption: AES-256
- Versioning: Enabled
- Lifecycle rules: 30 gün sonra IA, 90 gün sonra Glacier
- Cross-region replication: Disabled (maliyet)

## 6. Maliyet Tahmini
- **Ücretsiz katman**: 5GB depolama, 20,000 GET, 2,000 PUT
- **Ücretli katman**: $0.023/GB/ay + transfer ücretleri
- **Aylık tahmini**: $2-5 (100MB veri için) 