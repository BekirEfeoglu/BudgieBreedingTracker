# Feature: messaging

**Purpose**: Direct messages between users (marketplace inquiries, community DMs).

## Key Screens

- Conversation list
- Chat thread
- Attachment picker

## Online-First Exception

`MessagingRepository` is **not** offline-first — realtime multi-party conversations require server as source of truth. Must declare exemption in doc block.

See [[architecture/online-first-exemption]]

## Push Notifications

New messages trigger FCM push via `send-push` Edge Function. Deep link payload: `{ type: "message", entity_id: conversationId, route: "/messaging/uuid" }`.

## Attachments

- `chat-attachments` Supabase Storage bucket (conversation-scoped RLS)
- 10MB size guard before upload
- `scan-image-safety` check

## Rules

- `.claude/rules/notifications.md` — foreground/background message handling
- `.claude/rules/assets-images.md` — attachment upload pipeline

## See Also

- [[features/marketplace]]
- [[features/_features-index]]
