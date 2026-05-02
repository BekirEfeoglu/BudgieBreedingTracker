import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/utils/logger.dart';
import 'app_update_info.dart';

class AppStoreLookupService {
  const AppStoreLookupService({http.Client? client}) : _client = client;

  static const String _appId = '6759828211';

  final http.Client? _client;

  Future<AppStoreListing?> fetchLatest({String country = 'tr'}) async {
    final client = _client ?? http.Client();
    final shouldClose = _client == null;
    try {
      final uri = Uri.https('itunes.apple.com', '/lookup', {
        'id': _appId,
        'country': country,
      });
      final response = await client.get(uri);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return AppStoreListing.fromLookupJson(decoded);
    } catch (e, st) {
      AppLogger.warning('[AppUpdate] App Store lookup failed: $e');
      AppLogger.error('[AppUpdate] App Store lookup error', e, st);
      return null;
    } finally {
      if (shouldClose) client.close();
    }
  }
}
