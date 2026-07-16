# Assets & Images

Fotoğraf yükleme, ikon yönetimi, network image cache ve dosya boyutu güvenliği. Yanlış kalite/boyut hem performans hem maliyet (Supabase Storage) sorunudur.

## SVG İkon Sistemi
- Domain ikonlar: `AppIcon(AppIcons.x)` — flutter_svg ile render edilir
- 99 sabit, `lib/core/constants/app_icons.dart` içinde (güncel sayı: CLAUDE.md § Codebase Stats — `verify_rules.py` doğrular)
- Asset dizini: `assets/icons/<category>/` (10 kategori)
- Generic UI: `LucideIcons.x` (sadece settings, generic action — domain için DEĞİL)
- Asla `Icon(Icons.x)` — domain ikonu varsa SVG, yoksa LucideIcons

```dart
// CORRECT
AppIcon(AppIcons.bird, size: 24, color: theme.colorScheme.primary)

// WRONG
Icon(Icons.pets)
SvgPicture.asset('assets/icons/birds/bird.svg')  // sabit yerine path
```

### Yeni SVG İkon Ekleme
1. SVG dosyasını `assets/icons/<category>/` altına ekle
2. `AppIcons` sınıfına sabit ekle: `static const String birdMale = 'assets/icons/birds/bird_male.svg'`
3. `pubspec.yaml` asset path'i wildcard (`assets/icons/`) zaten alır — manuel ekleme gereksiz
4. Kullan: `AppIcon(AppIcons.birdMale)`

## Network Image (CachedNetworkImage)
- `CachedNetworkImage` zorunlu — `Image.network` direct kullanılmaz
- Her zaman `placeholder` + `errorWidget` sağla
- Memory cache + disk cache otomatik
- List item'larda `memCacheWidth`/`memCacheHeight` ver (decode boyutu sınırlanır)

```dart
CachedNetworkImage(
  imageUrl: bird.photoUrl,
  memCacheWidth: 200,  // List item için decode boyutu
  placeholder: (_, __) => const ShimmerBox(width: 100, height: 100),
  errorWidget: (_, __, ___) => AppIcon(AppIcons.imagePlaceholder),
  fit: BoxFit.cover,
)
```

## Photo Upload Pipeline
```
User selects photo (ImagePicker)
  -> Local validation (size, dimension, format)
  -> Picker-side resize/quality (surface-specific)
  -> Safety moderation (scan-image-safety; community: upload-community-photo)
  -> Reject if unsafe + show l10n error
  -> Upload to Supabase Storage (bucket-specific)
  -> Save signed URL or storage path in DB
  -> Invalidate provider for UI refresh
```

## File Size Guard
- **2 MiB raw üst limit** — safety scan kullanan tüm upload yüzeylerinde picker
  sonrası istemci ön kontrolü, repository/storage doğrulaması, Edge doğrulaması ve
  bucket `file_size_limit` aynı sözleşmeyi uygular
- Picker resize/quality payload'ı çoğunlukla küçültür fakat format/cihaz davranışı
  nedeniyle 2 MiB garantisi vermez; guard her zaman picker sonucunun boyutunu ölçer
- 10 MiB `maxUploadSizeBytes` scanned UGC için kullanılmaz; Local AI gibi ayrı,
  tarama-dışı işleme bütçeleri kendi açık sabitini kullanır
- L10n: `errors.image_too_large` (`args: ['2']`); mesaj ölçümün picker işlemi
  sonrasındaki dosyaya uygulandığını açıklar

```dart
final accepted = await ImagePickerGuard.ensureWithinSizeLimit(context, file);
if (!accepted || !context.mounted) return;
```

`StorageService` / marketplace remote source aynı 2 MiB raw sınırını, izinli
uzantıyı ve magic-byte eşleşmesini tekrar doğrular; picker guard yalnız UX
katmanıdır. `ImageSafetyService`, `scan-image-safety` ve
`upload-community-photo` aynı sınırı fail-closed uygular. Tam 2 MiB kabul edilir;
bir byte üstü reddedilir.

2 MiB seçimi bilinçlidir: raw veri base64 ile yaklaşık %33 büyür; 10 MiB raw
yaklaşık 13.33 MiB base64 alanı üretir. Edge request parser body chunk'larını
tutup JSON parse öncesi tek buffer'a kopyalar, community handler ayrıca decode
buffer'ı üretir ve moderasyon isteği payload'ı yeniden serileştirir. Bu nedenle
10 MiB'ye yükseltmek transient bellek/CPU ile authenticated payload-amplification
abuse yüzeyini gereksiz büyütür; picker/client/bucket sınırı 2 MiB'ye indirilir.

## Picker-Side Resize / Quality

Projede ayrı bir `flutter_image_compress` / isolate aşaması yoktur. Boyut ve
kalite doğrudan `ImagePicker` parametreleriyle yüzeye göre ayarlanır:

