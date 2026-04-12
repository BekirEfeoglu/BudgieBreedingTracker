import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'local_ai_models.dart';

class LocalAiService {
  LocalAiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration _requestTimeout = Duration(seconds: 25);
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
    final allowedGenetics = _collectAllowedGenetics(
      father: father,
      mother: mother,
      calculatorResults: calculatorResults,
    );
    final payload = await _generate(
      config: config,
      prompt: _buildGeneticsPrompt(
        father: father,
        mother: mother,
        fatherName: fatherName,
        motherName: motherName,
        calculatorResults: calculatorResults,
        allowedGenetics: allowedGenetics,
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
  }) async {
    final payload = await _generate(
      config: config,
      prompt: _buildSexPrompt(observations),
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
        'Secilen gorsel bulunamadi. Lutfen gorseli yeniden secin.',
      );
    }

    final fileSize = await file.length();
    if (fileSize > AppConstants.maxLocalAiImageBytes) {
      throw const ValidationException(
        'Gorsel boyutu 10 MB sinirini asiyor. Daha kucuk bir gorsel secin.',
      );
    }

    final payload = await _generate(
      config: config,
      prompt: _buildMutationImagePrompt(),
      images: [base64Encode(await file.readAsBytes())],
    );
    return LocalAiMutationInsight.fromJson(payload);
  }

  Future<void> testConnection({required LocalAiConfig config}) async {
    final endpoint = _buildUri(config: config, path: '/api/tags');

    try {
      final response = await _client.get(endpoint).timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException(
          'Yerel model baglantisi basarisiz (HTTP ${response.statusCode}).',
        );
      }

      final root = jsonDecode(response.body);
      if (root is! Map<String, dynamic> || root['models'] is! List) {
        throw const ValidationException(
          'Yerel model servisi beklenen formatta yanit vermedi.',
        );
      }
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test timed out', e, st);
      throw const NetworkException(
        'Yerel model zaman asimina ugradi. Ollama servisini ve model durumunu kontrol edin.',
      );
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test failed', e, st);
      throw const NetworkException(
        'Yerel modele baglanilamadi. Ollama servisinin calistigini ve URL bilgisinin dogru oldugunu kontrol edin.',
      );
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test failed', e, st);
      throw const NetworkException(
        'Yerel modele baglanilamadi. Ollama servisinin calistigini ve URL bilgisinin dogru oldugunu kontrol edin.',
      );
    } on FormatException catch (e, st) {
      AppLogger.error('[LocalAiService] Connection test parse failed', e, st);
      throw const ValidationException(
        'Yerel model servisi anlasilamayan bir yanit dondurdu.',
      );
    }
  }

  Future<List<String>> listModels({required LocalAiConfig config}) async {
    final endpoint = _buildUri(config: config, path: '/api/tags');

    try {
      final response = await _client.get(endpoint).timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NetworkException(
          'Yerel model listesi alinamadi (HTTP ${response.statusCode}).',
        );
      }

      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final rawModels = root['models'];
      if (rawModels is! List) {
        throw const ValidationException(
          'Yerel model listesi beklenen formatta gelmedi.',
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
        'Yerel model listesi alinirken zaman asimi olustu.',
      );
    } on SocketException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list failed', e, st);
      throw const NetworkException(
        'Yerel modele baglanilamadi. Ollama servisinin calistigini ve URL bilgisinin dogru oldugunu kontrol edin.',
      );
    } on http.ClientException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list failed', e, st);
      throw const NetworkException(
        'Yerel modele baglanilamadi. Ollama servisinin calistigini ve URL bilgisinin dogru oldugunu kontrol edin.',
      );
    } on FormatException catch (e, st) {
      AppLogger.error('[LocalAiService] Model list parse failed', e, st);
      throw const ValidationException('Yerel model listesi anlasilamadi.');
    }
  }

  Future<Map<String, dynamic>> _generate({
    required LocalAiConfig config,
    required String prompt,
    List<String> images = const [],
  }) async {
    final endpoint = _buildUri(config: config, path: '/api/generate');
    http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': config.normalizedModel,
              'prompt': prompt,
              'stream': false,
              'format': 'json',
              if (images.isNotEmpty) 'images': images,
              'options': {'temperature': 0.2, 'top_p': 0.9, 'num_predict': 500},
            }),
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (e, st) {
      AppLogger.error('[LocalAiService] Request timed out', e, st);
      throw const NetworkException(
        'Yerel model zaman asimina ugradi. Daha kisa girdiyle veya daha hafif bir modelle tekrar deneyin.',
      );
    } catch (e, st) {
      AppLogger.error('[LocalAiService] Connection failed', e, st);
      throw const NetworkException(
        'Yerel modele baglanilamadi. Ollama servisinin calistigini ve URL bilgisinin dogru oldugunu kontrol edin.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      AppLogger.warning(
        '[LocalAiService] Unexpected status ${response.statusCode}: ${response.body}',
      );
      throw NetworkException(
        'Yerel model yanit vermedi (HTTP ${response.statusCode}).',
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
      AppLogger.error('[LocalAiService] Response parse failed', e, st);
      throw const ValidationException(
        'Model yaniti anlasilamadi. Daha kisa bir girdiyle tekrar deneyin.',
      );
    }
  }

  static Uri _buildUri({required LocalAiConfig config, required String path}) {
    final uri = Uri.tryParse(config.normalizedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ValidationException(
        'Yerel model URL bilgisi gecersiz. Ornek: http://127.0.0.1:11434',
      );
    }
    return uri.replace(path: path);
  }

  static String _buildGeneticsPrompt({
    required ParentGenotype father,
    required ParentGenotype mother,
    required List<OffspringResult> calculatorResults,
    required List<BudgieMutationRecord> allowedGenetics,
    String? fatherName,
    String? motherName,
  }) {
    final calculatorSummary = calculatorResults.isEmpty
        ? 'No calculator results available.'
        : calculatorResults
              .take(8)
              .map(
                (OffspringResult result) =>
                    '- phenotype=${result.phenotype}; probability=${result.probability.toStringAsFixed(2)}; sex=${result.sex.name}; genotype=${result.genotype ?? 'unknown'}',
              )
              .join('\n');
    final allowedGeneticsSummary = allowedGenetics.isEmpty
        ? '- none'
        : allowedGenetics
              .map((item) => '- ${item.id}: ${item.name}')
              .join('\n');

    return '''
You are helping inside a budgerigar breeding application.
Analyze the pair and respond with JSON only.

Return exactly this JSON shape:
{
  "summary": "short plain text summary",
  "confidence": "low|medium|high",
  "likely_mutations": ["..."],
  "matched_genetics": ["mutation_id"],
  "sex_linked_note": "short note",
  "warnings": ["..."],
  "next_checks": ["..."]
}

Rules:
- Focus on budgerigar genetics.
- Use the built-in calculator summary as the main source of truth.
- Write every value in Turkish.
- Keep each list item short.
- If uncertain, lower confidence instead of inventing facts.
- If a parent genotype is empty, explicitly mention that the pair data is incomplete.
- Warning items should focus on ambiguous genes, sex-linked risks, or missing evidence.
- `likely_mutations` should describe phenotype-level outcomes, not raw gene IDs.
- `matched_genetics` must only contain IDs from the allowed list below.
- Use `matched_genetics` for the app genetics that best explain your conclusion.

Father name: ${fatherName?.trim().isNotEmpty == true ? fatherName!.trim() : 'Unknown'}
Father genotype: ${_formatGenotype(father)}
Mother name: ${motherName?.trim().isNotEmpty == true ? motherName!.trim() : 'Unknown'}
Mother genotype: ${_formatGenotype(mother)}

Built-in calculator summary:
$calculatorSummary

Allowed app genetics IDs:
$allowedGeneticsSummary
''';
  }

  static List<BudgieMutationRecord> _collectAllowedGenetics({
    required ParentGenotype father,
    required ParentGenotype mother,
    required List<OffspringResult> calculatorResults,
  }) {
    final ids = <String>{
      ...father.allMutationIds,
      ...mother.allMutationIds,
      for (final result in calculatorResults) ...result.visualMutations,
      for (final result in calculatorResults) ...result.carriedMutations,
    };

    final records = ids
        .map(MutationDatabase.getById)
        .whereType<BudgieMutationRecord>()
        .toList(growable: false);
    records.sort((a, b) => a.name.compareTo(b.name));
    return records;
  }

  static String _buildSexPrompt(String observations) {
    return '''
You are helping inside a budgerigar breeding application.
Estimate sex from the observation text and respond with JSON only.

Return exactly this JSON shape:
{
  "predicted_sex": "male|female|uncertain",
  "confidence": "low|medium|high",
  "rationale": "short plain text explanation",
  "indicators": ["..."],
  "next_checks": ["..."]
}

Rules:
- Focus on budgerigar sex estimation.
- Consider cere color, age, juvenile head bars, mutation effects, and typical breeder cues.
- Write every value in Turkish.
- If evidence is weak or conflicting, use "uncertain".
- Keep list items short.
- Treat lutino, albino, recessive pied, and juvenile birds as lower-confidence cases when appropriate.
- Mention when age progression or direct cere inspection would improve certainty.

Observation text:
${observations.trim()}
''';
  }

  static String _buildMutationImagePrompt() {
    return '''
You are analyzing a single budgerigar photo for a breeding app.
Respond with JSON only.

Allowed mutation labels:
- normal_light_green
- normal_dark_green
- normal_olive
- spangle_green
- cinnamon_green
- opaline_green
- dominant_pied_green
- recessive_pied_green
- clearwing_green
- greywing_green
- dilute_green
- clearbody_green
- lutino
- yellowface_blue
- violet_green
- normal_skyblue
- normal_cobalt
- normal_mauve
- spangle_blue
- cinnamon_blue
- opaline_blue
- dominant_pied_blue
- recessive_pied_blue
- clearwing_blue
- greywing_blue
- dilute_blue
- clearbody_blue
- albino
- unknown

Return exactly this JSON shape:
{
  "predicted_mutation": "one allowed label",
  "confidence": "low|medium|high",
  "base_series": "green|blue|lutino|albino|unknown",
  "pattern_family": "normal|spangle|pied|opaline|cinnamon|clearwing|greywing|dilute|clearbody|yellowface|violet|ino|unknown",
  "body_color": "short phrase",
  "wing_pattern": "short phrase",
  "eye_color": "short phrase",
  "rationale": "short explanation",
  "secondary_possibilities": ["allowed label", "allowed label"]
}

Rules:
- Focus on standard budgerigar mutation naming.
- Prefer "unknown" over inventing a label.
- First infer `base_series`, then `pattern_family`, then choose `predicted_mutation`.
- Use body color, wing pattern, and eye color as primary evidence.
- Write `body_color`, `wing_pattern`, `eye_color`, and `rationale` in Turkish.
- Only use `confidence=high` when body color, wing pattern, and eye color are all clearly visible.
- Do not include `unknown` inside `secondary_possibilities`.
- If the bird visually looks like a standard green budgie with classic black barring, prefer `normal_light_green`, `normal_dark_green`, or `normal_olive` before patterned mutations.
- `predicted_mutation` must be consistent with `base_series` and `pattern_family`.
- Keep secondary_possibilities short and limited to 3 items.
- If the photo is blurry, shadowed, or heavily cropped, reduce confidence.
- If the bird has white/blue body with black barring, prefer `normal_skyblue`, `normal_cobalt`, or `normal_mauve`.
- If the bird is pure white with red eyes, prefer `albino`. If pure yellow with red eyes, prefer `lutino`.
''';
  }

  static String _formatGenotype(ParentGenotype genotype) {
    if (genotype.mutations.isEmpty) return 'none selected';
    final entries = genotype.mutations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => '${entry.key}:${entry.value.name}')
        .join(', ');
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
}
