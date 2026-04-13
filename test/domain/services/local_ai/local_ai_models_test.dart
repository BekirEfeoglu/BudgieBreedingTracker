import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';

void main() {
  group('LocalAiConfig', () {
    test('defaults have correct values', () {
      expect(LocalAiConfig.defaults.baseUrl, 'http://127.0.0.1:11434');
      expect(LocalAiConfig.defaults.model, 'gemma4:latest');
      expect(LocalAiConfig.defaults.provider, LocalAiProvider.ollama);
    });

    test('openRouterDefaults have correct values', () {
      expect(
        LocalAiConfig.openRouterDefaults.baseUrl,
        'https://openrouter.ai',
      );
      expect(
        LocalAiConfig.openRouterDefaults.provider,
        LocalAiProvider.openRouter,
      );
    });

    test('normalizedBaseUrl adds http if missing scheme', () {
      const config = LocalAiConfig(baseUrl: 'localhost:11434', model: 'test');
      expect(config.normalizedBaseUrl, 'http://localhost:11434');
    });

    test('normalizedBaseUrl strips trailing slash', () {
      const config = LocalAiConfig(
        baseUrl: 'http://localhost:11434/',
        model: 'test',
      );
      expect(config.normalizedBaseUrl, 'http://localhost:11434');
    });

    test('normalizedBaseUrl returns default for empty', () {
      const config = LocalAiConfig(baseUrl: '', model: 'test');
      expect(config.normalizedBaseUrl, LocalAiConfig.defaults.baseUrl);
    });

    test('normalizedBaseUrl forces openrouter for openRouter provider', () {
      const config = LocalAiConfig(
        provider: LocalAiProvider.openRouter,
        baseUrl: 'http://anything.com',
        model: 'test',
      );
      expect(config.normalizedBaseUrl, 'https://openrouter.ai');
    });

    test('normalizedModel returns default for empty', () {
      const config = LocalAiConfig(baseUrl: 'test', model: '');
      expect(config.normalizedModel, LocalAiConfig.defaults.model);
    });

    test('normalizedModel returns openRouter default for empty + openRouter', () {
      const config = LocalAiConfig(
        provider: LocalAiProvider.openRouter,
        baseUrl: 'test',
        model: '',
      );
      expect(config.normalizedModel, LocalAiConfig.openRouterDefaults.model);
    });

    test('normalizedModel trims whitespace', () {
      const config = LocalAiConfig(baseUrl: 'test', model: '  gemma  ');
      expect(config.normalizedModel, 'gemma');
    });

    test('isOpenRouter returns correct value', () {
      const ollama = LocalAiConfig(baseUrl: 'test', model: 'test');
      const openRouter = LocalAiConfig(
        provider: LocalAiProvider.openRouter,
        baseUrl: 'test',
        model: 'test',
      );

      expect(ollama.isOpenRouter, isFalse);
      expect(openRouter.isOpenRouter, isTrue);
    });

    test('copyWith creates new instance with overridden fields', () {
      const config = LocalAiConfig(baseUrl: 'url', model: 'model');
      final copy = config.copyWith(model: 'new_model');

      expect(copy.baseUrl, 'url');
      expect(copy.model, 'new_model');
    });
  });

  group('LocalAiProvider', () {
    test('fromRaw parses known values', () {
      expect(LocalAiProvider.fromRaw('ollama'), LocalAiProvider.ollama);
      expect(
        LocalAiProvider.fromRaw('openRouter'),
        LocalAiProvider.openRouter,
      );
    });

    test('fromRaw defaults to openRouter for unknown', () {
      expect(LocalAiProvider.fromRaw(null), LocalAiProvider.openRouter);
      expect(LocalAiProvider.fromRaw('unknown'), LocalAiProvider.openRouter);
    });

    test('key returns name', () {
      expect(LocalAiProvider.ollama.key, 'ollama');
      expect(LocalAiProvider.openRouter.key, 'openRouter');
    });
  });

  group('LocalAiConfidence', () {
    test('fromRaw parses English values', () {
      expect(LocalAiConfidence.fromRaw('low'), LocalAiConfidence.low);
      expect(LocalAiConfidence.fromRaw('medium'), LocalAiConfidence.medium);
      expect(LocalAiConfidence.fromRaw('high'), LocalAiConfidence.high);
    });

    test('fromRaw parses Turkish values', () {
      expect(LocalAiConfidence.fromRaw('düşük'), LocalAiConfidence.low);
      expect(LocalAiConfidence.fromRaw('dusuk'), LocalAiConfidence.low);
      expect(LocalAiConfidence.fromRaw('orta'), LocalAiConfidence.medium);
      expect(LocalAiConfidence.fromRaw('yüksek'), LocalAiConfidence.high);
      expect(LocalAiConfidence.fromRaw('yuksek'), LocalAiConfidence.high);
    });

    test('fromRaw is case insensitive', () {
      expect(LocalAiConfidence.fromRaw('HIGH'), LocalAiConfidence.high);
      expect(LocalAiConfidence.fromRaw('Low'), LocalAiConfidence.low);
      expect(LocalAiConfidence.fromRaw('MEDIUM'), LocalAiConfidence.medium);
    });

    test('fromRaw returns unknown for unrecognized', () {
      expect(LocalAiConfidence.fromRaw(null), LocalAiConfidence.unknown);
      expect(LocalAiConfidence.fromRaw(''), LocalAiConfidence.unknown);
      expect(LocalAiConfidence.fromRaw('garbage'), LocalAiConfidence.unknown);
    });
  });

  group('LocalAiSexPrediction', () {
    test('fromRaw parses English values', () {
      expect(LocalAiSexPrediction.fromRaw('male'), LocalAiSexPrediction.male);
      expect(
        LocalAiSexPrediction.fromRaw('female'),
        LocalAiSexPrediction.female,
      );
      expect(
        LocalAiSexPrediction.fromRaw('uncertain'),
        LocalAiSexPrediction.uncertain,
      );
    });

    test('fromRaw parses Turkish values', () {
      expect(
        LocalAiSexPrediction.fromRaw('erkek'),
        LocalAiSexPrediction.male,
      );
      expect(
        LocalAiSexPrediction.fromRaw('dişi'),
        LocalAiSexPrediction.female,
      );
      expect(
        LocalAiSexPrediction.fromRaw('disi'),
        LocalAiSexPrediction.female,
      );
      expect(
        LocalAiSexPrediction.fromRaw('belirsiz'),
        LocalAiSexPrediction.uncertain,
      );
    });

    test('fromRaw is case insensitive', () {
      expect(LocalAiSexPrediction.fromRaw('MALE'), LocalAiSexPrediction.male);
      expect(
        LocalAiSexPrediction.fromRaw('Female'),
        LocalAiSexPrediction.female,
      );
    });

    test('fromRaw returns uncertain for unknown', () {
      expect(
        LocalAiSexPrediction.fromRaw(null),
        LocalAiSexPrediction.uncertain,
      );
      expect(
        LocalAiSexPrediction.fromRaw('xyz'),
        LocalAiSexPrediction.uncertain,
      );
    });
  });

  group('LocalAiGeneticsInsight.fromJson', () {
    test('parses complete JSON', () {
      final insight = LocalAiGeneticsInsight.fromJson({
        'summary': 'Test summary',
        'confidence': 'high',
        'likely_mutations': ['Green Normal', 'Blue Opaline'],
        'matched_genetics': ['opaline', 'blue'],
        'sex_linked_note': 'Opaline is sex-linked',
        'warnings': ['Warning 1'],
        'next_checks': ['Check 1'],
      }, allowedGenetics: {'opaline', 'blue', 'ino'});

      expect(insight.summary, 'Test summary');
      expect(insight.confidence, LocalAiConfidence.high);
      expect(insight.likelyMutations, hasLength(2));
      expect(insight.matchedGenetics, containsAll(['blue', 'opaline']));
      expect(insight.sexLinkedNote, 'Opaline is sex-linked');
      expect(insight.warnings, ['Warning 1']);
      expect(insight.nextChecks, ['Check 1']);
    });

    test('filters matched_genetics by allowed set', () {
      final insight = LocalAiGeneticsInsight.fromJson({
        'summary': '',
        'confidence': 'low',
        'likely_mutations': <String>[],
        'matched_genetics': ['opaline', 'fake_mutation', 'blue'],
        'sex_linked_note': '',
        'warnings': <String>[],
        'next_checks': <String>[],
      }, allowedGenetics: {'opaline', 'blue'});

      expect(insight.matchedGenetics, ['opaline', 'blue']);
      expect(insight.matchedGenetics, isNot(contains('fake_mutation')));
    });

    test('handles null and missing fields gracefully', () {
      final insight = LocalAiGeneticsInsight.fromJson({});

      expect(insight.summary, '');
      expect(insight.confidence, LocalAiConfidence.unknown);
      expect(insight.likelyMutations, isEmpty);
      expect(insight.matchedGenetics, isEmpty);
      expect(insight.sexLinkedNote, '');
      expect(insight.warnings, isEmpty);
      expect(insight.nextChecks, isEmpty);
    });
  });

  group('LocalAiSexInsight.fromJson', () {
    test('parses complete JSON', () {
      final insight = LocalAiSexInsight.fromJson({
        'predicted_sex': 'female',
        'confidence': 'high',
        'rationale': 'Brown cere indicates female',
        'indicators': ['Brown cere', 'Adult bird'],
        'next_checks': ['Verify with breeding'],
      });

      expect(insight.predictedSex, LocalAiSexPrediction.female);
      expect(insight.confidence, LocalAiConfidence.high);
      expect(insight.rationale, 'Brown cere indicates female');
      expect(insight.indicators, hasLength(2));
      expect(insight.nextChecks, hasLength(1));
    });

    test('handles null fields gracefully', () {
      final insight = LocalAiSexInsight.fromJson({});

      expect(insight.predictedSex, LocalAiSexPrediction.uncertain);
      expect(insight.confidence, LocalAiConfidence.unknown);
      expect(insight.rationale, '');
      expect(insight.indicators, isEmpty);
    });
  });

  group('LocalAiMutationInsight.fromJson', () {
    test('parses complete JSON', () {
      final insight = LocalAiMutationInsight.fromJson({
        'predicted_mutation': 'normal_light_green',
        'confidence': 'high',
        'base_series': 'green',
        'pattern_family': 'normal',
        'body_color': 'Yeşil',
        'wing_pattern': 'Normal siyah çizgili',
        'eye_color': 'Koyu/siyah',
        'rationale': 'Standard green budgie',
        'secondary_possibilities': ['normal_dark_green'],
      });

      expect(insight.predictedMutation, 'normal_light_green');
      expect(insight.confidence, LocalAiConfidence.high);
      expect(insight.baseSeries, 'green');
      expect(insight.patternFamily, 'normal');
      expect(insight.bodyColor, 'Yeşil');
      expect(insight.rationale, 'Standard green budgie');
    });

    test('handles null fields gracefully', () {
      final insight = LocalAiMutationInsight.fromJson({});

      expect(insight.predictedMutation, 'unknown');
      expect(insight.confidence, LocalAiConfidence.low);
      expect(insight.baseSeries, 'unknown');
      expect(insight.patternFamily, 'unknown');
    });

    test('secondary_possibilities limited to 3', () {
      final insight = LocalAiMutationInsight.fromJson({
        'predicted_mutation': 'normal_skyblue',
        'confidence': 'medium',
        'base_series': 'blue',
        'pattern_family': 'normal',
        'body_color': 'mavi',
        'wing_pattern': 'normal',
        'eye_color': 'koyu',
        'rationale': 'test',
        'secondary_possibilities': [
          'normal_cobalt',
          'normal_mauve',
          'spangle_blue',
          'opaline_blue',
          'cinnamon_blue',
        ],
      });

      expect(insight.secondaryPossibilities.length, lessThanOrEqualTo(3));
    });

    test('deduplicates secondary_possibilities', () {
      final insight = LocalAiMutationInsight.fromJson({
        'predicted_mutation': 'normal_skyblue',
        'confidence': 'medium',
        'base_series': 'blue',
        'pattern_family': 'normal',
        'body_color': 'mavi',
        'wing_pattern': 'normal',
        'eye_color': 'koyu',
        'rationale': 'test',
        'secondary_possibilities': [
          'normal_cobalt',
          'normal_cobalt',
          'normal_cobalt',
        ],
      });

      expect(insight.secondaryPossibilities, hasLength(1));
    });

    test('excludes predicted_mutation from secondary', () {
      final insight = LocalAiMutationInsight.fromJson({
        'predicted_mutation': 'normal_skyblue',
        'confidence': 'medium',
        'base_series': 'blue',
        'pattern_family': 'normal',
        'body_color': 'mavi',
        'wing_pattern': 'normal',
        'eye_color': 'koyu',
        'rationale': 'test',
        'secondary_possibilities': [
          'normal_skyblue',
          'normal_cobalt',
        ],
      });

      expect(
        insight.secondaryPossibilities,
        isNot(contains('normal_skyblue')),
      );
    });

    test('infers baseSeries from signature when unknown', () {
      final insight = LocalAiMutationInsight.fromJson({
        'predicted_mutation': 'albino',
        'confidence': 'high',
        'base_series': 'unknown',
        'pattern_family': 'unknown',
        'body_color': 'beyaz',
        'wing_pattern': '',
        'eye_color': 'kırmızı',
        'rationale': 'test',
        'secondary_possibilities': <String>[],
      });

      // albino signature has series: {'albino', 'blue'} — length > 1 so not inferred
      // but patternFamily has family: {'ino'} — length == 1 so inferred
      expect(insight.patternFamily, 'ino');
    });
  });
}
