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

/// L10n error key prefix used by UI to detect translatable exception messages.
const _kErrorPrefix = 'genetics.local_ai_error_';

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
    final prompt = _buildGeneticsPrompt(
      father: father,
      mother: mother,
      fatherName: fatherName,
      motherName: motherName,
      calculatorResults: calculatorResults,
      allowedGenetics: allowedGenetics,
    );
    final payload = await _generate(
      config: config,
      system: _systemGenetics,
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

    final system = imagePath != null ? _systemSexWithImage : _systemSex;
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
      system: _systemMutationImage,
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
    if (config.isOpenRouter) {
      return const [];
    }

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
          .timeout(_requestTimeout);
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
          .timeout(_requestTimeout);
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

  static const _systemGenetics = '''
Budgerigar breeding genetics assistant. JSON only. IMPORTANT: ALL text values MUST be in Turkish (Türkçe). Never use English for summary, warnings, next_checks, or any descriptive text.

Output: {"summary":"...","confidence":"low|medium|high","likely_mutations":["phenotype descriptions"],"matched_genetics":["id from allowed list"],"sex_linked_note":"...","warnings":["..."],"next_checks":["..."]}

Rules:
- Calculator summary is the source of truth; complement it, don't contradict.
- matched_genetics: only IDs from the allowed list.
- likely_mutations: phenotype-level outcomes, not raw IDs.
- warnings: ambiguous genes, sex-linked risks, missing evidence.
- If a parent genotype is empty, say the pair data is incomplete.
- Lower confidence instead of inventing facts. Keep items short.''';

  static String _buildGeneticsPrompt({
    required ParentGenotype father,
    required ParentGenotype mother,
    required List<OffspringResult> calculatorResults,
    required List<BudgieMutationRecord> allowedGenetics,
    String? fatherName,
    String? motherName,
  }) {
    final fName = fatherName?.trim().isNotEmpty == true
        ? fatherName!.trim()
        : 'Unknown';
    final mName = motherName?.trim().isNotEmpty == true
        ? motherName!.trim()
        : 'Unknown';
    // Top 8 results to keep prompt concise within token budget.
    final calcLines = calculatorResults.isEmpty
        ? 'none'
        : calculatorResults
              .take(8)
              .map(
                (r) =>
                    '${r.phenotype} ${(r.probability * 100).toStringAsFixed(0)}% ${r.sex.name}',
              )
              .join('; ');
    final allowedIds = allowedGenetics.isEmpty
        ? 'none'
        : allowedGenetics.map((a) => '${a.id}(${a.name})').join(', ');

    return '''
Father($fName): ${_formatGenotype(father)}
Mother($mName): ${_formatGenotype(mother)}
Calculator: $calcLines
Allowed IDs: $allowedIds''';
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

  static const _systemSex = '''
Budgerigar sex estimation assistant. JSON only. IMPORTANT: ALL text values MUST be in Turkish (Türkçe). Never use English for rationale, indicators, or next_checks.

Output: {"predicted_sex":"male|female|uncertain","confidence":"low|medium|high","rationale":"...","indicators":["..."],"next_checks":["..."]}

Rules:
- Consider cere color, age, juvenile head bars, mutation effects, breeder cues.
- Lutino, albino, recessive pied, juveniles → lower confidence.
- Weak/conflicting evidence → "uncertain". Keep items short.
- Suggest age progression or cere inspection when it would improve certainty.''';

  static const _systemSexWithImage = '''
Budgerigar sex estimation assistant with cere photo. JSON only. IMPORTANT: ALL text values MUST be in Turkish (Türkçe). Never use English for rationale, indicators, or next_checks.

Output: {"predicted_sex":"male|female|uncertain","confidence":"low|medium|high","rationale":"...","indicators":["..."],"next_checks":["..."]}

Rules:
- A cere (nostril area) close-up photo is attached. Analyze cere color and texture first.
- Male cere: bright blue, purple-blue, or pink (juveniles). Female cere: brown, crusty tan, pale white-blue, or beige.
- Combine photo cere analysis with the text observations. Photo evidence outweighs text when they conflict.
- Consider age, juvenile head bars, mutation effects (lutino/albino/recessive pied mask cere color).
- Lutino, albino, recessive pied, juveniles → lower confidence.
- Weak/conflicting evidence → "uncertain". Keep items short.
- If photo is blurry, poorly lit, or does not show cere clearly → reduce confidence.''';

  static const _systemMutationImage = '''
Muhabbet kuşu mutasyon tespiti. JSON formatında yanıt ver. TÜM metin değerleri Türkçe olmalıdır.

Etiketler: normal_light_green, normal_dark_green, normal_olive, normal_skyblue, normal_cobalt, normal_mauve, spangle_green, spangle_blue, cinnamon_green, cinnamon_blue, opaline_green, opaline_blue, dominant_pied_green, dominant_pied_blue, recessive_pied_green, recessive_pied_blue, clearwing_green, clearwing_blue, greywing_green, greywing_blue, dilute_green, dilute_blue, clearbody_green, clearbody_blue, lutino, albino, yellowface_blue, violet_green, violet_blue, grey_green, grey_blue, fallow_green, fallow_blue, lacewing_green, lacewing_blue, opaline_cinnamon_green, opaline_cinnamon_blue, slate_blue, dark_eyed_clear_green, dark_eyed_clear_blue, texas_clearbody_green, texas_clearbody_blue, creamino, unknown

NOT: spangle_blue etiketi hem SF hem DF spangle blue için kullanılır.

Çıktı: {"predicted_mutation":"etiket","confidence":"low|medium|high","base_series":"green|blue|lutino|albino|unknown","pattern_family":"normal|spangle|pied|opaline|cinnamon|clearwing|greywing|dilute|clearbody|yellowface|violet|ino|grey|fallow|lacewing|slate|unknown","body_color":"...","wing_pattern":"...","eye_color":"...","rationale":"...","secondary_possibilities":["etiket","etiket"]}

===== KRİTİK KURAL: GÖZ RENGİ GEÇİDİ =====

Bu kural TÜM diğer kurallardan önce gelir. Hiçbir koşulda atlanamaz.

1. Fotoğrafta göz rengini tespit et ve eye_color alanına yaz.
2. KIRMIZI/PEMBE göz → ino mutasyonu mümkün (lutino veya albino).
3. KOYU/SİYAH göz → lutino veya albino ASLA seçilemez. Beyaz/soluk bir kuş + koyu göz = spangle DF, dominant pied, dilute veya clearbody.
4. Göz görünmüyor veya belirsiz → ino tahmin etme. Non-ino etiket veya "unknown" kullan.

BU KURALI İHLAL EDEN HERHANGİ BİR TAHMİN GEÇERSİZDİR.
Beyaz kuş + koyu göz = spangle_blue (DF spangle), dominant_pied_blue, dilute_blue veya recessive_pied_blue.
Beyaz kuş + kırmızı göz = albino.
Sarı kuş + koyu göz = spangle_green (DF spangle), dominant_pied_green veya dilute_green.
Sarı kuş + kırmızı göz = lutino.

===== ADIM ADIM TESPİT =====

ADIM 1 — GÖZ RENGİ (en kritik tanı):
- Kırmızı/pembe göz → ino mutasyonu. Sarı vücut = lutino, beyaz vücut = albino.
- Koyu/siyah göz → ASLA lutino veya albino DEĞİL.
- Göz görünmüyor → ino tahmin etme.

ADIM 2 — TEMEL SERİ (vücut rengi):
- Yeşil/sarı vücut (doğal sarı yüz) → seri "green".
- Mavi/beyaz/gri vücut → seri "blue".
- Saf sarı + kırmızı göz → seri "lutino".
- Saf beyaz + kırmızı göz → seri "albino".

ADIM 3 — KOYU FAKTÖR:
Yeşil seri: parlak canlı yeşil = light_green (0 DF), koyu yeşil = dark_green (1 DF), donuk kahverengi-yeşil = olive (2 DF).
Mavi seri: parlak gök mavisi = skyblue (0 DF), orta mavi = cobalt (1 DF), gri-mavi = mauve (2 DF).

ADIM 4 — DESEN AİLESİ:

NORMAL: Kanatlarda ve başın arkasında düzenli siyah çizgiler. Standart dalgalı desen.

SPANGLE: SF = kanat desenleri TERSİNE çevrilmiş (ince koyu merkez, açık kenarlar). DF = neredeyse tamamen beyaz (mavi seri) veya sarı (yeşil seri), KOYU GÖZLERLE — ino'ya benzer ama DEĞİLDİR. Kalıntı desenler arayın.

OPALİN: Başın arkasında/ensede azaltılmış çizgiler. Vücut rengi sırt bölgesine V şeklinde yayılır.

TARÇİN: TÜM siyah melanin kahverengi ile değiştirilmiş. Kanat desenleri kahverengi/tarçın rengi.

DOMİNANT PİED: Göğüs/karın bölgesinde net bir bant/yama. Koyu gözler + ışık iris halkası.

RESESİF PİED: Tüm vücutta rastgele, düzensiz berrak yamalar. Tamamen koyu gözler (iris halkası YOK).

CLEARWING: Kanat desenleri çok soluk, vücut rengi parlak ve doygun.

GREYWING: Kanat desenleri gri (siyah değil). Vücut rengi %50 seyreltilmiş.

DILUTE: Genel olarak soluk, solgun görünüm. Melanin %30'a düşürülmüş.

CLEARBODY: Vücut rengi parlak, melanin azaltılmış. Kanat desenleri koyu kalır.

YELLOWFACE: SADECE mavi seri kuşlarda. Mavi vücut + yüzde sarı tonu.

VİOLET: Canlı mor/menekşe tonu. En belirgin cobalt + violet'te. Yeşil seride daha derin ton. Mavi seride parlak mor-mavi.

GRİ: Gri ton overlay ekler. Yeşil→gri-yeşil (donuk yeşil-gri), mavi→gri (donuk gri). KOYU GÖZLER. Tüm vücut ve kanatlara eşit etki eder.

FALLOW: Tarçın'a çok benzer — kahverengi kanat desenleri. AMA KIRMIZI/PEMBE GÖZ. Göz rengi fallow'un TEK ayırt edici özelliğidir. Koyu gözlü kahverengi desenli kuş = tarçın, ASLA fallow DEĞİL.

LACEWING: Çok soluk/silik kahverengi desen + KIRMIZI GÖZ. Tarçın+İno birleşimi. Normal tarçından daha soluk. Vücut rengi açık sarı (yeşil seri) veya açık beyaz (mavi seri).

OPALİN TARÇINİ: Opaline V-sırt deseni + kahverengi (siyah değil) kanat desenleri. İki mutasyonun birleşimi. Sırtta renk yayılması + kahverengi melanin.

SLATE: Koyu gri-mavi ton. SADECE mavi seri kuşlarda. Normal mavi'den daha koyu ve grimsi. Mauve'dan daha soğuk ve metalik.

DARK-EYED CLEAR (DEC): Tamamen beyaz (mavi seri) veya sarı (yeşil seri) + KOYU GÖZ. DF Spangle + Recessive Pied birleşimi. Albino/Lutino'ya çok benzer ama göz KOYU.

TEXAS CLEARBODY (TCB): Soluk/açık vücut rengi + KIRMIZI GÖZ. Normal clearbody'den farkı kırmızı göz. Dilute'a benzer ama göz KOK rengi kırmızı.

CREAMİNO: Krem sarı vücut + KIRMIZI GÖZ. Yellowface + İno birleşimi. Lutino'dan farkı: hafif krem/bej ton (mavi seri arka planı). Saf sarı = lutino, krem sarı = creamino.

===== KARIŞTIRILMA OLASILIĞI YÜKSEK ÇİFTLER =====

Albino ↔ Spangle DF blue: Albino KIRMIZI göz. Spangle DF KOYU göz. İkisi de beyaz.
Albino ↔ Dark-eyed clear blue: Albino KIRMIZI göz. DEC KOYU göz. İkisi de beyaz.
Lutino ↔ Spangle DF green: Lutino KIRMIZI göz. Spangle DF KOYU göz. İkisi de sarı.
Lutino ↔ Creamino: Lutino saf sarı (yeşil seri). Creamino krem sarı (mavi seri + yellowface).
Fallow ↔ Cinnamon: Fallow KIRMIZI göz + kahverengi. Cinnamon KOYU göz + kahverengi. Göz rengi TEK fark.
Lacewing ↔ Cinnamon: Lacewing KIRMIZI göz + çok soluk desen. Cinnamon KOYU göz + belirgin desen.
Texas Clearbody ↔ Dilute: TCB KIRMIZI göz. Dilute KOYU göz. İkisi de soluk.
Dilute ↔ Greywing: Dilute = vücut ve kanatlar eşit soluk. Greywing = gri kanatlar + orta soluk vücut.
Clearwing ↔ Greywing: Clearwing = soluk kanat + parlak vücut. Greywing = gri kanat + soluk vücut.
Grey ↔ Mauve: Grey = soğuk gri ton. Mauve = sıcak gri-mavi. Grey daha düz/nötr.
Slate ↔ Mauve: Slate = metalik koyu gri-mavi. Mauve = daha sıcak ve yumuşak.
Dominant Pied ↔ Recessive Pied: Dominant = iris halkası var. Recessive = iris halkası yok.

===== KURALLAR =====
- Tahmin etmektense "unknown" tercih et. Belirsiz özellikler → güveni düşür.
- confidence=high SADECE vücut, kanat ve göz net görünüyorsa.
- secondary_possibilities: maks 3, "unknown" dahil etme.
- Gri mutasyonu gri ton ekler: yeşil→gri-yeşil, mavi→gri.
- Birden fazla mutasyon birleşebilir. En baskın görsel mutasyonu birincil seç.
- rationale alanında hangi adımdan hangi sonuca ulaştığını açıkla.''';

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

  /// L10n error key prefix for UI-side translation detection.
  static const errorKeyPrefix = _kErrorPrefix;
}
