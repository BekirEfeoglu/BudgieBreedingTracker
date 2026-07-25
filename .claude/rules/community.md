# Community

Public feed, post + comment + like + report akışı. **Online-first** (`*Repository` exemption — bkz. architecture.md § Online-First Exemption). Cross-user multi-party stream, local mirror UX faydası yok.

## Stack
| Katman | Bileşen |
|--------|---------|
| Feature | `lib/features/community/` (providers, screens, widgets) |
| Repository | `CommunityPostRepository` (online-first, no Drift table) |
| Cache | `community_post_cache.dart` (in-memory, `_defaultTtl = Duration(minutes: 5)`) |
| Profile cache | `community_profile_cache.dart` (post author lookup) |
| Moderation | `create-community-post` / `create-community-comment` Edge Functions |
| Storage | `community-photos` bucket (server upload, signed URL read) |

## Online-First Contract
- `CommunityPostRepository` Drift table'ı YOK
- Read: Supabase realtime query veya pagination
- Write: `create-community-post` ve `create-community-comment` Edge Functions; client doğrudan tablo insert yapmaz
- Cache: read latency için in-memory **5 dk** TTL (`CommunityPostCache._defaultTtl`), dirty bilgi yok
- Offline'da feed görünmez (cached snapshot OK, mutations engellenir)
- Repository class doc'unda exemption ifadesi zorunlu:
  ```dart
  /// Online-first: cross-user public feed, chronological. No local Drift mirror by design.
  ```

## Feed Pagination
- Cursor-based (timestamp + id, ascending stable order)
- Page size: 20 post (`CommunityFeedNotifier._pageSize`)
- Infinite scroll: **piksel** eşiği — `currentScroll >= maxScrollExtent - 200`
  (`community_feed_list.dart::_onScroll`). Yüzde tabanlı (%80) bir eşik YOK
- Pull-to-refresh: cursor reset, en yeniden başlat
- Loading state: skeleton 3 item, hata: ErrorState + retry

## Post Lifecycle
```
Compose -> Client moderation -> Edge create-community-post
  -> server moderation + guard -> service-role insert
  -> Başarıda feed.refresh() (tam re-fetch) + realtime broadcast
  -> Failure: l10n error, feed'e post eklenmez
```

- **Post create optimistic DEĞİL** (2026-07-05 doğrulaması): `CreatePostNotifier` (`community_create_providers.dart`) başarıda `communityFeedProvider.refresh()` çağırır — client-UUID optimistic append/revert YOK. Bilinçli: server moderation/guard sonrası authoritative satır tek kaynak. (Like/bookmark/follow/comment-like ise optimistic + rollback — aşağıya bkz.)
- **Post edit — implement edildi + prod'da (`main`, 2026-07-03):** İçerik-yalnızca düzenleme 5 dk pencerede. `CommunityPostRepository.update({postId, content})` → `CommunityPostRemoteSource.updateContent` → `create-community-post` edge fn `mode:'update'` (moderation yeniden çalışır, fail-closed). Pencere edge fn'de (`EDIT_WINDOW_MS`) + `community_posts` authenticated UPDATE grant'i `(is_deleted, needs_review)` kolonlarına daraltılarak (migration `20260703093817`, prod'a uygulandı) enforce edilir — content doğrudan client `.update()` ile değişemez. `edited_at` kolonu + UI'da `edited` rozeti (edit sheet `showAppBottomSheet`); "Düzenle" yalnız kendi postunda + pencere içinde. (Yazarın kendi `needs_review`'ünü temizleyebilmesi bilinçli kapsam dışı. `clearReviewFlag`'in var olmayan `reviewed_by` yazımı 2026-07-03'te kaldırıldı.)
- Delete: soft delete (`is_deleted = true` kolonu — `deleted_at` DEĞİL), feed query filter

