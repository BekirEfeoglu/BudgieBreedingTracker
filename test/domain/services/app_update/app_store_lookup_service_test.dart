import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:budgie_breeding_tracker/domain/services/app_update/app_store_lookup_service.dart';

void main() {
  group('AppStoreLookupService.fetchLatest', () {
    test(
      'returns AppStoreListing when lookup succeeds with valid payload',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, 'itunes.apple.com');
          expect(request.url.path, '/lookup');
          expect(request.url.queryParameters['id'], '6759828211');
          expect(request.url.queryParameters['country'], 'tr');
          return http.Response(
            jsonEncode({
              'resultCount': 1,
              'results': [
                {
                  'version': '1.2.3',
                  'trackViewUrl':
                      'https://apps.apple.com/tr/app/budgie/id6759828211',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = AppStoreLookupService(client: client);
        final listing = await service.fetchLatest();

        expect(listing, isNotNull);
        expect(listing!.version, '1.2.3');
        expect(
          listing.storeUrl,
          'https://apps.apple.com/tr/app/budgie/id6759828211',
        );
      },
    );

    test('passes through custom country code', () async {
      String? capturedCountry;
      final client = MockClient((request) async {
        capturedCountry = request.url.queryParameters['country'];
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final service = AppStoreLookupService(client: client);
      await service.fetchLatest(country: 'de');

      expect(capturedCountry, 'de');
    });

    test('returns null when response is non-200', () async {
      final client = MockClient((request) async {
        return http.Response('upstream error', 500);
      });

      final service = AppStoreLookupService(client: client);
      expect(await service.fetchLatest(), isNull);
    });

    test('returns null when results array is empty', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'resultCount': 0, 'results': []}),
          200,
        );
      });

      final service = AppStoreLookupService(client: client);
      expect(await service.fetchLatest(), isNull);
    });

    test('returns null when version field is missing', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'results': [
              {'trackViewUrl': 'https://apps.apple.com/tr/app/x/id1'},
            ],
          }),
          200,
        );
      });

      final service = AppStoreLookupService(client: client);
      expect(await service.fetchLatest(), isNull);
    });

    test('returns null when JSON body cannot be parsed', () async {
      final client = MockClient((request) async {
        return http.Response('not json at all', 200);
      });

      final service = AppStoreLookupService(client: client);
      expect(await service.fetchLatest(), isNull);
    });

    test('returns null when HTTP client throws (network failure)', () async {
      final client = MockClient((request) async {
        throw http.ClientException('connection refused');
      });

      final service = AppStoreLookupService(client: client);
      expect(await service.fetchLatest(), isNull);
    });

    test('returns null when response is not a JSON object', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode(['unexpected', 'array']), 200);
      });

      final service = AppStoreLookupService(client: client);
      expect(await service.fetchLatest(), isNull);
    });
  });
}