| Surface | Picker contract |
|---------|-----------------|
| Bird + DM photo | `maxWidth/maxHeight: 1920`, `imageQuality: 85` |
| Community post | `maxWidth/maxHeight: 1200`, `imageQuality: 85` |
| Marketplace | `maxWidth/maxHeight: 1200`, `imageQuality: 80` |
| Avatar | `maxWidth/maxHeight: 512`, `imageQuality: 80` |
| Local AI | `maxWidth/maxHeight: 1024`, `imageQuality: 85` |

Tablodaki safety-scanned yüzeylerin tamamında picker sonrası 2 MiB raw guard
zorunludur; çözünürlük/quality değerleri sadece bu limite ulaşma olasılığını
iyileştiren yüzeye özel optimizasyonlardır.

## Storage Buckets
- Bucket isimleri `SupabaseConstants` içinde sabit
- Her bucket'ın RLS policy'si var (user kendi dosyalarına okuma/yazma)
- Public bucket vs private bucket ayrımı:
  - Public: marketplace listings
  - Private/signed: kullanıcı kuş fotoğrafları, sağlık kayıt fotoğrafları, community post fotoğrafları
- Public bucket için CDN URL, private için signed URL (TTL 1h)

Gerçek bucket'lar (`lib/core/constants/supabase_constants.dart`): `bird-photos`, `egg-photos`, `chick-photos`, `avatars`, `backups`, `community-photos`, `photos` (marketplace, sabit adı `marketplacePhotosBucket`), `message-photos`. `health-records` ve `chat-attachments` diye ayrı bucket'lar YOK — sağlık kayıt fotoğrafı `bird-photos` altında, DM fotoğrafları `message-photos` altında saklanır.

Safety-scanned yedi image bucket'ının (`bird/egg/chick/avatars/community/photos/message`)
`file_size_limit` değeri migration `20260717120000` ile 2 MiB'dir. `backups`
ayrı 50 MiB sözleşmesindedir ve bu limite dahil değildir.

| Bucket | Erişim | İçerik |
|--------|--------|--------|
| `bird-photos` | Private (user-scoped RLS) | Kullanıcı kuşları + sağlık kayıt fotoğrafları |
| `egg-photos` / `chick-photos` | Private (user-scoped RLS) | Yumurta/yavru fotoğrafları |
| `avatars` | Private | Profil fotoğrafı |
| `community-photos` | Server upload, signed URL read | Topluluk paylaşımları |
| `photos` (marketplace) | Public read, auth write | İlan fotoğrafları |
| `backups` | Private | Kullanıcı yedekleri |
| `message-photos` | Private (user-scoped RLS) | DM fotoğraf mesajları |

## Signed URL TTL
- Default: 1 saat
- Profil fotoğrafı gibi sık erişilen: CDN public + cache header
- Hassas dosya: short TTL (15dk), her erişimde yeni URL

## Image Caching Strategy
- Disk cache TTL: 7 gün (varsayılan)
- Manuel invalidation: `DefaultCacheManager().removeFile(url)`
- Profile photo değişimi: cache'i temizle, yeni URL ile yeniden yükle

## Asset Lazy Loading
- App startup'ta tüm SVG'leri precache ETMEYE — gerektiğinde yükle
- Critical path (splash logo) hariç precache yok
- `flutter_svg`'nin built-in cache'i yeterli

## Performance Anti-Patterns
1. `Image.network` doğrudan (cache yok, retry yok)
2. List item'larda decode boyut limiti olmamak (memory shoot)
3. Picker resize/quality parametresi olmadan upload (ham foto, Storage maliyeti)
4. PNG ile fotoğraf kaydetmek (JPEG'in 5x'i boyut)
5. `Icon(Icons.pets)` domain ikonu için (anti-pattern #12)
6. SVG path hardcode (anti-pattern #13 — `AppIcons` sabitleri zorunlu)
7. Zorunlu safety path'i atlayıp doğrudan upload (`scan-image-safety`;
   community için `upload-community-photo`)
8. Yüzeye özel picker limitini atlamak (avatar/marketplace için gereksiz büyük payload)
9. Signed URL'i cache etmeden her widget rebuild'de yeniden istemek

## Test
```dart
testWidgets('rejects scanned image larger than 2 MiB after picker processing', (tester) async {
  // ImagePickerGuard false döner ve localized snackbar gösterir.
});

testWidgets('shows placeholder while loading', (tester) async {
  await pumpWidget(tester, BirdAvatar(url: 'https://example.com/bird.jpg'));
  expect(find.byType(ShimmerBox), findsOneWidget);
});
```

> **İlgili**: edge-functions.md (scan-image-safety), data-layer.md (SupabaseConstants, Storage), performance.md (image budget), coding-standards.md (icon API)