## Comment
- **Tek seviye reply (nested 1 seviye) — shipped + prod'da (2026-07-07):** `CommunityComment.parentId` + `parent_id` kolonu (migration `20260707093514`, prod'da). UI: `replyToCommentProvider` state, `community_comment_input.dart` "→ @kullanıcı" reply banner'ı + `parentId` geçişi, `community_comment_tile.dart` `parentId != null` ise girinti (`AppSpacing.xl * 2`). Reply trigger execute-grant'ı `harden_comment_reply_trigger_function_execute` (migration `20260707194236`) ile hardened. 2+ seviye nesting YOK — tek seviye sınırı korunur (anti-pattern #8).
- Comment yazma/silme/like `commentListProvider(postId)`'i günceller (add → `fetchInitial`, delete → `removeComment`, like → optimistic `applyLikeToggle`+rollback). `visibleCommentsProvider` bunu izler. Ayrı bir `commentsForPostProvider` YOK (2026-07-05'te ölü çift-kaynak olarak kaldırıldı).
- Comment moderation: `create-community-comment` Edge Function içinde fail-closed
- Char limit **1000** (`CommentFormNotifier.maxCommentLength` + input `maxLength`), UI textarea expandable

## Like / Reaction
- Tek tip like (Twitter heart benzeri, multi-emoji YOK)
- Toggle: `community_post_likes` junction table
- Race-safe: client `requestId` pattern, server unique constraint `(post_id, user_id)`
- Sayaç: **cache YOK.** `likeCount` post satırıyla birlikte gelir;
  `CommunityFeedNotifier` optimistic olarak `±1` yapar ve hata durumunda geri
  alır. TTL'li ayrı bir like-count cache'i yoktur (post satırının kendisi
  `CommunityPostCache`'in 5 dk TTL'ine tabidir)

