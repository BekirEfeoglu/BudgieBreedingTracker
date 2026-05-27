# Content & Image Moderation

Topluluk feed, marketplace, mesajlaşma ve photo upload akışlarında **fail-closed** moderation pipeline. Apple App Store Guideline 1.2 ve Google Play UGC policy gereği zorunlu — kullanıcı tarafından oluşturulan tüm içerik publish öncesi filtrelenir.

## Stack
| Katman | Servis | Konum |
|--------|--------|-------|
| Client text filter | `ContentModerationService._checkClientSide` | `lib/domain/services/moderation/content_moderation_service.dart` |
| Server text moderation | Edge function `moderate-content` | `supabase/functions/moderate-content/` |
| Client image guard | `ImageSafetyService` (size, format) | `lib/domain/services/moderation/image_safety_service.dart` |
| Server image safety | Edge function `scan-image-safety` | `supabase/functions/scan-image-safety/` |

## Two-Layer Text Pipeline
```
User submits content
  -> Layer 1: Client keyword filter (instant, offline-capable)
     -> Hit -> reject locally, no network call
     -> Miss -> continue
  -> Layer 2: Edge function moderate-content (AI-powered)
     -> Reject -> show l10n reason, do not publish
     -> Network fail -> FAIL CLOSED (block publish, retry button)
     -> Allow -> publish
```

**Fail-closed contract**: edge function ulaşılamıyorsa içerik publish EDİLMEZ. Kullanıcıya "geçici sorun, tekrar deneyin" mesajı gösterilir. Asla bypass ile publish.

## Client Keyword Filter
- Offline-capable instant feedback
- Konum: `lib/domain/services/moderation/content_moderation_service.dart`
- Kelime listesi compile-time'da kod içinde (asla server'dan fetch — bypass riski)
- Türkçe + İngilizce + Almanca temel listeler
- False positive tolerance düşük; tartışmalı kelimeler server layer'a bırakılır

## Server Text Moderation (`moderate-content`)
- AI-powered (OpenAI moderation veya benzeri)
- JWT zorunlu (`verify_jwt = true`)
- Request: `{ content: string, contextType: 'post' | 'comment' | 'message' | 'listing' }`
- Response: `{ allowed: boolean, categories?: string[], reason?: string }`
- Rate limit: dakikada 30 çağrı/user (anti-spam)
- Log: rejection categories Sentry'ye gider, content GİTMEZ (PII koruması)

## Image Safety Pipeline
```
User picks image
  -> Client guard:
     - Size <= 10MB (anti-pattern: assets-images.md)
     - Format JPEG/PNG/HEIC
     - Dimension sanity (min 64px, max 8000px)
  -> Resize + compress (1920px max, quality 85)
  -> Server scan-image-safety:
     - NSFW model (Hive, AWS Rekognition equivalent)
     - Malware/EXIF strip
     - Content hash duplicate check
  -> Reject -> show l10n error, do not upload to Storage
  -> Allow -> upload to Storage bucket
  -> DB write with storage path
```

Server scan FAIL → upload yapılmaz. Storage'da unscanned dosya bulunmaz (zero unsafe content invariant).

## Context-Aware Rules
| Context | Threshold | Override |
|---------|-----------|----------|
| Post body | Strict | Moderator review queue |
| Comment | Strict | Auto-flag + hide pending review |
| DM | Permissive | Block list per-user (reciprocal) |
| Marketplace listing | Very strict | Premium account ek kontrol |
| Profile bio | Strict | Account-level ban risk |

DM permissive olmasının sebebi: 1-1 mesajlaşmada kullanıcı zaten block edebilir. Public broadcast'lerde (post, listing) tolerance yok.

## Rejection UX
- L10n key: `moderation.rejected_<category>` (ör. `moderation.rejected_profanity`)
- Generic fallback: `moderation.content_not_allowed`
- Kullanıcıya RAW reason göstermeme (örn. "AI confidence 0.87 toxicity") — l10n key
- Repeat offender: warning → temp ban (24h) → permanent ban (admin review)
- Ban server-side flag, client cache 5dk TTL

## Report Flow
- Kullanıcı içerik bildir → `community_reports` table'a kayıt
- Auto-flag threshold: 3 raporda gizle (pending review)
- Admin dashboard moderation queue
- Self-report ignore (user kendi içeriğini raporlayamaz)

## Edge Function Auth & Validation
- JWT zorunlu — `user_id` body'den DEĞİL claim'den
- Input validation: max content length 10K char (DoS engeli)
- Image scan: file size header check, content-type strict
- Output: typed JSON, error code l10n key'e map'lenir

## Telemetry
- Moderation log Sentry'ye sadece category + outcome (raw content ASLA)
- Approve/reject rate dashboard: false positive rate < %5 hedef
- Latency budget:
  - Client filter: < 50ms
  - Server text: < 800ms (p95)
  - Image scan: < 2s (p95) — büyük resimde 5s'e kadar tolerans

## Testing
- Unit: bilinen kötü kelime → reject, edge case (kelime parçası) → allow
- Integration: edge function happy path + auth fail + network timeout (fail-closed verify)
- Image: 10MB+, wrong format, NSFW sample (test fixture) → reject
- E2E: post → moderate → publish full flow

```dart
test('rejects content when edge function returns 5xx', () async {
  when(() => mockEdgeClient.invoke('moderate-content', any()))
      .thenThrow(EdgeFunctionException(statusCode: 500));
  final result = await service.checkText('any text');
  expect(result.isAllowed, isFalse); // FAIL CLOSED
  expect(result.rejectionReason, 'moderation.service_unavailable');
});
```

## Anti-Patterns
1. **Fail-open**: edge function fail → allow publish (release-blocker)
2. Client filter listesini server'dan fetch (kullanıcı network blok'larsa bypass)
3. Raw rejection reason'ı kullanıcıya gösterme (UX + privacy)
4. Image upload sonrası moderation (Storage'da unsafe dosya kalır)
5. Moderation log'da plaintext content (Sentry/log GDPR riski)
6. JWT verify atlamak `moderate-content` üzerinde
7. Rate limit'siz endpoint (spam vector)
8. Self-report'a izin (UX kafa karışıklığı, abuse)
9. DM'i public içerik gibi strict moderate etmek (engagement düşüşü, P2P unrealistic)
10. Marketplace listing'i post threshold'unda bırakmak (premium içerik daha strict)

> **İlgili**: edge-functions.md (`moderate-content`, `scan-image-safety`), assets-images.md (10MB guard, image pipeline), community.md (feed integration), security.md (UGC policy), observability.md (Sentry PII)
