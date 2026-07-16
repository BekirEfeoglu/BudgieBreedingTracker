# Local AI Service

Source: `.claude/rules/local-ai.md`

**Location**: `lib/domain/services/local_ai/local_ai_service.dart`

**Type**: Online-only — no Drift mirror. Correctly named `*Service`.

## Purpose

LLM-based analysis for budgerigar photos (gender/mutation prediction) and text helpers (care suggestions, genetics summarization).

## Backend Routing

| Backend | When | Cost |
|---------|------|------|
| Ollama | User configures own server (advanced setting) | Free, high latency |
| OpenRouter | Default (cloud LLM) | Pay-per-token |

## Size & Cost Guards

- Max image: **10MB** (same limit as assets-images.md)
- Client-side resize to max 1024px before sending (lower token cost)
- Token budget: max 4K input / 512 output per prompt
- Rate limit: **no client-side limiter today**. The only real bound is the in-memory
  `LocalAiCache` (8 entries / 10 min) — a cache, not a limiter. OpenRouter HTTP 429
  maps to `genetics.local_ai_error_rate_limit`, but that is the upstream provider's
  limit, not app-enforced. "N calls/min per user" + premium 2× is future server-side
  work (consistent with local-ai.md Anti-Pattern #6) — see [[known-gaps]]

## Caching

- `LocalAiCache` (in-memory, max **8** entries, **10-minute** TTL — `lib/domain/services/local_ai/local_ai_service.dart`)
- Cache key: SHA-1 byte hash of image bytes (`_imageCacheToken`) — NOT a perceptual hash; a small edit to the same photo is a cache miss (known limitation, see rules `local-ai.md` § Anti-Patterns #5)
- App restart clears cache

## Confidence Thresholds

- Confidence < 0.7 → show as "tahmin" (estimate), no auto-save
- Confidence ≥ 0.7 → user review + accept to save
- Confidence = 1.0 → suspect (LLMs are overconfident)

## Fallback Chain

Actual behavior is **fail-fast, single backend, typed error** (`local_ai_transport.dart`):

```
Transport routes to ONE backend: config.isOpenRouter ? OpenRouter : Ollama
  → first network/timeout/parse failure THROWS a typed exception
    (NetworkException / ValidationException, genetics.local_ai_error_* l10n key)
  → NO retry, NO 2s backoff, NO cross-backend fallback
  → surfaces via AsyncValue.guard (local_ai_providers.dart) → AsyncError → UI ErrorState
```

- There is no `AnalysisResult.unavailable()` type; models are
  `LocalAiGeneticsInsight` / `LocalAiSexInsight` / `LocalAiMutationInsight`.
- The contract still holds: AI failure **never blocks the user** — manual input and
  the deterministic calculator remain the primary path.

**Unshipped (see [[known-gaps]]):** retry-once + 2s backoff and cross-backend
fallback are a future enhancement, not implemented today.

## PII Redaction

- Never include email, phone, birth dates in prompts
- Bird name OK; raw health record text → anonymize first
- Log only first 200 characters of prompt
- Never send prompt content to Sentry — only metadata (backend, latency, success)

## Prompt Settings

- Temperature: 0.2 (deterministic for genetics)
- Response in user's locale (`tr`, `en`, `de`)
- JSON schema response format for structured output

## `founderAiGuard`

Gates heavy AI features to founder/admin accounts only in development. Always returns `false` in production.

## See Also

- [[domain/genetics-engine]] — AI confidence integration
- [[patterns/assets-images]] — picker sizing and file guard patterns
- [[patterns/observability]] — PII rules
- [[domain/services-index]]
