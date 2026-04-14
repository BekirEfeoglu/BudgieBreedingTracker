import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'local_ai_models.dart';
import 'local_ai_prompts.dart';

/// L10n error key prefix used by UI to detect translatable exception messages.
const _kErrorPrefix = 'genetics.local_ai_error_';

class LocalAiService {
  LocalAiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _requestTimeout = Duration(seconds: 25);
  static const Duration _imageRequestTimeout = Duration(seconds: 45);
  final http.Client _client;

  void dispose() => _client.close();

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
    final payload = await _generate(
      config: config,
      system: LocalAiPrompts.systemGenetics,
      prompt: prompt,
      numPredict: 400,
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
    if (imagePath != null) {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw const ValidationException(
          '${_kErrorPrefix}image_not_found',
        );
      }
      final fileSize = await file.length();
      if (fileSize > AppConstants.maxLocalAiImageBytes) {
        throw const ValidationException(
          '${_kErrorPrefix}image_too_large',
        );
      }
      images = [base64Encode(await file.readAsBytes())];
    }

    final system = imagePath != null
        ? LocalAiPrompts.systemSexWithImage
        : LocalAiPrompts.systemSex;
    final payload = await _generate(
      config: config,
      system: system,
      prompt: observations.trim(),
      images: images,
      numPredict: 300,
    );
    return LocalAiSexInsight.fromJson(payload);
  }

  Future<LocalAiMutationInsight> analyzeMutationFromImage({
    required LocalAiConfig config,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const ValidationException(
        '${_kErrorPrefix}image_not_found',
      );
    }

    final fileSize = await file.length();
    if (fileSize > AppConstants.maxLocalAiImageBytes) {
      throw const ValidationException(
        '${_kErrorPrefix}image_too_large',
      );
    }

    final payload = await _generate(
      config: config,
      system: LocalAiPrompts.systemMutationImage,
      prompt: 'Analyze this budgerigar photo.',
      images: [base64Encode(await file.readAsBytes())],
      numPredict: 350,
    );
    return LocalAiMutationInsight.fromJson(payload);
  }

  Future<void> testConnection({required LocalAiConfig config}) async {
    if (config.isOpenRouter) {
      return _testOpenRouterConnection(config: config);
    }

    final endpoint = _buildUri(config: config, path: '/api/tags');

    try {
      final response = await _client.get(endpoint).timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException(
          '${_kErrorPrefix}connection_http\x00${response.statusCode}',
        );
      }

      final root = jsonDecode(response.body);
      if (root is! Map<String, dynamic> || root['models'] is! List) {
        throw const ValidationException(
          '${_kErrorPrefix}unexpected_response',
        );
      }
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test timed out', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}ollama_timeout',
      );
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}ollama_unreachable',
      );
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}ollama_unreachable',
      );
    } on FormatException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test parse failed', e, st);
      throw const ValidationException(
        '${_kErrorPrefix}unparseable',
      );
    }
  }

  Future<void> _testOpenRouterConnection({
    required LocalAiConfig config,
  }) async {
    if (config.apiKey.trim().isEmpty) {
      throw const ValidationException(
        '${_kErrorPrefix}api_key_required',
      );
    }

    final endpoint = Uri.parse(
      '${config.normalizedBaseUrl}/api/v1/models',
    );

    try {
      final response = await _client
          .get(endpoint, headers: {
            'Authorization': 'Bearer ${config.apiKey}',
          })
          .timeout(_requestTimeout);

      if (response.statusCode == 401) {
        throw const ValidationException(
          '${_kErrorPrefix}api_key_invalid',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException(
          '${_kErrorPrefix}openrouter_http\x00${response.statusCode}',
        );
      }
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter test timed out', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}openrouter_timeout',
      );
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter test failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}openrouter_unreachable',
      );
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter test failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}openrouter_unreachable',
      );
    }
  }

  Future<List<String>> listModels({required LocalAiConfig config}) async {
    return config.isOpenRouter
        ? _listOpenRouterModels(config: config)
        : _listOllamaModels(config: config);
  }

  Future<List<String>> _listOllamaModels({
    required LocalAiConfig config,
  }) async {
    final endpoint = _buildUri(config: config, path: '/api/tags');

    try {
      final response = await _client.get(endpoint).timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException(
          '${_kErrorPrefix}model_list_http\x00${response.statusCode}',
        );
      }

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final rawModels = root['models'];
      if (rawModels is! List) {
        throw const ValidationException(
          '${_kErrorPrefix}model_list_format',
        );
      }

      return rawModels
          .whereType<Map>()
          .map((item) => item['name']?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list timed out', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}model_list_timeout',
      );
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}ollama_unreachable',
      );
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}ollama_unreachable',
      );
    } on FormatException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list parse failed', e, st);
      throw const ValidationException(
        '${_kErrorPrefix}model_list_unparseable',
      );
    }
  }

  /// Fetches vision-capable models from OpenRouter's public model list.
  Future<List<String>> _listOpenRouterModels({
    required LocalAiConfig config,
  }) async {
    if (config.apiKey.trim().isEmpty) return const [];

    final endpoint = Uri.parse(
      '${config.normalizedBaseUrl}/api/v1/models',
    );

    try {
      final response = await _client
          .get(endpoint, headers: {
            'Authorization': 'Bearer ${config.apiKey}',
          })
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final data = root['data'];
      if (data is! List) return const [];

      // Filter to vision-capable models and extract IDs.
      return data
          .whereType<Map<String, dynamic>>()
          .where((m) {
            final arch = m['architecture'] as Map<String, dynamic>?;
            final modality = arch?['modality'] as String? ?? '';
            return modality.contains('image');
          })
          .map((m) => (m['id'] as String?)?.trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toList()
        ..sort();
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter model list timed out', e, st);
      return const [];
    } catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter model list failed', e, st);
      return const [];
    }
  }

  Future<Map<String, dynamic>> _generate({
    required LocalAiConfig config,
    required String prompt,
    String? system,
    List<String> images = const [],
    int numPredict = 400,
  }) async {
    return config.isOpenRouter
        ? _generateOpenRouter(
            config: config,
            prompt: prompt,
            system: system,
            images: images,
            numPredict: numPredict,
          )
        : _generateOllama(
            config: config,
            prompt: prompt,
            system: system,
            images: images,
            numPredict: numPredict,
          );
  }

  Future<Map<String, dynamic>> _generateOllama({
    required LocalAiConfig config,
    required String prompt,
    String? system,
    List<String> images = const [],
    int numPredict = 400,
  }) async {
    final endpoint = _buildUri(config: config, path: '/api/generate');
    final timeout =
        images.isNotEmpty ? _imageRequestTimeout : _requestTimeout;
    http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': config.normalizedModel,
              'prompt': prompt,
              if (system != null) 'system': system,
              'stream': false,
              'format': 'json',
              if (images.isNotEmpty) 'images': images,
              'options': {
                'temperature': 0.2,
                'top_p': 0.9,
                'num_predict': numPredict,
              },
            }),
          )
          .timeout(timeout);
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] Ollama timed out', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}generate_ollama_timeout',
      );
    } catch (e, st) {
      AppLogger.error('[LocalAiService] Ollama connection failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}ollama_unreachable',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.warning(
        '[LocalAiService] Ollama status ${response.statusCode}: ${response.body}',
      );
      throw NetworkException(
        '${_kErrorPrefix}generate_ollama_http\x00${response.statusCode}',
      );
    }

    try {
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      if (root['response'] is Map<String, dynamic>) {
        return root['response'] as Map<String, dynamic>;
      }
      final modelResponse = root['response'] as String? ?? '';
      return extractJsonObject(modelResponse);
    } catch (e, st) {
      AppLogger.error('[LocalAiService] Ollama parse failed', e, st);
      throw const ValidationException(
        '${_kErrorPrefix}generate_parse',
      );
    }
  }

  Future<Map<String, dynamic>> _generateOpenRouter({
    required LocalAiConfig config,
    required String prompt,
    String? system,
    List<String> images = const [],
    int numPredict = 400,
  }) async {
    final endpoint = Uri.parse(
      '${config.normalizedBaseUrl}/api/v1/chat/completions',
    );

    final messages = <Map<String, dynamic>>[
      if (system != null) {'role': 'system', 'content': system},
    ];

    if (images.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          for (final img in images)
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$img'},
            },
        ],
      });
    } else {
      messages.add({'role': 'user', 'content': prompt});
    }

    final timeout =
        images.isNotEmpty ? _imageRequestTimeout : _requestTimeout;
    http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
              'HTTP-Referer': 'https://budgiebreeding.com',
              'X-Title': 'Budgie Breeding Tracker',
            },
            body: jsonEncode({
              'model': config.normalizedModel,
              'messages': messages,
              'temperature': 0.2,
              'top_p': 0.9,
              'max_tokens': numPredict,
            }),
          )
          .timeout(timeout);
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter timed out', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}generate_openrouter_timeout',
      );
    } catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter connection failed', e, st);
      throw const NetworkException(
        '${_kErrorPrefix}generate_openrouter_unreachable',
      );
    }

    if (response.statusCode == 401) {
      throw const ValidationException(
        '${_kErrorPrefix}api_key_invalid',
      );
    }
    if (response.statusCode == 429) {
      throw const NetworkException(
        '${_kErrorPrefix}rate_limit',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.warning(
        '[LocalAiService] OpenRouter status ${response.statusCode}: ${response.body}',
      );
      throw NetworkException(
        '${_kErrorPrefix}generate_openrouter_http\x00${response.statusCode}',
      );
    }

    try {
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = root['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const FormatException('No choices in response');
      }
      final message = (choices[0] as Map<String, dynamic>)['message']
          as Map<String, dynamic>;
      final content = message['content'] as String? ?? '';
      return extractJsonObject(content);
    } catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter parse failed', e, st);
      throw const ValidationException(
        '${_kErrorPrefix}generate_parse',
      );
    }
  }

  static Uri _buildUri({required LocalAiConfig config, required String path}) {
    final uri = Uri.tryParse(config.normalizedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ValidationException(
        '${_kErrorPrefix}invalid_url',
      );
    }
    return uri.replace(path: path);
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
