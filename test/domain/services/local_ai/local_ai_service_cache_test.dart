import 'dart:convert';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_cache.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('LocalAiService caching', () {
    test('analyzeGenetics reuses cached response on identical inputs', () async {
      var callCount = 0;
      final service = LocalAiService(
        cache: LocalAiCache(
          maxEntries: 4,
          ttl: const Duration(minutes: 5),
        ),
        breadcrumbSink: (_) {},
        client: MockClient((_) async {
          callCount++;
          return http.Response(
            jsonEncode({
              'response': {
                'summary': 'cached summary',
                'confidence': 'medium',
                'likely_mutations': <String>[],
                'matched_genetics': <String>[],
                'sex_linked_note': '',
                'warnings': <String>[],
                'next_checks': <String>[],
              },
            }),
            200,
          );
        }),
      );

      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final first = await service.analyzeGenetics(
        config: LocalAiConfig.defaults,
        father: father,
        mother: mother,
      );
      final second = await service.analyzeGenetics(
        config: LocalAiConfig.defaults,
        father: father,
        mother: mother,
      );

      expect(callCount, 1, reason: 'second call served from cache');
      expect(first.summary, 'cached summary');
      expect(second.summary, 'cached summary');
    });

    test('different model ids miss cache and hit the endpoint twice', () async {
      var callCount = 0;
      final service = LocalAiService(
        cache: LocalAiCache(
          maxEntries: 4,
          ttl: const Duration(minutes: 5),
        ),
        breadcrumbSink: (_) {},
        client: MockClient((_) async {
          callCount++;
          return http.Response(
            jsonEncode({
              'response': {
                'summary': 'r$callCount',
                'confidence': 'low',
                'likely_mutations': <String>[],
                'matched_genetics': <String>[],
                'sex_linked_note': '',
                'warnings': <String>[],
                'next_checks': <String>[],
              },
            }),
            200,
          );
        }),
      );

      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      await service.analyzeGenetics(
        config: LocalAiConfig.defaults,
        father: father,
        mother: mother,
      );
      await service.analyzeGenetics(
        config: LocalAiConfig.defaults.copyWith(model: 'other:latest'),
        father: father,
        mother: mother,
      );

      expect(
        callCount,
        2,
        reason: 'different model id must produce different cache key',
      );
    });

    test('failed responses are not cached', () async {
      var callCount = 0;
      final service = LocalAiService(
        cache: LocalAiCache(
          maxEntries: 4,
          ttl: const Duration(minutes: 5),
        ),
        breadcrumbSink: (_) {},
        client: MockClient((_) async {
          callCount++;
          return http.Response('boom', 500);
        }),
      );

      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      await expectLater(
        service.analyzeGenetics(
          config: LocalAiConfig.defaults,
          father: father,
          mother: mother,
        ),
        throwsA(anything),
      );
      await expectLater(
        service.analyzeGenetics(
          config: LocalAiConfig.defaults,
          father: father,
          mother: mother,
        ),
        throwsA(anything),
      );

      expect(callCount, 2, reason: 'errors must retry, not cache');
    });
  });

  group('LocalAiService breadcrumbs', () {
    test('emits success breadcrumb on cache miss path', () async {
      final breadcrumbs = <Breadcrumb>[];
      final service = LocalAiService(
        cache: LocalAiCache(
          maxEntries: 4,
          ttl: const Duration(minutes: 5),
        ),
        breadcrumbSink: breadcrumbs.add,
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'response': {
                'summary': 'ok',
                'confidence': 'high',
                'likely_mutations': <String>[],
                'matched_genetics': <String>[],
                'sex_linked_note': '',
                'warnings': <String>[],
                'next_checks': <String>[],
              },
            }),
            200,
          );
        }),
      );

      await service.analyzeGenetics(
        config: LocalAiConfig.defaults,
        father: const ParentGenotype.empty(gender: BirdGender.male),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );

      expect(
        breadcrumbs.any((b) => b.message == 'LocalAI inference success'),
        isTrue,
      );
      final success = breadcrumbs.firstWhere(
        (b) => b.message == 'LocalAI inference success',
      );
      expect(success.category, 'ai.inference');
      expect(success.level, SentryLevel.info);
      expect(success.data?['hasImage'], false);
      expect(success.data?['provider'], isNotNull);
    });

    test('emits cache hit breadcrumb on repeated call', () async {
      final breadcrumbs = <Breadcrumb>[];
      final service = LocalAiService(
        cache: LocalAiCache(
          maxEntries: 4,
          ttl: const Duration(minutes: 5),
        ),
        breadcrumbSink: breadcrumbs.add,
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'response': {
                'summary': 'ok',
                'confidence': 'high',
                'likely_mutations': <String>[],
                'matched_genetics': <String>[],
                'sex_linked_note': '',
                'warnings': <String>[],
                'next_checks': <String>[],
              },
            }),
            200,
          );
        }),
      );

      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);
      await service.analyzeGenetics(
        config: LocalAiConfig.defaults,
        father: father,
        mother: mother,
      );
      await service.analyzeGenetics(
        config: LocalAiConfig.defaults,
        father: father,
        mother: mother,
      );

      expect(
        breadcrumbs.any((b) => b.message == 'LocalAI cache hit'),
        isTrue,
      );
      final hit = breadcrumbs.firstWhere(
        (b) => b.message == 'LocalAI cache hit',
      );
      expect(hit.category, 'ai.inference.cache');
    });

    test('emits failure breadcrumb when inference throws', () async {
      final breadcrumbs = <Breadcrumb>[];
      final service = LocalAiService(
        cache: LocalAiCache(
          maxEntries: 4,
          ttl: const Duration(minutes: 5),
        ),
        breadcrumbSink: breadcrumbs.add,
        client: MockClient((_) async => http.Response('nope', 500)),
      );

      await expectLater(
        service.analyzeGenetics(
          config: LocalAiConfig.defaults,
          father: const ParentGenotype.empty(gender: BirdGender.male),
          mother: const ParentGenotype.empty(gender: BirdGender.female),
        ),
        throwsA(anything),
      );

      final failure = breadcrumbs.firstWhere(
        (b) => b.message == 'LocalAI inference failed',
      );
      expect(failure.level, SentryLevel.warning);
      expect(failure.data?['errorType'], isNotNull);
    });

    test('breadcrumb sink errors do not break inference', () async {
      final service = LocalAiService(
        cache: LocalAiCache(
          maxEntries: 4,
          ttl: const Duration(minutes: 5),
        ),
        breadcrumbSink: (_) => throw StateError('telemetry down'),
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'response': {
                'summary': 'still ok',
                'confidence': 'low',
                'likely_mutations': <String>[],
                'matched_genetics': <String>[],
                'sex_linked_note': '',
                'warnings': <String>[],
                'next_checks': <String>[],
              },
            }),
            200,
          );
        }),
      );

      final result = await service.analyzeGenetics(
        config: LocalAiConfig.defaults,
        father: const ParentGenotype.empty(gender: BirdGender.male),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );

      expect(result.summary, 'still ok');
    });
  });
}
