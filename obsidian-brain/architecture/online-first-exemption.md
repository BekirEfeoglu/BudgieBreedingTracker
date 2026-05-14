# Online-First Exemption

Source: `.claude/rules/architecture.md`, `.claude/rules/data-layer.md`

## Rule

A class named `*Repository` **MUST** be offline-first (Drift table + DAO + SyncMetadata) **UNLESS** it serves a **cross-user public feed or realtime multi-party stream** where the server is the source of truth by design.

## Exempt Classes

| Class | Reason |
|-------|--------|
| `CommunityPostRepository` | Cross-user public feed, chronological ordering, local mirror would not improve UX |
| `MessagingRepository` | Realtime multi-party conversations, server state is authoritative |

Exempt classes **must** declare their exemption in the first doc block:

```dart
/// Online-first: cross-user public feed. No local Drift mirror by design.
class CommunityPostRepository { ... }
```

## Naming Rule for Non-Exempt Online-Only Classes

If a class is online-only but **not** a cross-user/multi-party stream, it must **not** be named `*Repository`. Use instead:

- `*RemoteService`
- `*OnlineSource`

### Example

```dart
// CORRECT — network-mandatory, correctly named *Service
class LocalAiService { ... }

// WRONG — online-only but named Repository (lying about offline-first contract)
class ImageAnalysisRepository { ... }
```

`LocalAiService` (`lib/domain/services/local_ai/`) is the canonical example: LLM inference requires network, no Drift mirror, named `*Service`.

## Why This Matters

Naming a class `*Repository` without the offline-first contract means:
- User creates data offline → app resumes → silent data loss
- Sync service expects SyncMetadata that doesn't exist → crash

## See Also

- [[architecture/offline-first]] — the default contract
- [[data-layer/repositories]] — BaseRepository + SyncableRepository
