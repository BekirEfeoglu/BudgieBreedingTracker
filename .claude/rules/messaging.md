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
conversations: (id, type ['direct'|'group'], last_message_at, ...)
conversation_participants: (conversation_id, user_id, role ['owner'|'admin'|'member'], is_left, ...)
messages: (id, conversation_id, sender_id, body, sent_at, ...)
```

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
- Mesaj sırası: `sent_at` server timestamp authoritative
- Failure'da local kuyruğa koy, connectivity dönünce auto-retry (max 3)

## Delivery Status
Shipped: `Message.deliveryStatus` local-only (`@JsonKey(includeFromJson: false, includeToJson: false)`) ve server satırlarında varsayılan `sent`. `MessagingFormNotifier.sendMessage` validation/moderation geçtikten sonra aynı client id ile `sending` optimistic mesajı `messagingRealtimeProvider`'a ekler; repository başarıyla dönerse id-bazlı upsert ile `sent`, hata dönerse `failed` yapar. `MessageBubble` clock / failed / read-check göstergelerini bu local state'ten render eder. Başarısızlıkta metin korunur ve `MessageInputBar` SnackBar + `common.retry` aksiyonunu göstermeye devam eder.

## Read Receipts
- Gerçek şema: `messages.read_by` (JSONB kullanıcı ID dizisi) + `conversation_participants.last_read_at`
- **Privacy toggle henüz implement edilmedi (2026-07-02 audit):** her okuma koşulsuz kaydedilir — kullanıcının bunu kapatabileceği bir ayar (`Settings → Messaging`) kod tabanında YOK. Bu bölüm gelecek tasarım hedefidir.

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
- Shipped photo flow: `MessageInputBar` ek butonu yalnız fotoğraf seçeneğini gösterir; `MessageAttachmentService` `ImagePicker` ile 1920px / JPEG q85 seçer, `ImagePickerGuard` 10MB ön kontrolü yapar, `StorageService.uploadMessagePhoto` `scan-image-safety` sonrası `message-photos/{userId}/{conversationId}/...` path'ine yükler ve `MessagingFormNotifier.sendMessage(messageType: image, imageUrl: ...)` ile optimistic gönderir.
- `message-photos` bucket/policy migration'ı: `20260709120000_add_message_photos_storage_bucket.sql`. Fetch edilen image mesajlarında `MessagingRepository` eski signed URL'leri `StorageUrlResolver` ile tazeler.
- `birdCard`/`listingCard` render desteği var, ancak üretici UI henüz yok; gerçek seçici/producer eklenmeden bottom-sheet seçeneği gösterme.
- Genel dosya/audio attachment ve `chat-attachments` bucket tasarımı shipped değil; `chat-attachments` diye bucket yok.

## Pagination
- Initial load: son 30 mesaj
- Scroll up'ta önceki 30 fetch (cursor: oldest message sent_at)
- Newest at bottom (WhatsApp UX)
- Long conversation: virtualized list (ListView.builder), memory budget

## Block & Report
- Block: `community_blocks` tablosu (community.md ile paylaşılan, `conversation_blocked` diye ayrı bir flag YOK)
- Client-side: `blockedUsersProvider` yeni DM başlatmayı engeller ve UI'da bloklu kullanıcıyı gizler
- Server-side RLS (`messages_insert`, `participants_insert` policy'leri, migration `20260702174304_block_messages_from_blocked_users.sql`): gönderen ile conversation'daki herhangi bir aktif katılımcı arasında (iki yönde) block ilişkisi varsa insert reddedilir. **2026-07-02'de production'a deploy edildi** (Supabase MCP `apply_migration`, `security` advisor 0 yeni bulgu).
- Block sonrası geçmiş mesaj görünür (delete edilmez)
- Report: tek mesaj → `community_reports` (contextType: 'message')

## Notification Integration
- Yeni mesaj → FCM push (`notifications.md`)
- Push payload: `{ type: 'message', conversation_id, sender_name, preview }`
- Receiver app foreground'da: in-app banner, push silenced (notification.md kuralı)
- Quiet hours: `profile.notification_preferences` honored
- Group muted conversation: badge artar, push gelmez

## Empty / Error State
- Empty conversation list: "Henüz mesajınız yok" + community → DM CTA
- Empty conversation: "İlk mesajınızı gönderin" + sender info
- Network error: cached messages göster + offline banner + retry queue

## Performance
- Initial conversation load p95 < 1s
- Send latency (optimistic UI) < 50ms
- Realtime message receive < 200ms (region-dependent)
- Memory: aktif conversation max 200 mesaj in-memory
- Idle conversation list: 30sn TTL refresh

## Privacy & Security
- E2E encryption YOK (bilinçli tercih — moderation gerekli)
- Server tarafı mesajları görür ama PII redaction Sentry'de zorunlu
- Logout: aktif subscription dispose, cache clear
- Cihaz değişimi: server'da kalır, yeniden fetch

## Anti-Patterns
1. `MessagingRepository`'ye Drift table eklemek (online-first contract)
2. Realtime subscription dispose etmemek (battery + concurrent socket limit)
3. Read receipt'i mandatory yapmak (privacy ihlali — şu an zaten opt-out yok, bkz. § Read Receipts gap)
4. Grup conversation'larda block/moderation kontrolünü 1-1'e göre gevşetmek (participant sayısı arttıkça spam/abuse yüzeyi büyür)
5. Moderation atlamak DM diye (anti-pattern: moderation.md spam riski)
6. Optimistic insert failure'da kullanıcıya bildirmeden silmek (gaslighting)
7. Attachment URL'i public bucket (mesaj content public olur)
8. Typing indicator'ı DB'ye yazmak (realtime ephemeral olmalı)
9. Yeni 1-1 conversation oluştururken duplicate-check atlamak (aynı iki kullanıcı için birden fazla conversation row'u)
10. Block'lu user'ın geçmiş mesajlarını silmek (kullanıcı kendi history'sine erişemez)
11. RLS block-check migration'ını deploy etmeden "blocking server-side enforce ediliyor" varsaymak (bkz. § Block & Report deploy notu)

> **İlgili**: architecture.md § Online-First Exemption, presence.md (typing + online), community.md (block sync, profile lookup), notifications.md (push), moderation.md (DM threshold), assets-images.md (attachment)
