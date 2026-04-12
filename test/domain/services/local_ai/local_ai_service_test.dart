import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';

void main() {
  group('LocalAiService.extractJsonObject', () {
    test('parses plain json', () {
      final result = LocalAiService.extractJsonObject(
        '{"summary":"ok","confidence":"high"}',
      );

      expect(result['summary'], 'ok');
      expect(result['confidence'], 'high');
    });

    test('parses fenced json with surrounding text', () {
      final result = LocalAiService.extractJsonObject('''
Here is the result:
```json
{"predicted_sex":"female","confidence":"medium"}
```
''');

      expect(result['predicted_sex'], 'female');
      expect(result['confidence'], 'medium');
    });

    test(
      'parses first balanced json object when explanation contains braces',
      () {
        final result = LocalAiService.extractJsonObject('''
Model note: use {"ignored": true} only as an example.
Actual response:
{"summary":"ok","confidence":"high","warnings":[]}
Thanks.
''');

        expect(result['summary'], 'ok');
        expect(result['confidence'], 'high');
      },
    );
  });

  group('LocalAi model parsing', () {
    test('maps sex and confidence enums', () {
      final insight = LocalAiSexInsight.fromJson({
        'predicted_sex': 'dişi',
        'confidence': 'low',
        'rationale': 'sample',
        'indicators': ['cere'],
        'next_checks': ['wait'],
      });

      expect(insight.predictedSex, LocalAiSexPrediction.female);
      expect(insight.confidence, LocalAiConfidence.low);
      expect(insight.indicators, ['cere']);
    });

    test('maps mutation insight payload', () {
      final insight = LocalAiMutationInsight.fromJson({
        'predicted_mutation': 'normal_light_green',
        'confidence': 'high',
        'base_series': 'green',
        'pattern_family': 'normal',
        'body_color': 'bright green',
        'wing_pattern': 'classic black barring',
        'eye_color': 'dark',
        'rationale': 'looks standard green',
        'secondary_possibilities': ['normal_dark_green'],
      });

      expect(insight.predictedMutation, 'normal_light_green');
      expect(insight.confidence, LocalAiConfidence.high);
      expect(insight.secondaryPossibilities, ['normal_dark_green']);
    });

    test('filters matched genetics by allowed ids', () {
      final insight = LocalAiGeneticsInsight.fromJson(
        {
          'summary': 'sample',
          'confidence': 'medium',
          'likely_mutations': ['yesil seri'],
          'matched_genetics': ['blue', 'not_real', 'ino'],
          'sex_linked_note': '',
          'warnings': [],
          'next_checks': [],
        },
        allowedGenetics: {'blue', 'ino'},
      );

      expect(insight.matchedGenetics, ['blue', 'ino']);
    });

    test('downgrades inconsistent mutation confidence', () {
      final insight = LocalAiMutationInsight.fromJson({
        'predicted_mutation': 'spangle_green',
        'confidence': 'high',
        'base_series': 'green',
        'pattern_family': 'normal',
        'body_color': 'bright green',
        'wing_pattern': 'classic black barring',
        'eye_color': 'dark',
        'rationale': 'sample',
        'secondary_possibilities': ['unknown', 'normal_light_green'],
      });

      expect(insight.confidence, LocalAiConfidence.low);
      expect(insight.secondaryPossibilities, ['normal_light_green']);
    });

    test('normalizes localized config values', () {
      const config = LocalAiConfig(baseUrl: '127.0.0.1:11434/', model: '  ');

      expect(config.normalizedBaseUrl, 'http://127.0.0.1:11434');
      expect(config.normalizedModel, LocalAiConfig.defaults.model);
    });
  });

  group('LocalAiService.testConnection', () {
    test('accepts healthy Ollama tags response', () async {
      final service = LocalAiService(
        client: MockClient((request) async {
          expect(request.url.toString(), 'http://127.0.0.1:11434/api/tags');
          return http.Response('{"models":[]}', 200);
        }),
      );

      await service.testConnection(config: LocalAiConfig.defaults);
    });

    test('throws validation exception for invalid base url', () async {
      final service = LocalAiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => service.testConnection(
          config: const LocalAiConfig(baseUrl: '://bad-url', model: 'gemma'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws network exception on non-2xx response', () async {
      final service = LocalAiService(
        client: MockClient((_) async => http.Response('oops', 503)),
      );

      expect(
        () => service.testConnection(config: LocalAiConfig.defaults),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('LocalAiService.analyzeMutationFromImage', () {
    test('throws validation exception when file does not exist', () async {
      final service = LocalAiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => service.analyzeMutationFromImage(
          config: LocalAiConfig.defaults,
          imagePath: '/tmp/does_not_exist_test_budgie.jpg',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws validation exception when image exceeds size limit', () async {
      final tmpDir = Directory.systemTemp.createTempSync('ai_test_');
      final tmpFile = File(p.join(tmpDir.path, 'large.jpg'));
      try {
        tmpFile.writeAsBytesSync(List.filled(11 * 1024 * 1024, 0));

        final service = LocalAiService(
          client: MockClient((_) async => http.Response('{}', 200)),
        );

        await expectLater(
          () => service.analyzeMutationFromImage(
            config: LocalAiConfig.defaults,
            imagePath: tmpFile.path,
          ),
          throwsA(isA<ValidationException>()),
        );
      } finally {
        tmpDir.deleteSync(recursive: true);
      }
    });
  });

  group('LocalAiService.listModels', () {
    test('returns sorted unique model names', () async {
      final service = LocalAiService(
        client: MockClient((_) async {
          return http.Response(
            '{"models":[{"name":"llama3:8b"},{"name":"gemma4:e4b"},{"name":"llama3:8b"}]}',
            200,
          );
        }),
      );

      final models = await service.listModels(config: LocalAiConfig.defaults);
      expect(models, ['gemma4:e4b', 'llama3:8b']);
    });

    test(
      'throws validation exception when models payload is invalid',
      () async {
        final service = LocalAiService(
          client: MockClient((_) async => http.Response('{"models":{}}', 200)),
        );

        expect(
          () => service.listModels(config: LocalAiConfig.defaults),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });
}
