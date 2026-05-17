part of 'local_ai_service.dart';

class _LocalAiTransport {
  _LocalAiTransport({required http.Client client}) : _client = client;

  static const Duration _requestTimeout = Duration(seconds: 25);
  static const Duration _imageRequestTimeout = Duration(seconds: 45);

  final http.Client _client;

  void dispose() => _client.close();

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
        throw const ValidationException('${_kErrorPrefix}unexpected_response');
      }
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test timed out', e, st);
      throw const NetworkException('${_kErrorPrefix}ollama_timeout');
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test failed', e, st);
      throw const NetworkException('${_kErrorPrefix}ollama_unreachable');
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test failed', e, st);
      throw const NetworkException('${_kErrorPrefix}ollama_unreachable');
    } on FormatException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test parse failed', e, st);
      throw const ValidationException('${_kErrorPrefix}unparseable');
    }
  }

  Future<void> _testOpenRouterConnection({
    required LocalAiConfig config,
  }) async {
    if (config.apiKey.trim().isEmpty) {
      throw const ValidationException('${_kErrorPrefix}api_key_required');
    }

    final endpoint = Uri.parse('${config.normalizedBaseUrl}/api/v1/models');

    try {
      final response = await _client
          .get(endpoint, headers: {'Authorization': 'Bearer ${config.apiKey}'})
          .timeout(_requestTimeout);

      if (response.statusCode == 401) {
        throw const ValidationException('${_kErrorPrefix}api_key_invalid');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException(
          '${_kErrorPrefix}openrouter_http\x00${response.statusCode}',
        );
      }
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter test timed out', e, st);
      throw const NetworkException('${_kErrorPrefix}openrouter_timeout');
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter test failed', e, st);
      throw const NetworkException('${_kErrorPrefix}openrouter_unreachable');
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter test failed', e, st);
      throw const NetworkException('${_kErrorPrefix}openrouter_unreachable');
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
        throw const ValidationException('${_kErrorPrefix}model_list_format');
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
      throw const NetworkException('${_kErrorPrefix}model_list_timeout');
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list failed', e, st);
      throw const NetworkException('${_kErrorPrefix}ollama_unreachable');
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list failed', e, st);
      throw const NetworkException('${_kErrorPrefix}ollama_unreachable');
    } on FormatException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list parse failed', e, st);
      throw const ValidationException('${_kErrorPrefix}model_list_unparseable');
    }
  }

  /// Fetches vision-capable models from OpenRouter's public model list.
  Future<List<String>> _listOpenRouterModels({
    required LocalAiConfig config,
  }) async {
    if (config.apiKey.trim().isEmpty) return const [];

    final endpoint = Uri.parse('${config.normalizedBaseUrl}/api/v1/models');

    try {
      final response = await _client
          .get(endpoint, headers: {'Authorization': 'Bearer ${config.apiKey}'})
          .timeout(_requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final data = root['data'];
      if (data is! List) return const [];

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
      AppLogger.error(
        '[LocalAiService] OpenRouter model list timed out',
        e,
        st,
      );
      return const [];
    } catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter model list failed', e, st);
      return const [];
    }
  }

  Future<Map<String, dynamic>> generate({
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
    final timeout = images.isNotEmpty ? _imageRequestTimeout : _requestTimeout;
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
      throw const NetworkException('${_kErrorPrefix}generate_ollama_timeout');
    } catch (e, st) {
      AppLogger.error('[LocalAiService] Ollama connection failed', e, st);
      throw const NetworkException('${_kErrorPrefix}ollama_unreachable');
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
      return LocalAiService.extractJsonObject(modelResponse);
    } catch (e, st) {
      AppLogger.error('[LocalAiService] Ollama parse failed', e, st);
      throw const ValidationException('${_kErrorPrefix}generate_parse');
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

    final timeout = images.isNotEmpty ? _imageRequestTimeout : _requestTimeout;
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
      throw const ValidationException('${_kErrorPrefix}api_key_invalid');
    }
    if (response.statusCode == 429) {
      throw const NetworkException('${_kErrorPrefix}rate_limit');
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
      final message =
          (choices[0] as Map<String, dynamic>)['message']
              as Map<String, dynamic>;
      final content = message['content'] as String? ?? '';
      return LocalAiService.extractJsonObject(content);
    } catch (e, st) {
      AppLogger.error('[LocalAiService] OpenRouter parse failed', e, st);
      throw const ValidationException('${_kErrorPrefix}generate_parse');
    }
  }

  static Uri _buildUri({required LocalAiConfig config, required String path}) {
    final uri = Uri.tryParse(config.normalizedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ValidationException('${_kErrorPrefix}invalid_url');
    }
    return uri.replace(path: path);
  }
}
