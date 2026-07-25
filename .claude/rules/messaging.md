# Messaging

Direkt mesajlaşma. **Online-first** (`*Repository` exemption — architecture.md § Online-First Exemption). Realtime multi-party stream, local mirror gerçek-zaman gereksinimine ters.

**Doküman düzeltmesi (2026-07-02 audit):** Bu dosya önceden "1-1 only, deterministik ID" bir tasarım belgeliyordu, ama gerçek şema ve kod tabanı **grup sohbetini de destekliyor** — `conversations`/`conversation_participants` join table (rastgele UUIDv7 conversation ID + lookup-then-create-with-retry dedup, `participant_a`/`participant_b` deterministik ID şeması DEĞİL), `group_form_screen.dart` ile grup oluşturma, `messages_screen.dart`'ta "Yeni Grup" menü öğesi, ve kendi test coverage'ı (`group_form_screen_test.dart`) mevcut ve shipped. Aşağıdaki bölümler artık gerçek şemayı yansıtıyor; "1-1 only" kısıtlaması resmi olarak kaldırıldı.

## Stack
| Katman | Bileşen |
|--------|---------|
| Feature | `lib/features/messaging/` (providers, screens, widgets) |
| Repository | `MessagingRepository` (online-first, no Drift table) |
| Realtime | Supabase realtime channels per conversation |
| Presence | `presence.md` ile online/typing indikator |
| Storage | `SupabaseConstants.messagePhotosBucket` (`message-photos`) private, user-scoped DM fotoğrafları — bkz. § Attachments |
| Moderation | `moderate-content` (DM permissive threshold) |

## Online-First Contract
- `MessagingRepository` Drift table'ı YOK
- Read: realtime subscription veya paginated fetch
- Local cache: in-memory aktif conversation, app exit'te clear
- Offline: gönderilen mesaj "pending" indicator, online olunca delivered
- Class doc'unda zorunlu:
  ```dart
  /// Online-first: realtime multi-party conversation. No local Drift mirror by design.
  ```

## Conversation Model
```
conversations: (id, type ['direct'|'group'], creator_id, name, image_url,
                last_message_content, last_message_at, last_message_user_id,
                participant_count, is_deleted, created_at, updated_at)
conversation_participants: (conversation_id, user_id, role ['owner'|'admin'|'member'],
                joined_at, last_read_at, is_muted, is_left)  -- PK (conversation_id, user_id)
messages: (id, conversation_id, sender_id, sender_name, sender_avatar_url,
                content, message_type ['text'|'image'|'birdCard'|'listingCard'],
                image_url, reference_id, reference_data, read_by, is_deleted,
                created_at)
```
Mesaj gövdesi kolonu **`content`**, zaman damgası **`created_at`**'tir —
`body`/`sent_at` diye kolon YOKTUR (`20260402110000_create_messaging_tables.sql`).

- Conversation ID: rastgele `Uuid().v7()` (participant çiftinden deterministik türetilmiyor)
- 1-1 conversation duplicate engeli: lookup-then-create-with-retry (mevcut conversation var mı önce sorgula, yoksa oluştur)
- Grup: `role` alanı owner/admin/member ayrımı yapar; katılımcı ekleme/çıkarma `conversation_participants` üzerinden
- `messages` tablosunda `attachments`/`delivered_at`/`read_at` KOLONLARI YOK; fotoğraf mesajları mevcut `image_url` + `message_type=image` alanlarını kullanır.

## Send Flow
```
User types -> Send button
  -> Client optimistic append (status: sending)
  -> Moderation (moderate-content, DM permissive)
  -> Insert messages row + update conversation.last_message_at
  -> Realtime broadcast diğer participant'a
  -> Status: sent -> delivered (receiver app açık) -> read (receiver görüntüledi)
  -> Failure: status: failed, retry button
```

- Optimistic ID client UUID
- Mesaj sırası: `created_at` server timestamp authoritative (index: `(conversation_id, created_at DESC)`)
- Failure'da local kuyruğa koy, connectivity dönünce auto-retry (max 3)

## Delivery Status
Shipped: `Message.deliveryStatus` local-only (`@JsonKey(includeFromJson: false, includeToJson: false)`) ve server satırlarında varsayılan `sent`. `MessagingFormNotifier.sendMessage` validation/moderation geçtikten sonra aynı client id ile `sending` optimistic mesajı `messagingRealtimeProvider`'a ekler; repository başarıyla dönerse id-bazlı upsert ile `sent`, hata dönerse `failed` yapar. `MessageBubble` clock / failed / read-check göstergelerini bu local state'ten render eder. Başarısızlıkta metin korunur ve `MessageInputBar` SnackBar + `common.retry` aksiyonunu göstermeye devam eder.

