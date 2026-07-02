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

**Not wired up yet (2026-07-02 audit):** `message_input_bar.dart`'s attach
button is fully stubbed (`onTap: Navigator.pop`) — there is no working
gallery/camera attachment flow. `SupabaseConstants.messagePhotosBucket`
(`message-photos`) is defined but has zero call sites. `messages.image_url`
+ `message_type` (`image`/`birdCard`/`listingCard`) schema support exists,
so a future attachment flow has somewhere to write to, but the 10MB guard /
`scan-image-safety` / compress pipeline described in `.claude/rules/messaging.md`
is a design target, not shipped behavior.

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
