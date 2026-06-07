# BudgieBreedingTracker Marketing Operations Kit

Bu klasör Facebook ve Instagram reklam/icerik operasyonunu güvenli şekilde yürütmek için hazırlanmıştır. Amaç soğuk DM atmak değil; içerik, reklam, lead formu ve kullanıcı başlatmalı mesajlar üzerinden izinli talep toplamaktır.

## Dosyalar

| Dosya | Amaç |
| --- | --- |
| `design.md` | Kapsam, veri akışı, agent sınırları ve başarı metrikleri |
| `meta-campaign-briefs.md` | Meta Lead Ads, click-to-message ve retargeting kampanya brief'leri |
| `content-calendar-30-days.csv` | 30 günlük Reels, carousel, story ve post takvimi |
| `inbound-agent-playbook.md` | Gelen yorum/DM/form agent kuralları ve iş akışı |
| `agent-system-prompt.md` | Agent için doğrudan kullanılabilir system prompt |
| `message-templates.md` | Onaylı mesaj ve yorum cevap şablonları |
| `facebook-group-outreach.md` | Facebook kuş grupları için izinli outreach playbook'u |
| `facebook-group-outreach-tracker.csv` | Grup adayları, admin izni ve paylaşım durum takip tablosu |
| `crm-template.csv` | Sheet/CRM import şablonu |
| `weekly-dashboard-template.md` | Haftalık KPI ve karar şablonu |
| `link-map.md` | Uygulama, lead magnet ve UTM link haritası |
| `launch-7-day-plan.md` | İlk 7 gün için Meta yayın ve otomasyon uygulama planı |
| `assets/free-incubation-tracker-template.csv` | Lead magnet olarak paylaşılacak ücretsiz kuluçka takip tablosu |

## Ana Prensip

Soğuk DM yok. Kullanıcı bir form doldurmuş, reklama tıklayıp mesaj başlatmış, yorumda bilgi istemiş veya açıkça iletişim izni vermiş olmalı.

## Haftalık Operasyon Ritmi

Pazartesi:

- Önceki haftanın KPI raporunu çıkar.
- En iyi 3 içerik ve en zayıf 3 içeriği belirle.
- Reklam bütçesini lead kalitesine göre yeniden dağıt.

Salı-Perşembe:

- Reels, carousel ve story içeriklerini yayınla.
- Yorum ve DM'leri agent ile sınıflandır.
- İnsan onayından geçen cevapları gönder.

Cuma:

- Lead form kayıtlarını CRM'e işle.
- Opt-in follow-up listesini kontrol et.
- Sık sorulan sorulardan gelecek hafta içerik başlığı çıkar.

Hafta sonu:

- Topluluk gruplarında reklam yerine `facebook-group-outreach.md` kurallarına göre izinli faydalı içerik paylaş.
- Mikro influencer ve petshop iş birlikleri için liste güncelle.

## İlk 30 Gün Hedefleri

| Metrik | Hedef |
| --- | ---: |
| Yayınlanan içerik | 30 |
| Lead formu | 150+ |
| DM konuşması | 50+ |
| Store tıklaması | 100+ |
| Uygulama indirme | 50+ |
| Yanıt süresi | < 12 saat |

## UTM Standardı

Tüm linklerde şu desen kullanılmalı:

```text
utm_source=facebook|instagram
utm_medium=organic|paid|dm|lead_form
utm_campaign=YYYYMM_topic
utm_content=creative_or_template_name
```

Örnek:

```text
https://budgiebreedingtracker.online/?utm_source=instagram&utm_medium=organic&utm_campaign=202606_incubation_tracker&utm_content=reels_day01
```

## Aktif Linkler

- Uygulama/landing linki: `https://budgiebreedingtracker.online/`
- Ücretsiz kuluçka takip tablosu: `docs/marketing/assets/free-incubation-tracker-template.csv`
- Paylaşımda kullanılacak UTM'li linkler için `link-map.md` kullanılmalı.
