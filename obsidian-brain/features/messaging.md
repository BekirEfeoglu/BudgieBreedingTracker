# Feature: messaging

**Purpose**: 1:1 and group direct messages. Surfaces marketplace inquiries,
community DMs, and small group chats. Realtime by design — server is the
source of truth.

## Key Screens

| Screen | Route |
|--------|-------|
| `MessagesScreen` | `AppRoutes.messages` — conversation list |
| `MessageDetailScreen` | `AppRoutes.messageDetail` (`/messages/:id`) — single thread |
| `NewDmScreen` | `AppRoutes.messageNewDm` — start DM (user search + pre-filled body) |
| `GroupFormScreen` | `AppRoutes.messageGroupForm` — group creation / membership |

## Online-First Exception

`MessagingRepository` is one of the **two** exempt repositories
(community is the other) — realtime multi-party conversations cannot be
served from local mirror without losing the entire purpose.

Exemption must be declared in the file's first doc block per
[[architecture/online-first-exemption]] contract.

## Realtime

Subscribes to Supabase realtime on `messages` and `conversations` tables,
scoped to the user's memberships. Updates flow:

```
remote insert → realtime event → invalidate provider → UI re-renders → mark read receipt
```

Pull-to-refresh is a fallback; primary path is realtime push.

## Push Notifications

Out-of-app delivery via `send-push` Edge Function. Payload schema:

```json
{
  "type": "message",
  "entity_id": "conversationId",
  "route": "/messages/uuid"
}
```

App handles foreground (in-app banner, no auto-nav), background
(navigates on tap), terminated (`getInitialMessage()` post-splash).
See [[domain/notification-service]].

## Attachments

- Bucket: `chat-attachments` (conversation-scoped RLS)
- 10 MB guard
- `scan-image-safety` (fail-closed)
- Compress → JPEG q85

Multi-attachment messages bundle into one row with attachment URL array.

## Read Receipts

Realtime + Drift mirror (last-seen per-conversation, not per-message
fidelity). User can opt out via privacy settings.

## Group Chats

`group_form_screen.dart` manages create/edit. Membership stored
server-side; client never trusts local membership claims for write
authorization — RLS is the gate.

## Moderation

User-reported messages flow into [[domain/moderation-service]]
(`content_moderation_service`). Threshold-flagged messages enter the
admin review queue.

## Rules

- `.claude/rules/notifications.md` — foreground/background handling
- `.claude/rules/assets-images.md` — attachment upload
- `.claude/rules/security.md` — RLS, JWT, member-scoped access

## See Also

- [[features/marketplace]] — "contact seller" entry
- [[features/community]] — sister online-first feature
- [[domain/notification-service]] — push delivery
- [[domain/moderation-service]] — message moderation
- [[architecture/online-first-exemption]]
- [[features/_features-index]]
