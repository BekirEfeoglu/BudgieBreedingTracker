# Moderation Service

Source: `.claude/rules/moderation.md` (primary — two-layer pipeline, fail-closed contract, context-aware thresholds), `.claude/rules/edge-functions.md` (moderate-content, scan-image-safety), `.claude/rules/security.md`

**Location**: `lib/domain/services/moderation/`

## Responsibility

Two complementary pipelines: text moderation for community posts/comments/
DMs, and image safety scanning for any user-uploaded photo. Both fail-closed
— if the backend is unreachable, the upload is rejected, not silently
allowed. App Store + Play Store policy hinges on this contract.

## Components

| File | Purpose |
|------|---------|
| `content_moderation_service.dart` | Text checks: local pattern allowlist + `moderate-content` Edge Function |
| `image_safety_service.dart` | Most photo flows: fail-closed `scan-image-safety` client bridge |
| `upload-community-photo` | Community-specific Edge path: validate + moderate + store |
| `moderation_providers.dart` | Riverpod wiring for both services |

## Text Moderation

```
ContentModerationService.checkText(text)
  ├── Local pattern pass: tr/en/de slur / hate / violence / spam patterns (lowercased contains())
  ├── If clean → call moderate-content Edge Function for nuanced server-side classification
  └── ModerationResult { allowed, reason?, rejectionKey? }
```

Local patterns catch obvious cases offline; server pass adds context-aware
classification (e.g. self-harm intent). Rejection reasons map to localized
`errors.moderation_*` keys.

## Image Safety

```
ImageSafetyService.scanImage({bytes, mimeType})
  ├── Client pre-check: raw bytes <= 2 MB (before base64)
  ├── POST to scan-image-safety Edge Function (JWT verified)
  ├── Edge validates MIME + estimated decoded bytes <= 2 MB
  ├── Decode response → ImageSafetyResult
  └── Network/parse failure → unsafe (fail-closed)
```

`ImageSafetyResult.safe` / `.unsafe(reason)` are both consumed by photo
upload flows. Reasons feed localized rejection UI.

Community deliberately bypasses the generic client bridge: `StorageService`
calls `upload-community-photo`, whose handler performs the same size/MIME/magic
byte and OpenAI-category checks before server-side storage.

Most UGC pickers use a 10 MB UX/storage guard, while this mandatory scan rejects
raw payloads above 2 MB. Picker-side resizing may reduce them but is not a hard
2 MB guarantee; the effective limit mismatch is tracked in [[known-gaps]].

## Fail-Closed Behavior

Every failure path (network, timeout, parse, missing JWT) resolves to
"unsafe" / "blocked." Audit findings repeatedly confirm this is the
required default — App Store rejection is the alternative. See the
2026-05-19 audit notes.

## Server-Side Authority

Local pattern checks are convenience, not security:

- They run before upload to save round-trips on obvious cases
- They MUST NOT be relied on alone — the Edge Function is the gate
- Bypassing the Edge Function (calling Supabase Storage directly) is an
  audit-flagged anti-pattern

## Anti-Patterns

1. Failing open when the Edge Function times out (App Store compliance break)
2. Skipping the mandatory safety path because "the user is premium" (no exemption)
3. Hardcoded English-only patterns (tr + de coverage required)
4. Passing raw `text` to Sentry on rejection (PII leak)
5. Storing the photo before scan completes (unsafe content on disk)

## See Also

- [[infrastructure/edge-functions]] — `moderate-content`, `scan-image-safety`
- [[features/community]] — text moderation consumer
- [[features/marketplace]] — image safety consumer
- [[patterns/assets-images]] — upload pipeline
- [[domain/services-index]]
