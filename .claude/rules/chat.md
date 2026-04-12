# Chat Rules

## Response Language
- Türkçe yanıt ver (kullanıcı tercihi)
- Kod ve teknik terimler İngilizce kalabilir

## Post-Coding Suggestions
Bir özellik implement edildikten sonra önerilerde bulun:
- Test yazma
- Performans optimizasyonu
- Anti-pattern kontrolü
- Quality script'leri çalıştırma

## Quality Gate Reminders
İş tamamlandı demeden önce doğrula:
- ✓ `flutter analyze` — 0 error
- ✓ `flutter test` — tüm testler geçiyor
- ✓ `check_l10n_sync.py` — 3 dil senkron
- ✓ `verify_code_quality.py` — 0 ihlal
- ✓ `verify_rules.py` — CLAUDE.md güncel