## Follow
- Yazma yolu: `CommunitySocialRepository.toggleFollow` → `community_follows` (`follower_id`/`following_id`, unique pair). RLS: kendi `follower_id`'nle insert/delete
- **Takip durumunun İKİ kaynağı var (2026-07-14):** `fetch_community_feed` RPC'si `is_following_author`'ı artık kendisi döndürür (migration `20260714200510`; her iki sıralama dalında da `EXISTS` ile, SECURITY INVOKER — `community_follows_select` zaten follower'ın kendi satırlarını görmesine izin verir). Feed bu yüzden tek round-trip'tir. Diğer yollar (`fetchById`/`fetchByUser`/`fetchByTag`/`fetchByIds`) düz select'tir, kolonu TAŞIMAZ; `CommunityPostRepository._enrichPosts` bu satırlar için `fetchFollowedUserIds` ile alanı çözmeye devam eder (`needsFollowLookup` — satırda kolon yoksa çeker). Bu fallback'i KALDIRMA: 2026-07-14 öncesi hiçbir kaynak alanı doldurmuyordu, alan sabit `false` kalıyordu, buton hiç "Takip Ediliyor"a geçmiyordu ve **"Takip Edilenler" filtre sekmesi hep boştu**
- RPC'ye kolon eklemek `RETURNS TABLE` değişimidir → `CREATE OR REPLACE` yetmez, DROP+CREATE gerekir; grant'ları (`authenticated`, `service_role`; PUBLIC YOK) migration içinde açıkça geri ver. Parametre listesi değişmediği için eski binary'ler kırılmaz (fazladan kolonu yok sayarlar)
- `FollowToggleNotifier` başarıdan sonra ÜÇ şeyi de yapmalı: feed optimistic toggle + `invalidateFeedCache()` + `ref.invalidate(followedUsersProvider)`. Sonuncusu atlanırsa public profil ekranının takip butonu (state'i `followedUsersProvider`'dan türetir) pull-to-refresh'e kadar eski durumda kalır
- Yeni bir "takip durumu" tüketicisi eklerken: kaynağı `isFollowingAuthor` (post bazlı) mı `followedUsersProvider` (kullanıcı listesi) mi — İKİSİ de invalidate edilmeli

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
- Post fotoğrafları: `community-photos` bucket
- Upload: `upload-community-photo` Edge Function içinde server-side image moderation zorunlu
- Client direct Storage insert/update kapalı; Edge Function service-role ile yükler
- Picker sonrası raw boyut en fazla 2 MiB'dir; client guard, Edge decoded-size
  doğrulaması ve bucket `file_size_limit` aynı sınırı uygular
- Okuma: post payload'ında signed URL; URL path'i `user_id/post_id` ile eşleşmeli
- Storage path: `community-photos/<user_id>/<post_id>/<timestamp>-<uuid>.<ext>`

## Premium Features
- Foto/post: free **3**, premium **10** — client-side enforce edilir (`CommunityCreatePostScreen._maxImages`, `effectivePremiumProvider`; limit aşımında `community.photo_limit_reached` toast). Server `validate-free-tier-limit` authoritative kalır; client cap yalnız UX (2026-07-05'te eklendi).
- Verified breeder badge (gamification.md) — post/guide yazar satırında `Semantics(label: community.verified_breeder)` + `LucideIcons.badgeCheck`
- Pinned post — shipped client flow: `community_posts.is_pinned` parse edilir, pinned badge tüm post tiplerinde görünür, loaded feed içinde pinned postlar stabil biçimde öne alınır. Admin/founder (`isAdminProvider`) feed kart menüsünden ve detail app bar'dan pin/unpin yapabilir; `PostPinToggleNotifier` optimistic update + rollback uygular ve cache'i düşürür. Not: server RPC cursor bozulmasın diye global pinned-first pagination SQL'i yok; sadece yüklenen sayfa/set içinde öne alma yapılır.
- **Bird-link / mutation-tags — shipped + prod'da (2026-07-08):** `community_posts.bird_id` (FK → `birds.id` ON DELETE SET NULL) + `bird_name` + `mutation_tags TEXT[]` kolonları prod'da (migration `20260708153615_add_bird_tags_to_posts`, `idx_community_posts_bird_id` partial index dahil). Tam round-trip: create-post edge fn `bird_id`/`mutation_tags`'ı Zod ile validate edip yazar (`handler.ts`), `_feedColumns` seçer, `CommunityPostRepository._parsePost` okur, `BirdLinkChip`/`PostTagWrap` render eder. **Not:** bu kolonlar `_feedColumns`'ta ZORUNLU — kaldırmak/kolonları drop etmek `fetchById`/`fetchByUser`'ı 400 ile kırar (2026-07-08'de kolon prod'da yokken tam bu drift yaşandı).

## RLS Policy Yapısı
- SELECT: herkes okuyabilir (public feed)
- INSERT: authenticated direct insert disabled; create post/comment Edge Functions service-role ile yazar ve JWT owner bilgisini kullanır
- UPDATE: 5dk window + author only
- DELETE: author OR admin
- Soft delete: `is_deleted = false` filter tüm SELECT'lerde (`deleted_at` kolonu yok)

## Block / Mute
- Block: karşılıklı feed gizleme, DM engelleme
- **Mute — implement edildi + prod'da (`main`, 2026-07-03):** Tek yönlü, görünürlük-yalnızca yumuşak block. **Ayrı** `community_mutes` tablosu (migration `20260703093916`) — `community_blocks`'a kolon EKLENMEDİ, çünkü messaging block-RLS'i (`20260702174304`) `community_blocks` okur; mute DM'i etkilememeli. RLS SELECT **owner-only** (`auth.uid() = user_id`) — mute'lanan kişi öğrenemez (block'un iki-yönlü SELECT'inden farklı). Client: `CommunitySocialRepository.{muteUser,unmuteUser,fetchMutedUserIds}` + `mutedUsersProvider` (block stack'inin aynası, optimistic+rollback). Feed filtresi muted'ı blocked'dan sonra tüm tab'lerde uygular; `visibleCommentsProvider` yorumları da filtreler. Light action (confirm yok, toast) — community-only, messaging'e wire EDİLMEDİ.
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
11. `_feedColumns`'a kolon eklerken/çıkarırken prod şema ile senkron olmamak (kolon prod'da yokken query 400 döner — `bird_id`/`mutation_tags` 2026-07-08 drift'i; migration ÖNCE deploy edilmeli, migrations.md deploy sırası)
12. Model alanının (`isFollowingAuthor` gibi) sadece parse edilmesine bakıp veri kaynağının onu GERÇEKTEN döndürdüğünü doğrulamamak — `_parsePost` alanı okuyordu ama RPC hiç göndermiyordu; alan sessizce hep `false` kaldı (§ Follow)
13. Optimistic toggle'ı "yazma başarılı" sanıp durumu okuyan İKİNCİ yüzeyi (public profil butonu) invalidate etmemek (§ Follow)

> **İlgili**: architecture.md § Online-First Exemption, moderation.md (`moderate-content`), messaging.md (DM CTA + block sync), gamification.md (verified badge), edge-functions.md (`create-community-post`, `create-community-comment`, `upload-community-photo`), assets-images.md (post images)
