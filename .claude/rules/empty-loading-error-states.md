# Empty, Loading & Error States

Veri olmayan üç durum hep var: **boş**, **yükleniyor**, **hata**. UX kalitesi bu üç state'in ne kadar iyi handle edildiğinde belli olur. Beyaz ekran asla acceptable değil.

## Shared Widget Catalog
`lib/core/widgets/` altında (`OfflineBanner` istisna — `lib/shared/widgets/`):
| Widget | Kullanım | Gerçek constructor |
|--------|----------|---------------------|
| `EmptyState` | Sonuç yok ama hata da yok (boş liste, filtre eşleşmedi) | `{icon: Widget, title, message, actionLabel: String?, onAction: VoidCallback?}` |
| `LoadingState` | Initial fetch, manuel refresh — spinner + label | `{message}` |
| `SkeletonLoader` | Tek shimmer placeholder kutusu | `{width, height, borderRadius}` — liste için tek tek örneklenir, `count`/`itemBuilder` parametresi YOK |
| `ErrorState` | Network/server hatası + retry CTA | `{message, onRetry: VoidCallback?}` — `icon` parametresi YOK (ikon dahili sabit) |
| `OfflineBanner` | Connectivity yok, ama eski veri görünüyor | `lib/shared/widgets/offline_banner.dart` |

