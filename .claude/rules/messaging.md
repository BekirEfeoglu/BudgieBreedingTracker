# Messaging

1-1 direkt mesajlaşma. **Online-first** (`*Repository` exemption — architecture.md § Online-First Exemption). Realtime multi-party stream, local mirror gerçek-zaman gereksinimine ters.

## Stack
| Katman | Bileşen |
|--------|---------|
| Feature | `lib/features/messaging/` (providers, screens, widgets) |
| Repository | `MessagingRepository` (online-first, no Drift table) |
| Realtime | Supabase realtime channels per conversation |
| Presence | `presence.md` ile online/typing indikator |
| Storage | `chat-attachments` bucket (conversation-scoped RLS) |
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
conversations: (id, participant_a, participant_b, last_message_at, last_message_preview)
messages: (id, conversation_id, sender_id, body, attachments, sent_at, delivered_at, read_at)
```

- Conversation deterministik ID: `min(uid_a, uid_b)_max(uid_a, uid_b)` — duplicate engeli
- `participant_*` UUID sıralı (alphabetical) — query consistency
- Group chat YOK (1-1 only)

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
| Status | Anlam | UI |
|--------|-------|----|
| sending | Client'tan henüz gitmedi | Saat ikonu |
| sent | Server kabul etti | Tek tik |
| delivered | Receiver cihaza ulaştı | Çift tik |
| read | Receiver okudu | Çift mavi tik |
| failed | Retry edilebilir | Kırmızı ünlem + retry |

## Read Receipts
- Privacy ayarı: kullanıcı kapatabilir (Settings → Messaging)
- Kapalıysa: receiver'ın "read" timestamp'i server'a yazılmaz, "delivered"da kalır
- Karşılıklı: sender de read tik göremez
- Compliance: kullanıcı verisi, opt-in default DEĞİL — UX testi gerekiyor

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
- Image (10MB max, scan-image-safety pipeline)
- Audio (1MB max, voice note 60s)
- Storage path: `chat-attachments/<conversation_id>/<message_id>/<file>`
- Bucket RLS: sadece conversation participant'ları read/write
- Signed URL TTL: 1 saat (paranoid — hassas içerik)

## Pagination
- Initial load: son 30 mesaj
- Scroll up'ta önceki 30 fetch (cursor: oldest message sent_at)
- Newest at bottom (WhatsApp UX)
- Long conversation: virtualized list (ListView.builder), memory budget

## Block & Report
- Block (community.md ile sync): conversation_blocked flag
- Blocked user mesaj gönderemez (server-side enforce, RLS)
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
3. Read receipt'i mandatory yapmak (privacy ihlali)
4. Group chat eklemeye çalışmak (1-1 only — scope creep)
5. Moderation atlamak DM diye (anti-pattern: moderation.md spam riski)
6. Optimistic insert failure'da kullanıcıya bildirmeden silmek (gaslighting)
7. Attachment URL'i public bucket (mesaj content public olur)
8. Typing indicator'ı DB'ye yazmak (realtime ephemeral olmalı)
9. Conversation ID'yi (UID_A, UID_B) ile sıralamadan üretmek (duplicate row)
10. Block'lu user'ın geçmiş mesajlarını silmek (kullanıcı kendi history'sine erişemez)

> **İlgili**: architecture.md § Online-First Exemption, presence.md (typing + online), community.md (block sync, profile lookup), notifications.md (push), moderation.md (DM threshold), assets-images.md (attachment)
