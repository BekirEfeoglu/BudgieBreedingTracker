import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/more/screens/user_guide_screen.dart';

class _GuideAssetLoader extends AssetLoader {
  const _GuideAssetLoader();

  static const _translations = <String, Map<String, dynamic>>{
    'tr': {
      'common': {
        'no_results': 'Sonuc bulunamadi',
        'no_results_hint': 'Farkli bir arama deneyin',
      },
      'user_guide': {
        'title': 'Kullanim Kilavuzu',
        'search_hint': 'Konularda ara...',
        'category_all': 'Tumu',
        'category_getting_started': 'Baslangic',
        'category_bird_management': 'Kus Yonetimi',
        'category_breeding_process': 'Ureme Sureci',
        'category_tools': 'Araclar',
        'category_data_management': 'Veri Yonetimi',
        'category_account_settings': 'Hesap ve Ayarlar',
        'tip_label': 'Ipucu:',
        'warning_label': 'Uyari:',
        'premium_feature': 'Premium',
        'topics': {
          'registration': {
            'title': 'Kayit ve Giris',
            'subtitle': 'Hesap olusturma',
            'intro': 'Kayit intro',
          },
          'dashboard': {
            'title': 'Dashboard Tanitimi',
            'subtitle': 'Ana ekran',
            'intro': 'Dashboard intro',
          },
          'eggs_incubation': {
            'title': 'Yumurta ve Kulucka Takibi',
            'subtitle': 'Kulucka sureci',
          },
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

      expect(find.text('Yumurta ve Kulucka Takibi'), findsOneWidget);
    });

    testWidgets('matches Turkish dotless i forms in search', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'kayit');
      await tester.pumpAndSettle();

      expect(find.text('Kayit ve Giris'), findsOneWidget);
    });
  });
}
