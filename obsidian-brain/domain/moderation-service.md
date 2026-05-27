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
| `image_safety_service.dart` | Photo NSFW/CSAM scan via `scan-image-safety` Edge Function |
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
  ├── Pre-check: bytes <= 2 MB after base64 (server budget)
  ├── POST to scan-image-safety Edge Function (JWT verified)
  ├── Decode response → ImageSafetyResult
  └── Network/parse failure → unsafe (fail-closed)
```

`ImageSafetyResult.safe` / `.unsafe(reason)` are both consumed by photo
upload flows. Reasons feed localized rejection UI.

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
2. Skipping `scan-image-safety` because "the user is premium" (no exemption)
3. Hardcoded English-only patterns (tr + de coverage required)
4. Passing raw `text` to Sentry on rejection (PII leak)
5. Storing the photo before scan completes (unsafe content on disk)

## See Also

- [[infrastructure/edge-functions]] — `moderate-content`, `scan-image-safety`
- [[features/community]] — text moderation consumer
- [[features/marketplace]] — image safety consumer
- [[patterns/assets-images]] — upload pipeline
- [[domain/services-index]]
