# Accessibility (a11y)

## Hedef
WCAG 2.1 AA — kullanıcılarımızın bir kısmı yaşlı kuşbazlar, ekran okuyucu / büyük yazı / yüksek kontrast tercih eden kullanıcılar var. Erişilebilirlik release-blocker'dır.

## Touch Target (Dokunma Hedefi)
- Minimum **48x48 dp** her interaktif öğe için (WCAG 2.5.5)
- `IconButton` varsayılan boyutu yetersiz — `constraints: BoxConstraints(minWidth: 48, minHeight: 48)` zorunlu
- `verify_code_quality.py` → `check_iconbutton_constraints` bu kuralı tarar
- İkonlar arası min **8 dp** boşluk (yanlış basma riskini düşür)

```dart
// CORRECT
IconButton(
  icon: AppIcon(AppIcons.edit),
  onPressed: _onEdit,
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
)

// WRONG - default 32x32 if dense
IconButton(
  icon: AppIcon(AppIcons.edit),
  onPressed: _onEdit,
)
```

## Semantic Labels
- Her interaktif öğenin `Semantics` etiketi olmalı (ekran okuyucu)
- `IconButton(tooltip: 'birds.edit_bird'.tr())` — tooltip otomatik olarak semantic label olur
- Sadece dekoratif görseller: `Semantics(excludeSemantics: true, child: ...)`
- Form alanları: `TextFormField(decoration: InputDecoration(labelText: 'birds.name'.tr()))` — labelText semantic'e gider

```dart
// İkon-only button — açık etiket gerekli
IconButton(
  icon: AppIcon(AppIcons.delete),
  tooltip: 'common.delete'.tr(),
  onPressed: _onDelete,
)

// Görsel + metin kombinasyonu — Semantics ile birleşir
Semantics(
  label: 'birds.bird_card_label'.tr(namedArgs: {'name': bird.name}),
  child: BirdCard(bird: bird),
)
```

## Renk & Kontrast
- Metin/arka plan kontrast oranı **min 4.5:1** (normal metin) / **3:1** (büyük metin)
- Sadece renk ile bilgi iletme: cinsiyet / sağlık / durum mutlaka ikon + metin ile desteklenmeli
- Genetik fenotip renkleri istisna — kontrast yerine biyolojik doğruluk önceliği (rules: data-layer.md)
- Dark mode test edilmeli — `Theme.of(context).colorScheme` kullan, hardcoded renk yok

## Yazı Tipi & Ölçeklendirme
- Kullanıcı sistem ölçeklendirmesini onurlandırmak zorunlu — `MediaQuery.textScalerOf(context)`
- Sabit yükseklik vermek YERİNE `IntrinsicHeight` veya esnek layout kullan
- Min font boyutu **12sp**, varsayılan **14sp**, başlık **16sp+**
- `Theme.of(context).textTheme` kullan, hardcoded `TextStyle(fontSize: 14)` etme

## Klavye & Focus
- `FocusNode` kullanılan formlarda — `dispose()` zorunlu
- `Focus` zinciri: form alanları arasında `TextInputAction.next` ile ilerle
- Submit edilen son alanda `TextInputAction.done`
- `autofocus: true` — sadece formun ilk kritik alanında

## L10n & Yön
- 3 dil destekli (tr/en/de) — uzun çeviriler için `Wrap` veya `FittedBox` kullan
- Almanca compound kelimeler taşar — `overflow: TextOverflow.ellipsis` + `tooltip` zorunlu
- RTL desteği şu an yok ama gelecek için `EdgeInsetsDirectional.only(start:)` tercih et

## Loading & Error State
- `CircularProgressIndicator` yerine `LoadingState` widget'ı (semantic label içerir)
- `ErrorState` widget'ı: ikon + l10n metin + retry button
- Boş durumlar: `EmptyState` ile açık bir CTA

## Test
```dart
testWidgets('button has min 48dp tap target', (tester) async {
  await pumpWidget(tester, MyButton());
  final size = tester.getSize(find.byType(IconButton));
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
});

testWidgets('icon button has tooltip', (tester) async {
  await pumpWidget(tester, MyIconButton());
  expect(find.byTooltip('common.delete'.tr()), findsOneWidget);
});
```

## Anti-Patterns
1. `IconButton` constraints olmadan (otomatik 48dp altına düşer)
2. Tooltip'siz icon-only button (ekran okuyucu için sessiz)
3. Sadece renk ile bilgi (color blind kullanıcı)
4. Hardcoded `fontSize` (sistem ölçeklendirmesini bozar)
5. `width: 200` gibi sabit boyut metin içeren widget'lara
6. `excludeSemantics: true` istemeden (etiketsiz interaktif element)
7. `Container` üzerinde `onTap` (semantic role yok — `InkWell`/`GestureDetector` + `Semantics`)

> **İlgili**: ui-patterns.md (shared widgets), localization.md (3 dil), coding-standards.md (Theme kullanımı)
