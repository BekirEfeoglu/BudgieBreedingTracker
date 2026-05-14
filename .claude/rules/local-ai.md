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
- Image: **max 10MB** (assets-images.md ile aynı limit) — daha büyükse reject
- Image: önce client-side resize (max 1024px LLM için yeterli)
- Token budget: prompt başına max 4K input / 512 output
- Rate limit: kullanıcı başına dakikada 5 çağrı (kötüye kullanım engeli)
- Premium: limit 2x (rate limit yumuşar, daha kaliteli model)

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
- In-memory `LruCache` (max 50 entry, 1h TTL)
- Cache key: prompt hash + image hash (perceptual hash kullan, byte hash değil)
- Persist edilmez — app restart cache'i temizler
- Premium kullanıcı için server-side cache değerlendirilebilir (out of scope)

```dart
final cacheKey = '${prompt.hashCode}_${await image.perceptualHash()}';
if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
final result = await _backend.analyze(...);
_cache[cacheKey] = result;
```

## Fallback Chain
```
Try primary backend (Ollama or OpenRouter)
  -> Network/timeout error -> retry once (2s backoff)
  -> Still failing -> try other backend if configured
  -> All failed -> return AnalysisResult.unavailable() + show graceful UI
```

UI'da AI başarısız olduğunda **iş engellenmemeli** — manuel input her zaman primary path. AI bir yardımcıdır, gate değil.

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

> **İlgili**: assets-images.md (resize, 10MB), observability.md (PII), edge-functions.md (server-side AI varsa), architecture.md (online-only naming — *Service)
