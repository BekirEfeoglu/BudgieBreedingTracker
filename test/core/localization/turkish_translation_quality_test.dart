import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> translations;

  setUpAll(() {
    translations =
        jsonDecode(File('assets/translations/tr.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  String value(String namespace, String key) {
    final section = translations[namespace] as Map<String, dynamic>;
    return section[key]! as String;
  }

  test('local AI labels preserve Turkish characters', () {
    expect(value('genetics', 'local_ai_api_key'), 'API Anahtarı');
    expect(value('genetics', 'local_ai_model_settings'), 'Model Ayarları');
    expect(
      value('genetics', 'local_ai_hint_openrouter'),
      contains('ücretsiz modeller'),
    );
    expect(
      value('genetics', 'local_ai_connection_ok'),
      contains('bağlantısı başarılı'),
    );
  });

  test(
    'admin analytics and maintenance labels preserve Turkish characters',
    () {
      expect(value('admin', 'premium_users'), 'Premium Kullanıcılar');
      expect(value('admin', 'free_users'), 'Ücretsiz Kullanıcılar');
      expect(value('admin', 'security_timeline'), 'Güvenlik Zaman Çizelgesi');
      expect(value('admin', 'maintenance_tools'), 'Bakım Araçları');
    },
  );
}
