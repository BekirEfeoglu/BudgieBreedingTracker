# Community

Public feed, post + comment + like + report akışı. **Online-first** (`*Repository` exemption — bkz. architecture.md § Online-First Exemption). Cross-user multi-party stream, local mirror UX faydası yok.

## Stack
| Katman | Bileşen |
|--------|---------|
| Feature | `lib/features/community/` (providers, screens, widgets) |
| Repository | `CommunityPostRepository` (online-first, no Drift table) |
| Cache | `community_post_cache.dart` (in-memory + 1h TTL) |
| Profile cache | `community_profile_cache.dart` (post author lookup) |
| Moderation | `moderate-content` edge fn pre-publish |
| Storage | `community-posts` bucket (public read) |

## Online-First Contract
- `CommunityPostRepository` Drift table'ı YOK
- Read: Supabase realtime query veya pagination
- Write: doğrudan `client.from(SupabaseConstants.communityPostsTable)` (Repository içinde, UI'da değil)
- Cache: read latency için 1h in-memory, dirty bilgi yok
- Offline'da feed görünmez (cached snapshot OK, mutations engellenir)
- Repository class doc'unda exemption ifadesi zorunlu:
  ```dart
  /// Online-first: cross-user public feed, chronological. No local Drift mirror by design.
  ```

## Feed Pagination
- Cursor-based (timestamp + id, ascending stable order)
- Page size: 20 post (default), 50 max
- Infinite scroll: scroll position 80%'e ulaşınca next page fetch
- Pull-to-refresh: cursor reset, en yeniden başlat
- Loading state: skeleton 3 item, hata: ErrorState + retry

## Post Lifecycle
```
Compose -> Client moderation -> Edge moderate-content -> Insert to Supabase
  -> Optimistic UI append
  -> Realtime broadcast diğer kullanıcılara
  -> Failure: revert optimistic add + l10n error
```

- Optimistic insert: client UUID, server timestamp authoritative
- Edit window: 5 dakika (sonrası lock, MUTAVI-tarzı bilgilendirme)
- Delete: soft delete (`deleted_at`), feed query filter

## Comment
- Nested 1 seviye (reply-to-reply YOK — UX kompleksite)
- Per-post comment count cache invalidate'i write sonrası
- Comment moderation: post ile aynı pipeline (`contextType: 'comment'`)
- Long comment 2K char limit, UI textarea expandable

## Like / Reaction
- Tek tip like (Twitter heart benzeri, multi-emoji YOK)
- Toggle: `community_post_likes` junction table
- Race-safe: client `requestId` pattern, server unique constraint `(post_id, user_id)`
- Count cache: 30sn TTL, optimistic increment

## Report Flow
- User reports post → `community_reports` table
- Threshold (3 unique reporter) → auto-hide pending review
- Self-report ignore
- Admin moderation queue (admin.md)

## Author Display
- `community_profile_cache` post author lookup batch fetch
- Public profile fields: avatar, display name, verified badge, level
- PII (email, phone) ASLA expose etme
- Profil tap → public profile screen (DM CTA, blok CTA)

## Realtime
- Supabase realtime subscription `community_posts` insert + delete
- Yeni post geldiğinde feed top'unda "5 yeni post" banner (kullanıcı tap'leyince fetch)
- Otomatik scroll yapmama (UX rule — kullanıcı kontrolü)
- Disconnect/reconnect: cursor invalidate, soft refresh

## Storage Integration
- Post fotoğrafları: `community-posts` public bucket
- Upload: `assets-images.md` pipeline (scan-image-safety zorunlu)
- Public URL CDN cache (Cache-Control: 7 gün)
- Storage path: `community-posts/<user_id>/<post_id>/<index>.jpg`

## Premium Features
- Premium kullanıcı: max 10 fotoğraflı post, free max 3
- Verified breeder badge (gamification.md)
- Pinned post (premium only, max 1 aktif)

## RLS Policy Yapısı
- SELECT: herkes okuyabilir (public feed)
- INSERT: auth.uid() = user_id
- UPDATE: 5dk window + author only
- DELETE: author OR admin
- Soft delete: `deleted_at IS NULL` filter tüm SELECT'lerde

## Block / Mute
- Block: karşılıklı feed gizleme, DM engelleme
- Mute: tek yönlü, feed'de görünmez ama DM engellenmez
- Block list cache: 5dk TTL, mutation sonrası invalidate
- Engellenen kullanıcının postları feed query'sinde filter

## Empty / Error State
- Empty feed: ilk açılış için onboarding ("İlk postunu paylaş")
- Filter empty (sadece premium veya verified takip): filtre uyarısı
- Network error: cached snapshot göster + offline banner

## Performance
- Feed initial load p95 < 1.5s (cached author lookup)
- Realtime event handle < 100ms (UI append)
- Image lazy load: viewport'a 200px kala
- Memory: max 200 post in-memory, pagination scroll-back için cursor reload

## Anti-Patterns
1. `CommunityPostRepository`'ye Drift table eklemek (offline-first contract'a aykırı — exemption)
2. Realtime'da otomatik scroll (kullanıcı reading flow kırılır)
3. Optimistic insert sonrası failure'da feed'de bırakmak (sessiz tutarsızlık)
4. Edit window'sız sınırsız edit (history bilgisi yok, gaslighting riski)
5. Self-report'a izin
6. PII'yi profile cache'e koymak (email, phone)
7. Block durumunu sadece client'ta tutmak (server query'de filtrelemek zorunlu)
8. Comment'i 2+ seviye nested yapmak (UX karmaşası)
9. Moderation atlayıp publish (release-blocker — moderation.md fail-closed)
10. Public bucket'ta kullanıcı kimliği tahmin edilebilir path (`<email>/...` gibi)

> **İlgili**: architecture.md § Online-First Exemption, moderation.md (`moderate-content`), messaging.md (DM CTA + block sync), gamification.md (verified badge), edge-functions.md (`moderate-content`), assets-images.md (post images)
