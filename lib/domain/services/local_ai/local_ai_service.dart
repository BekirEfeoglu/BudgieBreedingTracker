import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'local_ai_cache.dart';
import 'local_ai_models.dart';
import 'local_ai_prompts.dart';

part 'local_ai_transport.dart';

/// L10n error key prefix used by UI to detect translatable exception messages.
const _kErrorPrefix = 'genetics.local_ai_error_';

class LocalAiService {
  LocalAiService({
    http.Client? client,
    LocalAiCache? cache,
    void Function(Breadcrumb)? breadcrumbSink,
  }) : _transport = _LocalAiTransport(client: client ?? http.Client()),
       _cache =
           cache ??
           LocalAiCache(maxEntries: 8, ttl: const Duration(minutes: 10)),
       _breadcrumbSink = breadcrumbSink ?? Sentry.addBreadcrumb;

  final _LocalAiTransport _transport;
  final LocalAiCache _cache;
  final void Function(Breadcrumb) _breadcrumbSink;

  void dispose() => _transport.dispose();

  @visibleForTesting
  LocalAiCache get cache => _cache;

  Future<LocalAiGeneticsInsight> analyzeGenetics({
    required LocalAiConfig config,
    required ParentGenotype father,
    required ParentGenotype mother,
    String? fatherName,
    String? motherName,
    List<OffspringResult> calculatorResults = const [],
  }) async {
    final allowedGenetics = LocalAiPrompts.collectAllowedGenetics(
      father: father,
      mother: mother,
      calculatorResults: calculatorResults,
    );
    final prompt = LocalAiPrompts.buildGeneticsPrompt(
      father: father,
      mother: mother,
      fatherName: fatherName,
      motherName: motherName,
      calculatorResults: calculatorResults,
      allowedGenetics: allowedGenetics,
    );
    final payload = await _generateCached(
      config: config,
      system: LocalAiPrompts.systemGenetics,
      prompt: prompt,
      numPredict: 400,
      cacheKey: _buildCacheKey(
        config: config,
        kind: 'genetics',
        prompt: prompt,
      ),
    );
    return LocalAiGeneticsInsight.fromJson(
      payload,
      allowedGenetics: allowedGenetics.map((entry) => entry.id).toSet(),
    );
  }

  Future<LocalAiSexInsight> analyzeSex({
    required LocalAiConfig config,
    required String observations,
    String? imagePath,
  }) async {
    List<String> images = const [];
    String? imageToken;
    if (imagePath != null) {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw const ValidationException('${_kErrorPrefix}image_not_found');
      }
      final stat = await file.stat();
      if (stat.size > AppConstants.maxLocalAiImageBytes) {
        throw const ValidationException('${_kErrorPrefix}image_too_large');
      }
      imageToken = _imageCacheToken(path: imagePath, stat: stat);
      images = [base64Encode(await file.readAsBytes())];
    }

