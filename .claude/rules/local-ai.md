# Local AI (LocalAiService)

LLM-tabanlı image analysis ve text inference. `LocalAiService` (`lib/domain/services/local_ai/`) online-only — yerel Drift mirror yok, sadece kısa süreli in-memory cache.

## Routing
İki backend desteklenir, runtime config'e göre seçilir:
| Backend | Kullanım | Maliyet |
|---------|----------|---------|
| **Ollama** | Kullanıcı kendi sunucusunu çalıştırırsa (advanced setting) | Bedava, latency yüksek |
| **OpenRouter** | Default cloud LLM | Pay-per-token |

Routing logic: kullanıcı Ollama endpoint set ettiyse Ollama, yoksa OpenRouter.

## Use Cases
- **Photo analysis**: kuş fotoğrafından cinsiyet/mutasyon ön-tahmin
- **Text helper**: bakım önerisi, genetik özetleme
- **Translation fallback**: l10n eksik dilde otomatik (kısıtlı)

AI çıktısı ASLA tek yetkili — kullanıcı her zaman manuel override edebilmeli (confidence düşükse default).

## Cost & Size Guards
- Image: **max 10MB** kendi işleme bütçesi — safety-scanned UGC'nin 2 MiB raw
  upload sözleşmesinden ayrıdır; daha büyükse reject
- Image: önce client-side resize (max 1024px LLM için yeterli)
- Token budget: prompt başına max 4K input / 512 output
- Rate limit: **client-side rate limiter YOK** (bugün). Tek gerçek sınır in-memory
  `LocalAiCache` (8 entry / 10 dk) — bu bir cache, limiter DEĞİL. OpenRouter HTTP
  429 `genetics.local_ai_error_rate_limit`'e eşlenir ama bu upstream sağlayıcı
  sınırıdır, uygulama enforce etmez. "Kullanıcı başına dakikada N çağrı" + premium
  2x yumuşatma **gelecek server-side işidir** (bu dosyanın Anti-Pattern #6'sıyla
  tutarlı — client-side hardcode etme); shipped kabul etme (known-gaps.md)

```dart
const maxImageBytes = 10 * 1024 * 1024;

Future<AnalysisResult> analyzeBirdPhoto(File image) async {
  if (await image.length() > maxImageBytes) {
    throw ValidationException('errors.image_too_large');
  }
  final resized = await _resizeForLlm(image, maxDim: 1024);
  return _service.analyze(resized);
}
```

