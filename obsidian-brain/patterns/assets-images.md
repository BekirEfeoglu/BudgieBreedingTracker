# Assets & Images

Source: `.claude/rules/assets-images.md`

## SVG Icon System

- Domain icons: `AppIcon(AppIcons.x)` — rendered via `flutter_svg`
- 84 constants in `lib/core/constants/app_icons.dart`
- Asset directories: `assets/icons/<category>/` (10 categories)
- Generic UI only: `LucideIcons.x` (settings, navigation)
- **Never**: `Icon(Icons.x)` for domain concepts, raw SVG path strings

```dart
// CORRECT
AppIcon(AppIcons.bird, size: 24, color: theme.colorScheme.primary)

// WRONG
Icon(Icons.pets)
SvgPicture.asset('assets/icons/birds/bird.svg')  // raw path
```

### Adding a New SVG Icon

1. Add SVG to `assets/icons/<category>/`
2. Add constant to `AppIcons`: `static const String birdMale = 'assets/icons/birds/bird_male.svg'`
3. No pubspec.yaml change needed (wildcard `assets/icons/` already registered)
4. Use: `AppIcon(AppIcons.birdMale)`

## Network Images

```dart
CachedNetworkImage(
  imageUrl: bird.photoUrl,
  memCacheWidth: 200,   // limit decode size in lists
  placeholder: (_, __) => const ShimmerBox(width: 100, height: 100),
  errorWidget: (_, __, ___) => AppIcon(AppIcons.imagePlaceholder),
  fit: BoxFit.cover,
)
```

**Always** use `CachedNetworkImage` — never `Image.network` directly.

## Photo Upload Pipeline

```
User selects photo (ImagePicker)
  → Local validation (size, dimension, format)
  → Compress + resize (max 1920px, JPEG q85)
  → scan-image-safety Edge Function (NSFW + malware)
  → Reject if unsafe + show l10n error
  → Upload to Supabase Storage (bucket-specific)
  → Save signed URL or path in DB
  → Invalidate provider for UI refresh
```

## File Size Guard

```dart
const maxImageBytes = 10 * 1024 * 1024;  // 10MB

if (await file.length() > maxImageBytes) {
  throw ValidationException(
    'errors.image_too_large',
    fieldErrors: {'image': 'errors.image_too_large'},
  );
}
```

Also enforced server-side by `scan-image-safety`.

## Compression

```dart
final compressed = await FlutterImageCompress.compressWithFile(
  file.path,
  minWidth: 1920, minHeight: 1920,
  quality: 85,
  format: CompressFormat.jpeg,
);
```

Run in isolate with `compute()` — never block UI thread.

## Storage Buckets

| Bucket | Access | Content |
|--------|--------|---------|
| `bird-photos` | Private (user RLS) | Bird photos |
| `community-posts` | Public read, auth write | Community images |
| `marketplace-listings` | Public read, auth write | Listing photos |
| `health-records` | Private | Health documents |
| `chat-attachments` | Conversation-scoped RLS | DM attachments |

- Private: signed URL (1h TTL)
- Public: CDN URL + cache header

## Anti-Patterns

1. `Image.network` (no cache, no retry)
2. No `memCacheWidth`/`memCacheHeight` in list items (memory spike)
3. No compression before upload (10MB storage cost)
4. PNG for photos (5× larger than JPEG)
5. `Icon(Icons.pets)` for domain icon (#12)
6. SVG path hardcoded (#13)
7. Skipping `scan-image-safety`
8. Compress on UI thread (jank)

## See Also

- [[patterns/anti-patterns]] — #12, #13, #14
- [[infrastructure/edge-functions]] — scan-image-safety
- [[data-layer/supabase]] — storage buckets