## Read Receipts
- Gerçek şema: `messages.read_by` (JSONB kullanıcı ID dizisi) + `conversation_participants.last_read_at`
- **Privacy toggle — shipped (2026-07-09), resiprokal:** `readReceiptsEnabledProvider` (`lib/data/providers/read_receipts_provider.dart`, `PrefBoolNotifier` → `AppPreferences.keyReadReceiptsEnabled`, default `true`). Toggle Settings → Privacy & Security'de. Kapalıyken: (1) `MessageDetailScreen._markVisibleAsRead` erken döner → `markAsRead` RPC'si çağrılmaz, `read_by`'a kullanıcı EKLENMEZ (karşı taraf okuma görmez); (2) resiprokal olarak `MessageBubble.showReadReceipts=false` ile okuma göstergesi "delivered" (tek check) ile sınırlanır (kullanıcı da başkalarının okuma durumunu görmez). **Neden güvenli:** `Conversation.unreadCount` `@JsonKey(includeFromJson:false)`, hiç doldurulmuyor — `read_by`'ı kullanıcının kendi unread takibi KULLANMIYOR, yani yazımı atlamak unread'i bozmaz. Provider `data/providers`'ta (feature değil) ki messaging cross-feature import olmadan enforce edebilsin; settings_toggle_providers re-export eder.

## Realtime Subscription
- Aktif conversation: Supabase realtime channel `conversation_<id>`
- Message insert event → UI append
- Receiver typing event → presence integration (typing indicator 3s timeout)
- Background'a giderken subscription dispose (battery)
- Foreground'a dönerken: re-subscribe + missed messages pull (last seen cursor)

## Typing Indicator
- Sender input event → debounced 500ms → broadcast typing
- Receiver "Ali yazıyor..." 3s timeout (yeni event reset)
- Realtime ephemeral channel — DB'ye yazılmaz
- Presence service ile entegre (presence.md)

## Attachments
- `messages.message_type` şeması `image`/`birdCard`/`listingCard`'ı destekler (`image_url` kolonu mevcut)
- Shipped photo flow: `MessageInputBar` ek butonu yalnız fotoğraf seçeneğini gösterir; `MessageAttachmentService` `ImagePicker` ile 1920px / JPEG q85 seçer, `ImagePickerGuard` picker sonrası raw 2 MiB UX ön kontrolü yapar, `StorageService.uploadMessagePhoto` aynı sınırı tekrar doğrulayıp `scan-image-safety` sonrası `message-photos/{userId}/{conversationId}/...` path'ine yükler ve `MessagingFormNotifier.sendMessage(messageType: image, imageUrl: ...)` ile optimistic gönderir. Bucket `file_size_limit` de 2 MiB'dir.
- `message-photos` bucket/policy migration'ı: `20260709103112_add_message_photos_storage_bucket.sql`. Fetch edilen image mesajlarında `MessagingRepository` eski signed URL'leri `StorageUrlResolver` ile tazeler.
- `birdCard`/`listingCard` render desteği var, ancak üretici UI henüz yok; gerçek seçici/producer eklenmeden bottom-sheet seçeneği gösterme.
- Genel dosya/audio attachment ve `chat-attachments` bucket tasarımı shipped değil; `chat-attachments` diye bucket yok.
- **Retry/orphan sözleşmesi (2026-07-09):** Foto yükleme `sendMessage`'den ÖNCE olduğu için gönderim reddedilirse (özellikle **cooldown**, sonraki başarılı gönderimin ardından 2 sn) Storage objesi orphan kalır. İki savunma: (1) `MessageInputBar._sendPhotoAttachment` yüklemeden ÖNCE `MessagingFormNotifier.isWithinSendCooldown` kontrol eder — cooldown'da hiç yüklemez; (2) SnackBar "tekrar dene" artık son gönderimi (`_pendingSend`) **replay eder** — fotoğraf ise **aynı yüklü URL'i reuse eder (yeniden yüklemez)** ve aynı client message id ile başarısız optimistic baloncuğu değiştirir. Ürün kararı: **reuse** (re-upload değil). Kalan sınırlı boşluk: kullanıcı başarısız fotoyu hiç retry etmeyip vazgeçerse yüklenmiş obje orphan kalır (küçük, private bucket; kabul edilir — GC scheduled job scope dışı).

