# Chat Rules

## Response Language
- Turkce yanit ver (kullanici tercihi)
- Kod ve teknik terimler Ingilizce kalabilir
- Commit mesajlari, PR basliklari, dokumantasyon Ingilizce

## Response Style
- Kisa ve oz — gereksiz aciklama yapma
- Kod degisikliklerinden sonra ozet verme, diff yeterli
- Soru sormadan once mevcut kodu oku ve anlama cabasi goster
- Emin degilsen sor, tahminle ilerleme

## Post-Coding Suggestions
Bir ozellik implement edildikten sonra onerilerde bulun:
- Test yazma veya guncelleme
- Performans optimizasyonu
- Anti-pattern kontrolu
- Ilgili quality script'leri calistirma

## Task Completion
Is tamamlandi demeden once kalite kapilarini calistir (bkz. ai-workflow.md § Quality Gates).

## Debugging Approach
- Hata mesajini tam oku, varsayimla hareket etme
- Onceki basarili durumu kontrol et (git log, git diff)
- Generated code sorunuysa once `build_runner build` calistir
- Data flow'u izle: UI -> Provider -> Repository -> DAO/Remote
- Tek seferde birden fazla seyi degistirme — izole test et

## Code Review Feedback
- Degisikligin amacini ve etkisini acikla
- Anti-pattern tespit edersen spesifik kural numarasini belirt (CLAUDE.md § 24 rules)
- Alternatif onerirken neden daha iyi oldugunu goster

> **Ilgili**: ai-workflow.md (quality gates, prohibited actions), coding-standards.md (conventions)
