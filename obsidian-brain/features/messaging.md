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

Pull-to-refresh is a fallback; primary path is realtime push. On send the
sender optimistically appends the persisted message to
`messagingRealtimeProvider` (`addLocalMessage`) so it shows immediately even
when realtime is gated off by rollout flags; the merge dedupes by id against
the eventual echo (`sendMessage` returns the `Message`, and the input bar
clears only on that non-null return — wired 2026-07-02, previously the text
stayed and users double-posted).

On failure the text is preserved and the reason is surfaced:
`MessageInputBar` `ref.listen`s `messagingFormStateProvider` and shows
`state.error` (cooldown / moderation / length / network) in a SnackBar with a
`common.retry` action that re-sends the preserved text, then calls
`clearError()`.

Delivery status is local-only: `Message.deliveryStatus` is excluded from JSON
and defaults to `sent` for server rows. `MessagingFormNotifier` adds a
`sending` optimistic message after validation/moderation and before the repo
call, then id-upserts it to `sent` on success or `failed` on repository error.
`MessageBubble` renders clock / failed / read-check indicators from that state.

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

Photo attachments are wired end-to-end. `MessageInputBar` shows a single photo
option, `MessageAttachmentService` picks a compressed gallery image, the 10MB
client guard runs before upload, `StorageService.uploadMessagePhoto` scans with
`scan-image-safety`, and `MessagingFormNotifier.sendMessage` persists an
`image` message with `image_url`. `message-photos` is a private user-scoped
bucket created by migration `20260709120000_add_message_photos_storage_bucket.sql`.
Fetched image message URLs are refreshed by `StorageUrlResolver`.

`birdCard` and `listingCard` render paths still exist, but there is no producer
UI yet; do not show those bottom-sheet options until a real selector flow ships.
There is no generic `chat-attachments` bucket.

## Read Receipts

Tracked via `messages.read_by` (JSONB array of user IDs) +
`conversation_participants.last_read_at` — **not** a Drift mirror (this
repository has no local table, see § Online-First Exception). **No opt-out
exists yet (2026-07-02 audit):** every read is recorded unconditionally;
there is no privacy setting to disable it.

## Block Enforcement

Client-side (`blockedUsersProvider`) hides blocked users and blocks
*starting* a new DM; both the fetched page (`messagesProvider`) and
realtime-delivered messages honor it (the realtime merge in
`message_detail_screen.dart` gained the filter 2026-07-02 — it previously
bypassed it, so a mid-session block could still flash an in-flight realtime
message). Server-side RLS enforcement for `messages_insert` /
`participants_insert` (blocking an already-participating blocked user from
continuing to send) was added in migration
`20260702174304_block_messages_from_blocked_users.sql` — deployed to
production 2026-07-02 (via Supabase MCP `apply_migration`; `security`
advisor showed 0 new findings after applying).

## Group Chats

`group_form_screen.dart` manages create/edit. Membership stored
server-side; client never trusts local membership claims for write
authorization — RLS is the gate.

## Moderation

User-reported messages flow into [[domain/moderation-service]]
(`content_moderation_service`). Threshold-flagged messages enter the
admin review queue.

## Rules

- `.claude/rules/messaging.md` — online-first DM, conversation model, delivery status, read receipts, typing, attachments, block sync
- `.claude/rules/presence.md` — typing indicator + online badge integration
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