## Pagination — tek sayfa (scroll-up SHIPPED DEĞİL)
- Initial load: **son 50 mesaj** (`MessagingRepository.getMessages(limit: 50)` /
  `MessageRemoteSource.fetchMessages(limit: 50)`)
- **Scroll-up ile eski mesaj yükleme YOK.** `getMessages`'ın `before` cursor
  parametresi mevcut ama hiçbir çağıran onu geçmiyor
  (`messaging_providers.dart:70` → `repo.getMessages(conversationId)`), ve
  `MessageDetailScreen._scrollController`'a `addListener` bağlanmıyor. 50'den
  eski mesajlar konuşmada erişilemez (`obsidian-brain/known-gaps.md`)
- Newest at bottom (WhatsApp UX)
- Long conversation: virtualized list (ListView.builder)

## Block & Report
- Block: `community_blocks` tablosu (community.md ile paylaşılan, `conversation_blocked` diye ayrı bir flag YOK)
- Client-side: `blockedUsersProvider` yeni DM başlatmayı engeller ve UI'da bloklu kullanıcıyı gizler
- Server-side RLS (`messages_insert`, `participants_insert` policy'leri, migration `20260702174304_block_messages_from_blocked_users.sql`): gönderen ile conversation'daki herhangi bir aktif katılımcı arasında (iki yönde) block ilişkisi varsa insert reddedilir. **2026-07-02'de production'a deploy edildi** (Supabase MCP `apply_migration`, `security` advisor 0 yeni bulgu).
- **`messages_insert` helper'lara taşındı (2026-07-14, migration `20260714200511`):** politika artık `private.is_conversation_member` + `private.sender_blocked_in_conversation` kullanır (recursion düzeltmesi değil — `messages` farklı bir relation'dır; tutarlılık + iç içe policy değerlendirmesini azaltma). **Dikkat:** `private.conversation_has_block_with` burada KULLANILAMAZ — o helper `is_left = false` filtreler, oysa orijinal `messages_insert` sohbetten AYRILMIŞ katılımcılarla olan block'ları da sayar. Bu yüzden `sender_blocked_in_conversation` ayrı bir helper'dır (is_left filtresi YOK) ve semantik birebir korunur
- **Self-join daraltması (2026-07-14, migration `20260714192445`):** `participants_insert`'in self-join dalı ARTIK sohbeti oluşturana kapsanmıştır. Öncesinde koşul çıplak `user_id = auth.uid()` idi; bir conversation UUID'sini öğrenen (deeplink, push payload, log) HERHANGİ bir authenticated kullanıcı kendini katılımcı olarak ekleyip — tüm okuma politikaları üyelik-tabanlı olduğu için (`participants_select`, `messages_participant_read`, `conversations_participant_read`) — sohbetin TÜM geçmişini okuyabiliyordu. Yeni koşul: `(user_id = auth.uid() AND private.is_conversation_creator(...)) OR private.is_conversation_manager(...)`. Bootstrap (creator kendini owner olarak ekler) ve davet (owner/admin başkasını ekler) akışları korunur; başkasının sohbetine kendini ekleme 42501 ile reddedilir. Creator kontrolü de SECURITY DEFINER helper'dan geçmek ZORUNDA: `public.conversations` üzerine çıplak alt-sorgu, caller RLS'i altında `conversations_participant_read` (üyelik ister) tarafından değerlendirilir — bootstrap anında üyelik henüz yoktur, kontrol hep false döner ve DM oluşturma kilitlenir
- **RLS recursion regresyonu (2026-07-14'te düzeltildi):** o migration block kontrolünü `participants_insert`'in `WITH CHECK`'ine **koşulsuz ham alt-sorgu** (`NOT EXISTS (… FROM conversation_participants …)`) olarak yazdı. Tablo kendi policy'si içinden okunduğu için Postgres HER katılımcı insert'ini `42P17: infinite recursion detected in policy` ile reddetti → **DM 2026-07-02'den 2026-07-14'e kadar tamamen çalışmadı** (prod kanıtı: conversations/participants/messages = 0). Bu, `20260402130000_fix_participants_rls_recursion.sql`'in aynı hatayı temizleyen düzeltmesini sessizce geri aldı. Fix: `20260714181422_fix_conversation_participants_rls_recursion.sql` — owner/admin ve block kontrolleri `private.is_conversation_manager` / `private.conversation_has_block_with` SECURITY DEFINER helper'larına taşındı (`private.is_conversation_member` deseni). Semantik korundu; block reddi hâlâ 42501 ile ateşliyor. **Kural: `conversation_participants` policy'sinin içine bu tabloyu okuyan çıplak alt-sorgu YAZMA — `private.*` SECURITY DEFINER helper üzerinden geç.**
- Block sonrası geçmiş mesaj görünür (delete edilmez)
- Report: tek mesaj → `community_reports` (contextType: 'message')

## Notification Integration — DM push SHIPPED DEĞİL
- Yeni mesaj için FCM push **gönderilmiyor**. `send-push`'ın uygulama içindeki
  tek çağıranı admin paneli (`admin_notification_manager.dart`,
  `admin_health_providers.dart`); `messages` tablosunda push tetikleyen bir
  trigger/cron da yok
- `type: 'message'` payload'ı üreten kod yok; `payloadToRoute`'ta `message`
  dalı da yok — böyle bir payload gelse `null` döner, hiçbir yere gitmez
  (notifications.md § Deeplink Payload)
- Sonuç: alıcı yalnız uygulama açıkken (realtime subscription) yeni mesajı görür
- Eklenirse: `send-push` çağıran taraf + `payloadToRoute`'a `message` dalı +
  `/messages/:id` rotası doğrulaması + quiet-hours `respectQuietHours: true`
  (non-kritik) + mute kontrolü birlikte gerekir; bu bölüm o zaman güncellenir
  (`obsidian-brain/known-gaps.md`)

## Empty / Error State
- Empty conversation list: "Henüz mesajınız yok" + community → DM CTA
- Empty conversation: "İlk mesajınızı gönderin" + sender info
- Network error: cached messages göster + offline banner + retry queue

## Performance
- Initial conversation load p95 < 1s
- Send latency (optimistic UI) < 50ms
- Realtime message receive < 200ms (region-dependent)
- Memory: **açık bir 200-mesaj in-memory cap'i YOK** — pratik sınır tek-sayfa
  fetch'in kendisidir (50 mesaj, § Pagination). Cap eklenirse burayı ve
  known-gaps'ı birlikte güncelle
- Idle conversation list: TTL'li otomatik refresh YOK; liste provider invalidate
  / pull-to-refresh ile tazelenir

## Privacy & Security
- E2E encryption YOK (bilinçli tercih — moderation gerekli)
- Server tarafı mesajları görür ama PII redaction Sentry'de zorunlu
- Logout: aktif subscription dispose, cache clear
- Cihaz değişimi: server'da kalır, yeniden fetch

## Anti-Patterns
1. `MessagingRepository`'ye Drift table eklemek (online-first contract)
2. Realtime subscription dispose etmemek (battery + concurrent socket limit)
3. Read receipt'i mandatory yapmak (privacy ihlali — `readReceiptsEnabledProvider` opt-out'unu hem yazımda hem resiprokal gösterimde honor et, bkz. § Read Receipts)
4. Grup conversation'larda block/moderation kontrolünü 1-1'e göre gevşetmek (participant sayısı arttıkça spam/abuse yüzeyi büyür)
5. Moderation atlamak DM diye (anti-pattern: moderation.md spam riski)
6. Optimistic insert failure'da kullanıcıya bildirmeden silmek (gaslighting)
7. Attachment URL'i public bucket (mesaj content public olur)
8. Typing indicator'ı DB'ye yazmak (realtime ephemeral olmalı)
9. Yeni 1-1 conversation oluştururken duplicate-check atlamak (aynı iki kullanıcı için birden fazla conversation row'u)
10. Block'lu user'ın geçmiş mesajlarını silmek (kullanıcı kendi history'sine erişemez)
11. RLS block-check migration'ını deploy etmeden "blocking server-side enforce ediliyor" varsaymak (bkz. § Block & Report deploy notu)
12. Katılımcı insert'ini kapsamsız `user_id = auth.uid()` ile açmak (conversation UUID'sini bilen herkes kendini ekleyip tüm thread'i okur — self-join dalı `private.is_conversation_creator` ile creator'a kapsanmalı, § Block & Report)
13. `conversation_participants` policy'sine bu tabloyu okuyan çıplak alt-sorgu koymak (42P17 recursion — TÜM insert'ler patlar, DM ölür; `private.*` SECURITY DEFINER helper zorunlu). Yeni bir messaging RLS policy'si yazdıktan sonra gerçek bir authenticated insert simülasyonuyla (rollback'li) doğrula — policy "mantıken doğru" görünse de recursion'a girebilir

> **İlgili**: architecture.md § Online-First Exemption, presence.md (typing + online), community.md (block sync, profile lookup), notifications.md (push), moderation.md (DM threshold), assets-images.md (attachment)
