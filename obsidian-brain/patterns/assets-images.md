# Assets & Images

Source: `.claude/rules/assets-images.md`

## SVG Icon System

- Domain icons: `AppIcon(AppIcons.x)` — rendered via `flutter_svg`
- 99 constants in `lib/core/constants/app_icons.dart`
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
2. Add constant to `AppIcons`: `static const male = 'assets/icons/birds/male.svg'`
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
  → Picker-side resize / quality (surface-specific)
  → ImagePickerGuard size pre-check
  → Storage validation (limit, extension, magic bytes)
  → Safety moderation (raw 2 MB cap, OpenAI categories)
      ├─ most flows: ImageSafetyService → scan-image-safety
      └─ community: upload-community-photo validates + moderates + stores
  → Reject if unsafe + show l10n error
  → Upload to Supabase Storage (bucket-specific)
  → Save signed URL or path in DB
  → Invalidate provider for UI refresh
```

## File Size Guard

```dart
final accepted = await ImagePickerGuard.ensureWithinSizeLimit(context, file);
if (!accepted || !context.mounted) return;
```

The picker guard is UX-only. `StorageService` (and the marketplace remote
source) re-checks the byte limit, allowed extension, and magic bytes before the
fail-closed safety scan/upload. `ValidationException` has no `fieldErrors` map.

For scanned UGC, the client/Edge moderation paths reject raw images above 2 MB.
Most pickers still advertise/guard 10 MB (avatar already uses 2 MB), so 2 MB is
the effective end-to-end limit until the mismatch in [[known-gaps]] is resolved.

## Picker-Side Resize / Quality

There is no separate `flutter_image_compress` or isolate stage. Each flow passes
limits directly to `ImagePicker`:

| Surface | Current picker contract |
|---------|-------------------------|
| Bird + DM photo | 1920×1920, quality 85 |
| Community post | 1200×1200, quality 85 |
| Marketplace | max width 1200, quality 80 |
| Avatar | 512×512, quality 80; 2 MB guard |
| Local AI | 1024×1024, quality 85 |

## Storage Buckets

Real buckets (`lib/core/constants/supabase_constants.dart`): `bird-photos`, `egg-photos`, `chick-photos`, `avatars`, `backups`, `community-photos`, `photos` (marketplace, constant `marketplacePhotosBucket`), `message-photos`. There is no separate `health-records` or `chat-attachments` bucket — health record photos live in `bird-photos`; DM photo messages live in `message-photos`.

| Bucket | Access | Content |
|--------|--------|---------|
| `bird-photos` | Private (user RLS) | Bird photos + health record photos |
| `egg-photos` / `chick-photos` | Private (user RLS) | Egg/chick photos |
| `community-photos` | Server upload, signed URL read | Community images |
| `photos` (marketplace) | Public read, auth write | Listing photos |
| `avatars` / `backups` | Private | Profile photo / user backups |
| `message-photos` | Private (user RLS) | DM photo messages |

- Private: signed URL (1h TTL)
- Public: CDN URL + cache header

## Anti-Patterns

1. `Image.network` (no cache, no retry)
2. No `memCacheWidth`/`memCacheHeight` in list items (memory spike)
3. Missing picker resize/quality parameters (oversized payload)
4. PNG for photos (5× larger than JPEG)
5. `Icon(Icons.pets)` for domain icon (#12)
6. SVG path hardcoded (#13)
7. Skipping the mandatory safety path (`scan-image-safety`, or
   `upload-community-photo` for community)
8. Reusing the 1920px bird/DM sizing for avatar or marketplace

## See Also

- [[patterns/anti-patterns]] — #12, #13, #14
- [[infrastructure/edge-functions]] — scan-image-safety
- [[data-layer/supabase]] — storage buckets