    final system = imagePath != null
        ? LocalAiPrompts.systemSexWithImage
        : LocalAiPrompts.systemSex;
    final trimmedObservations = observations.trim();
    final payload = await _generateCached(
      config: config,
      system: system,
      prompt: trimmedObservations,
      images: images,
      numPredict: 300,
      cacheKey: _buildCacheKey(
        config: config,
        kind: imagePath != null ? 'sex_image' : 'sex',
        prompt: trimmedObservations,
        imageToken: imageToken,
      ),
    );
    return LocalAiSexInsight.fromJson(payload);
  }

  Future<LocalAiMutationInsight> analyzeMutationFromImage({
    required LocalAiConfig config,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const ValidationException('${_kErrorPrefix}image_not_found');
    }

    final stat = await file.stat();
    if (stat.size > AppConstants.maxLocalAiImageBytes) {
      throw const ValidationException('${_kErrorPrefix}image_too_large');
    }

    const prompt = 'Analyze this budgerigar photo.';
    final payload = await _generateCached(
      config: config,
      system: LocalAiPrompts.systemMutationImage,
      prompt: prompt,
      images: [base64Encode(await file.readAsBytes())],
      numPredict: 350,
      cacheKey: _buildCacheKey(
        config: config,
        kind: 'mutation_image',
        prompt: prompt,
        imageToken: _imageCacheToken(path: imagePath, stat: stat),
      ),
    );
    return LocalAiMutationInsight.fromJson(payload);
  }

  Future<void> testConnection({required LocalAiConfig config}) async {
    return _transport.testConnection(config: config);
  }

  Future<List<String>> listModels({required LocalAiConfig config}) async {
    return _transport.listModels(config: config);
  }

  Future<Map<String, dynamic>> _generateCached({
    required LocalAiConfig config,
    required String prompt,
    required String cacheKey,
    String? system,
    List<String> images = const [],
    int numPredict = 400,
  }) async {
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      _emitBreadcrumb(
        message: 'LocalAI cache hit',
        category: 'ai.inference.cache',
        level: SentryLevel.info,
        data: {
          'provider': config.provider.key,
          'model': config.normalizedModel,
          'hasImage': images.isNotEmpty,
          'imageCount': images.length,
          'promptChars': prompt.length,
          'tokenBudget': numPredict,
        },
      );
      return cached;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await _generate(
        config: config,
        prompt: prompt,
        system: system,
        images: images,
        numPredict: numPredict,
      );
      stopwatch.stop();
      _cache.put(cacheKey, result);
      _emitBreadcrumb(
        message: 'LocalAI inference success',
        category: 'ai.inference',
        level: SentryLevel.info,
        data: {
          'provider': config.provider.key,
          'model': config.normalizedModel,
          'hasImage': images.isNotEmpty,
          'imageCount': images.length,
          'promptChars': prompt.length,
          'tokenBudget': numPredict,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );
      return result;
    } catch (error) {
      stopwatch.stop();
      _emitBreadcrumb(
        message: 'LocalAI inference failed',
        category: 'ai.inference',
        level: SentryLevel.warning,
        data: {
          'provider': config.provider.key,
          'model': config.normalizedModel,
          'hasImage': images.isNotEmpty,
          'imageCount': images.length,
          'promptChars': prompt.length,
          'tokenBudget': numPredict,
          'durationMs': stopwatch.elapsedMilliseconds,
          'errorType': error.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }

  void _emitBreadcrumb({
    required String message,
    required String category,
    required SentryLevel level,
    Map<String, dynamic>? data,
  }) {
    try {
      _breadcrumbSink(
        Breadcrumb(
          message: message,
          category: category,
          level: level,
          data: data,
        ),
      );
    } catch (_) {
      // Breadcrumbs are best-effort; never let telemetry break inference.
    }
  }

  String _buildCacheKey({
    required LocalAiConfig config,
    required String kind,
    required String prompt,
    String? imageToken,
  }) {
    final bytes = utf8.encode(
      [
        kind,
        config.provider.key,
        config.normalizedModel,
        prompt,
        imageToken ?? '',
      ].join('\u0001'),
    );
    return sha1.convert(bytes).toString();
  }

  String _imageCacheToken({required String path, required FileStat stat}) {
    return '$path|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
  }

  Future<Map<String, dynamic>> _generate({
    required LocalAiConfig config,
    required String prompt,
    String? system,
    List<String> images = const [],
    int numPredict = 400,
  }) async {
    return _transport.generate(
      config: config,
      prompt: prompt,
      system: system,
      images: images,
      numPredict: numPredict,
    );
  }

  @visibleForTesting
  static Map<String, dynamic> extractJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty model response');
    }

    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      final sanitized = trimmed
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final candidate = _extractBalancedJson(sanitized);
      if (candidate == null) {
        throw const FormatException('JSON object not found');
      }
      return jsonDecode(candidate) as Map<String, dynamic>;
    }
  }

  static String? _extractBalancedJson(String input) {
    var start = -1;
    var depth = 0;
    var inString = false;
    var isEscaped = false;
    String? lastCandidate;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (isEscaped) {
        isEscaped = false;
        continue;
      }

      if (char == r'\') {
        isEscaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (char == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0 && start != -1) {
          lastCandidate = input.substring(start, i + 1);
        }
      }
    }

    return lastCandidate;
  }

  /// L10n error key prefix for UI-side translation detection.
  static const errorKeyPrefix = _kErrorPrefix;
}
