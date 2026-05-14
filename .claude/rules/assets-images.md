# Assets & Images

Fotoğraf yükleme, ikon yönetimi, network image cache ve dosya boyutu güvenliği. Yanlış kalite/boyut hem performans hem maliyet (Supabase Storage) sorunudur.

## SVG İkon Sistemi
- Domain ikonlar: `AppIcon(AppIcons.x)` — flutter_svg ile render edilir
- 84 sabit, `lib/core/constants/app_icons.dart` içinde
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
  -> Compress + resize (max 1920px, JPEG q85)
  -> Call scan-image-safety edge fn (NSFW + malware check)
  -> Reject if unsafe + show l10n error
  -> Upload to Supabase Storage (bucket-specific)
  -> Save signed URL or storage path in DB
  -> Invalidate provider for UI refresh
```

## File Size Guard
- **10MB üst limit** — istemci tarafında ön kontrol (network'e atmadan reddet)
- Compress sonrası genelde 1MB altı (1920px JPEG q85)
- Edge function `scan-image-safety` ayrıca server-side guard yapar
- L10n: `errors.image_too_large` (namedArgs: max=10MB)

```dart
const maxImageBytes = 10 * 1024 * 1024;  // 10MB

Future<File> validateImage(File file) async {
  final size = await file.length();
  if (size > maxImageBytes) {
    throw ValidationException(
      'errors.image_too_large',
      fieldErrors: {'image': 'errors.image_too_large'},
    );
  }
  return file;
}
```

## Image Compression
- `flutter_image_compress` paketi
- Max boyut: 1920px (uzun kenar)
- Format: JPEG quality 85 (PNG sadece transparency varsa)
- Compress UI thread'i bloklar — `compute()` veya isolate kullan

```dart
final compressed = await FlutterImageCompress.compressWithFile(
  file.path,
  minWidth: 1920,
  minHeight: 1920,
  quality: 85,
  format: CompressFormat.jpeg,
);
```

## Storage Buckets
- Bucket isimleri `SupabaseConstants` içinde sabit
- Her bucket'ın RLS policy'si var (user kendi dosyalarına okuma/yazma)
- Public bucket vs private bucket ayrımı:
  - Public: marketplace listings, community posts
  - Private: kullanıcı kuş fotoğrafları, sağlık kayıt fotoğrafları
- Public bucket için CDN URL, private için signed URL (TTL 1h)

| Bucket | Erişim | İçerik |
|--------|--------|--------|
| `bird-photos` | Private (user-scoped RLS) | Kullanıcı kuşları |
| `community-posts` | Public read, auth write | Topluluk paylaşımları |
| `marketplace-listings` | Public read, auth write | İlan fotoğrafları |
| `health-records` | Private | Sağlık belgeleri |
| `chat-attachments` | Conversation-scoped RLS | Mesajlaşma medyası |

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
3. Compress'siz upload (10MB ham foto, Storage maliyeti)
4. PNG ile fotoğraf kaydetmek (JPEG'in 5x'i boyut)
5. `Icon(Icons.pets)` domain ikonu için (anti-pattern #12)
6. SVG path hardcode (anti-pattern #13 — `AppIcons` sabitleri zorunlu)
7. `scan-image-safety` edge fn'i atlayıp doğrudan upload
8. Compress'i UI thread'inde yapmak (jank)
9. Signed URL'i cache etmeden her widget rebuild'de yeniden istemek

## Test
```dart
test('rejects image larger than 10MB', () async {
  final file = MockFile(size: 11 * 1024 * 1024);
  expect(
    () => validateImage(file),
    throwsA(isA<ValidationException>()),
  );
});

testWidgets('shows placeholder while loading', (tester) async {
  await pumpWidget(tester, BirdAvatar(url: 'https://example.com/bird.jpg'));
  expect(find.byType(ShimmerBox), findsOneWidget);
});
```

> **İlgili**: edge-functions.md (scan-image-safety), data-layer.md (SupabaseConstants, Storage), performance.md (image budget), coding-standards.md (icon API)
