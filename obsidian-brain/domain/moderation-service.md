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
upload flows. Reasons feed localized rejection UI. Provider kotası/rate limiti
429 döndürürse Edge, ham sağlayıcı içeriğini sızdırmadan
`safety_scan_rate_limited` koduna eşler; istemci fail-closed kalır ve kullanıcı
"biraz sonra tekrar deneyin" yönlendirmesi görür.

Community deliberately bypasses the generic client bridge: `StorageService`
calls `upload-community-photo`, whose handler performs the same size/MIME/magic
byte and OpenAI-category checks before server-side storage.

All safety-scanned UGC pickers now measure the post-picker file against the same
raw 2 MiB limit as repositories, both Edge paths, and Storage buckets. Picker
resize/quality remains best-effort; exact raw byte length is authoritative.
Base64 padding is subtracted from decoded-size estimation, so exactly 2 MiB is
accepted and one byte above is rejected.

The server limit remains 2 MiB because 10 MiB raw inflates to 13.33 MiB base64;
the Edge parser copies the request body, community upload additionally decodes
it, and the provider request is serialized again. Raising the cap would increase
transient memory/CPU and authenticated payload-amplification risk.

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