## Caching
- In-memory `LocalAiCache` (max **8** entry, **10 dakika** TTL — `lib/domain/services/local_ai/local_ai_service.dart`)
- Cache key: SHA-1 byte hash of image bytes (`_imageCacheToken`) — perceptual hash DEĞİL; küçük bir edit aynı fotoğrafı cache miss yapar (bkz. Anti-Patterns #5, bu bilinen bir sınırlama)
- Persist edilmez — app restart cache'i temizler
- Premium kullanıcı için server-side cache değerlendirilebilir (out of scope)

```dart
final cacheKey = _sha1Hex(imageBytes);
if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
final result = await _backend.analyze(...);
_cache[cacheKey] = result;
```

## Fallback Chain
Gerçek davranış **fail-fast, tek backend, typed error** (`local_ai_transport.dart`):
```
Transport tek backend'e router'lanır: config.isOpenRouter ? OpenRouter : Ollama
  -> İlk network/timeout/parse hatasında typed exception FIRLATIR:
     NetworkException / ValidationException (genetics.local_ai_error_* l10n key ile)
  -> retry YOK, 2s backoff YOK, diğer backend'e cross-fallback YOK
  -> Hata local_ai_providers.dart'ta AsyncValue.guard ile AsyncError'a düşer
     -> UI ErrorState gösterir
```
- `AnalysisResult.unavailable()` diye bir tip **yoktur**; model tipleri
  `LocalAiGeneticsInsight` / `LocalAiSexInsight` / `LocalAiMutationInsight`
- **Sözleşme korunur:** AI başarısız olsa da **iş engellenmez** — manuel input ve
  deterministik hesaplayıcı her zaman primary path'tir. AI yardımcıdır, gate değil.

**Gelecek (unshipped, bkz. known-gaps.md):** retry-once + 2s backoff ve config
edilmişse diğer backend'e cross-fallback bir gelecek iyileştirmesidir — bugün YOK.
Eklenirse bu bölüm gerçek mekaniğiyle güncellenmeli.

## PII Redaction
- Asla kullanıcı email, profil adı, telefon prompt'a koyma
- Bird name OK (kullanıcı kendi kuşu)
- Sağlık kaydı ham metni: anonimize et veya kullanma
- Log'lara prompt yazarken ilk 200 karakter (`prompt.substring(0, min(200, prompt.length))`)
- Sentry'ye AI prompt İÇERİĞİ gönderme — sadece metadata (backend, latency, success)

## Prompt Engineering
- Sistem prompt'u Dart sabit, `assets/prompts/<task>.txt` referansı değil (build size)
- Localize prompt: kullanıcının dilinde response iste (`tr`, `en`, `de`)
- Temperature 0.2 (deterministik, genetik tahmin için kritik)
- JSON schema response için `response_format` parametresi (OpenRouter)
- Output parse'ı fail-safe: bozuk JSON için fallback message

```dart
final systemPrompt = '''
You are an avian genetics expert. Analyze the budgie photo.
Respond in $userLocale.
Output ONLY valid JSON with keys: gender, confidence, mutations (array).
''';
```

## Confidence Threshold
- Confidence < 0.7 → kullanıcıya "tahmin" olarak göster, otomatik kaydetme
- Confidence >= 0.7 → öneri olarak göster, kullanıcı kabul ederse kaydet
- Confidence 1.0 görsen ŞÜPHELEN — LLM'ler overconfident olabilir

## Streaming
- Uzun text output için streaming response (OpenRouter SSE)
- UI typing indicator, kısmi token'lar göster
- Kullanıcı cancel edebilmeli (timer + abort token)

## Testing
- Unit: backend mock, AnalysisResult parse path'leri
- Integration: tek bir gerçek call sandbox endpoint'e (rate-limited)
- Cost test: token sayısı assertion'ı (`expect(usage.totalTokens, lessThan(2000))`)
- Asla CI'da gerçek paid LLM çağrısı (mock zorunlu)

```dart
test('caches identical prompts', () async {
  when(() => mockBackend.analyze(any())).thenAnswer((_) async => fakeResult);
  await service.analyzePhoto(file);
  await service.analyzePhoto(file);
  verify(() => mockBackend.analyze(any())).called(1);
});
```

## Founder AI Guard
`founderAiGuard` (audit 2026-04-19) sadece founder/admin için aktif heavy feature'ları gate'ler. Production'da bu provider hep `false` döner — geliştirme amaçlı.

## Anti-Patterns
1. AI yanıtını ground truth saymak (her zaman kullanıcı override)
2. Image resize'siz LLM'e göndermek (token maliyeti + latency)
3. PII'yi prompt'a sızdırmak (email, full name)
4. Sentry'ye prompt içeriği göndermek (gizlilik + storage)
5. Cache key'i byte hash ile (aynı fotoğrafın küçük edit'i cache miss)
6. Rate limit'i client-side hardcode (server-side enforcement zorunlu, gelecek)
7. JSON parse fail'de exception fırlatıp UI'ı kırmak (graceful fallback)
8. Temperature yüksek (genetik tahmin için non-deterministic)
9. Pay-per-token endpoint'i test'te canlı çağırmak (faturalı sürpriz)

> **İlgili**: assets-images.md (resize, scanned vs Local AI size contracts), observability.md (PII), edge-functions.md (server-side AI varsa), architecture.md (online-only naming — *Service)