Sadece `EmptyState` `Widget icon` parametresi alır; `LoadingState`/`ErrorState`/`SkeletonLoader` almaz (anti-pattern #14 sadece `EmptyState`, `InfoCard`, `StatCard` gibi gerçekten `icon` parametresi olan widget'lar için geçerli).

## AsyncValue Mapping
```dart
asyncValue.when(
  loading: () => const SkeletonLoader(width: double.infinity, height: 80),
  error: (e, st) => ErrorState(
    message: _errorMessage(e).tr(),
    onRetry: () => ref.invalidate(myProvider),
  ),
  data: (items) => items.isEmpty
      ? EmptyState(
          icon: AppIcon(AppIcons.bird),
          title: 'birds.no_birds_title'.tr(),
          message: 'birds.no_birds_hint'.tr(),
          actionLabel: 'birds.add_first'.tr(),
          onAction: () => context.push(AppRoutes.birdForm),
        )
      : BirdList(items),
)
```

## Loading State Spektrumu
| Süre | Pattern |
|------|---------|
| 0-100ms | Hiçbir şey göstermeden bekle (flicker önle) |
| 100-500ms | Spinner (`LoadingState`) |
| 500ms+ | Skeleton (`SkeletonLoader`) — kullanıcıya layout güveni |
| 5s+ | Skeleton + cancel option (timeout uyarısı) |

**Refresh sırasında**: eski veriyi göster, üstte küçük spinner (`skipLoadingOnRefresh: true`). Beyaz ekran flicker yapma.

```dart
asyncValue.when(
  skipLoadingOnRefresh: true,  // Eski veri görünür kalır
  loading: () => const SkeletonLoader(width: double.infinity, height: 80),
  error: (e, _) => ErrorState(message: _errorMessage(e).tr()),
  data: (items) => BirdList(items),
)
```

## Empty State Anatomi
Boş durum sadece "hiç veri yok" demek değil — kullanıcıya **next action** sun:
- **Icon**: konuyla ilgili SVG (kuş, yumurta, mesaj)
- **Title**: kısa, açıklayıcı ("Henüz kuşunuz yok")
- **Message**: 1-2 cümle açıklama veya hint
- **CTA**: birincil eylem button'u ("İlk kuşunuzu ekleyin")

```dart
EmptyState(
  icon: AppIcon(AppIcons.bird, size: 64),
  title: 'birds.no_birds_title'.tr(),
  message: 'birds.no_birds_hint'.tr(),
  actionLabel: 'birds.add_first'.tr(),
  onAction: () => context.push(AppRoutes.birdForm),
)
```

### Filter Empty (Filtre Eşleşmedi)
Boş listeden farklı: kullanıcının veri var ama filtre eşleşmiyor.
- "Sonuç bulunamadı" + "Filtreleri temizle" CTA
- Veri yok mesajı KULLANMA — kullanıcı kafası karışır

## Error State Anatomi
- **Icon**: hataya uygun (cloud-off network, alert generic)
- **Message**: l10n key, kullanıcı dostu — raw exception YOK
- **Retry CTA**: yeniden dene button'u (idempotent operasyonlarda)
- **Secondary**: "Destek'e ulaş" link (kritik feature'larda)

### Network vs Server vs Validation
| Tip | Mesaj | CTA |
|-----|-------|-----|
| `NetworkException` | "İnternet bağlantısı yok" | Retry |
| `AuthException` | "Oturum sona erdi" | "Giriş Yap" |
| `ServerException` | "Sunucuya ulaşılamadı" | Retry + Destek |
| `ValidationException` | Field-level, form'da göster | — |
| `PermissionException` | "Bu işlem için yetkiniz yok" | Geri |
| `FreeTierLimitException` | "Ücretsiz limit doldu" | Premium upgrade |

## Skeleton Loader
- `SkeletonLoader` tek bir shimmer kutusu (`width`/`height`/`borderRadius`) — liste görünümü için birden fazla örnek elle diz (bkz. `lib/features/statistics/widgets/chart_skeletons.dart`)
- Shimmer animasyonu (built-in `LinearGradient` ile)
- ListView item template ile aynı boyut/padding (jank-free transition)

```dart
Column(
  children: List.generate(5, (_) => const SkeletonLoader(width: double.infinity, height: 72)),
)
```

## Offline Banner
- App-wide banner `MaterialApp.router.builder` içinde `AppUpdatePrompt`
  ile aynı global seviyede sarılır
- "Çevrimdışı — değişiklikleriniz kaydedildi" ve pending change count gösterir
- Sync error durumunda retry CTA `forceFullSync()` çağırır
- 20 saat üstü ve max retry dolmuş sync error kayıtları için cleanup öncesi
  pre-warning gösterir; 24 saat cleanup davranışı değişmez
- Online geldiğinde kısa reconnect toast tek kaynaktan gösterilir; ekran bazlı
  duplicate SnackBar eklenmez
- Eski veriyi gösterme engel YOK — offline çalışma temel

## Accessibility
- Tüm state'ler ekran okuyucu için `Semantics.label` (`accessibility.md`)
- Loading: "Yükleniyor, lütfen bekleyin"
- Error: hata mesajı + retry button label
- Empty: title + CTA okunur şekilde

```dart
Semantics(
  label: 'common.loading'.tr(),
  child: const CircularProgressIndicator(),
)
```

## L10n Key Convention
| Pattern | Örnek |
|---------|-------|
| `<feature>.no_<entity>_title` | `birds.no_birds_title` |
| `<feature>.no_<entity>_hint` | `birds.no_birds_hint` |
| `<feature>.add_first` | `birds.add_first` |
| `errors.<error_code>` | `errors.network_unavailable` |
| `common.retry` | "Yeniden Dene" |
| `common.loading` | "Yükleniyor..." |

## Testing
```dart
testWidgets('shows empty state when no birds', (tester) async {
  await pumpWidget(tester, BirdListScreen());
  expect(find.byType(EmptyState), findsOneWidget);
  expect(find.text('birds.no_birds_title'.tr()), findsOneWidget);
});

testWidgets('shows error state with retry on network failure', (tester) async {
  when(() => mockRepo.getAll()).thenThrow(NetworkException('errors.network_unavailable'));
  await pumpWidget(tester, BirdListScreen());
  await tester.pumpAndSettle();
  expect(find.byType(ErrorState), findsOneWidget);
  expect(find.text('common.retry'.tr()), findsOneWidget);
});

testWidgets('shows skeleton while loading', (tester) async {
  await pumpWidget(tester, BirdListScreen());
  expect(find.byType(SkeletonLoader), findsOneWidget);
});
```

## Anti-Patterns
1. Beyaz ekran loading (kullanıcı app dondu zanneder)
2. `CircularProgressIndicator` çıplak — context yok (semantic label, layout)
3. Empty state'te CTA olmaması (kullanıcı next step'i bulamaz)
4. Error state'te raw exception message göstermek (`e.toString()`)
5. Refresh'te skeleton göstermek (flicker — `skipLoadingOnRefresh` zorunlu)
6. Filter empty'yi data empty ile karıştırmak (mesaj farklı olmalı)
7. Skeleton boyutunun gerçek item'la uyuşmaması (jank transition)
8. Offline banner'ı her ekrana ayrı ayrı eklemek (global Scaffold wrapper kullan)
9. Loading 100ms altında spinner göstermek (flicker)
10. Retry button'unun aslında idempotent olmadığı operasyon (duplicate insert riski)

> **İlgili**: ui-patterns.md (AsyncValue), error-handling.md (exception → message), accessibility.md (semantics), localization.md (l10n keys), background-sync.md (offline banner)
