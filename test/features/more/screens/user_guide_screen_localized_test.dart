import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/more/screens/user_guide_screen.dart';

class _GuideAssetLoader extends AssetLoader {
  const _GuideAssetLoader();

  static const _translations = <String, Map<String, dynamic>>{
    'tr': {
      'common': {
        'no_results': 'Sonuç bulunamadı',
        'no_results_hint': 'Farklı bir arama deneyin',
      },
      'user_guide': {
        'title': 'Kullanım Kılavuzu',
        'search_hint': 'Konularda ara...',
        'category_all': 'Tümü',
        'category_getting_started': 'Başlangıç',
        'category_bird_management': 'Kuş Yönetimi',
        'category_breeding_process': 'Üreme Süreci',
        'category_tools': 'Araçlar',
        'category_data_management': 'Veri Yönetimi',
        'category_account_settings': 'Hesap ve Ayarlar',
        'tip_label': 'İpucu:',
        'warning_label': 'Uyarı:',
        'premium_feature': 'Premium',
        'topics': {
          'registration': {'title': 'Kayıt ve Giriş', 'intro': 'Kayıt intro'},
          'dashboard': {
            'title': 'Dashboard Tanıtımı',
            'intro': 'Dashboard intro',
          },
          'eggs_incubation': {'title': 'Yumurta ve Kuluçka Takibi'},
        },
      },
    },
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return _translations[locale.languageCode] ?? _translations['tr']!;
  }
}

Widget _createSubject() {
  return EasyLocalization(
    supportedLocales: const [Locale('tr')],
    fallbackLocale: const Locale('tr'),
    startLocale: const Locale('tr'),
    path: 'unused',
    assetLoader: const _GuideAssetLoader(),
    child: Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: const UserGuideScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserGuideScreen localized search', () {
    testWidgets('matches Turkish text when query omits diacritics', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'kulucka');
      await tester.pumpAndSettle();

      expect(find.text('Yumurta ve Kuluçka Takibi'), findsOneWidget);
    });

    testWidgets('matches Turkish dotless i forms in search', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'kayit');
      await tester.pumpAndSettle();

      expect(find.text('Kayıt ve Giriş'), findsOneWidget);
    });

    testWidgets('does not leak expansion state between filtered topics', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kayıt ve Giriş'));
      await tester.pumpAndSettle();

      expect(find.text('Kayıt intro'), findsOneWidget);
      expect(find.text('Dashboard intro'), findsNothing);

      await tester.enterText(find.byType(TextField), 'dashboard');
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Tanıtımı'), findsOneWidget);
      expect(find.text('Dashboard intro'), findsNothing);
    });
  });
}
