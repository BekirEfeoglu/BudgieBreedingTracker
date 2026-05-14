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
- Rate limit: 5 calls/min per user (premium: 2×)

## Caching

- `LruCache` (in-memory, max 50 entries, 1h TTL)
- Cache key: prompt hash + perceptual image hash (not byte hash)
- App restart clears cache

## Confidence Thresholds

- Confidence < 0.7 → show as "tahmin" (estimate), no auto-save
- Confidence ≥ 0.7 → user review + accept to save
- Confidence = 1.0 → suspect (LLMs are overconfident)

## Fallback Chain

```
Primary backend
  → NetworkException → retry once (2s backoff)
  → Still failing → try other backend (if configured)
  → All failed → AnalysisResult.unavailable() + graceful UI
```

AI failure must **never block the user** — manual input is always the primary path.

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
- [[patterns/assets-images]] — 10MB guard, image resize
- [[patterns/observability]] — PII rules
- [[domain/services-index]]
