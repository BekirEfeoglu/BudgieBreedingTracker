import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/marketplace_listing_remote_source.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/mocks.dart';

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

Uint8List _magicBytesFor(String ext, [int totalSize = 32]) {
  final data = Uint8List(totalSize);
  switch (ext) {
    case 'jpg' || 'jpeg':
      data[0] = 0xFF;
      data[1] = 0xD8;
      data[2] = 0xFF;
    case 'png':
      data[0] = 0x89;
      data[1] = 0x50;
      data[2] = 0x4E;
      data[3] = 0x47;
    case 'gif':
      data[0] = 0x47;
      data[1] = 0x49;
      data[2] = 0x46;
    case 'webp':
      data[0] = 0x52;
      data[1] = 0x49;
      data[2] = 0x46;
      data[3] = 0x46;
      data[8] = 0x57;
      data[9] = 0x45;
      data[10] = 0x42;
      data[11] = 0x50;
    case 'heic':
      data[4] = 0x66;
      data[5] = 0x74;
      data[6] = 0x79;
      data[7] = 0x70;
      data[8] = 0x68;
      data[9] = 0x65;
      data[10] = 0x69;
      data[11] = 0x63;
  }
  return data;
}

Future<File> _writeTempImage(String name, Uint8List bytes) async {
  final dir = await Directory.systemTemp.createTemp('marketplace-image-test-');
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes);
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return file;
}

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late MarketplaceListingRemoteSource source;

  setUpAll(() {
    registerFallbackValue(const FileOptions());
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = MarketplaceListingRemoteSource(client);
  });

  group('MarketplaceListingRemoteSource', () {
    test('fetchListings applies default filters and order', () async {
      selectBuilder.result = [
        {'id': 'l1', 'title': 'Blue Budgie', 'status': 'active'},
      ];

      final result = await source.fetchListings();

      expect(client.requestedTable, SupabaseConstants.marketplaceListingsTable);
      expect(result, hasLength(1));
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['is_deleted:false', 'status:active']));
      expect(selectBuilder.orderCalls, contains('created_at'));
      expect(selectBuilder.limitValue, 20);
    });

    test('fetchListings applies optional filters', () async {
      selectBuilder.result = [];

      await source.fetchListings(
        city: 'Istanbul',
        listingType: 'sale',
        gender: 'male',
        minPrice: 100,
        maxPrice: 500,
        limit: 10,
      );

      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(
        eqKeys,
        containsAll(['city:Istanbul', 'listing_type:sale', 'gender:male']),
      );
      final gteKeys = selectBuilder.gteCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(gteKeys, contains('price:100.0'));
      final lteKeys = selectBuilder.lteCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(lteKeys, contains('price:500.0'));
      expect(selectBuilder.limitValue, 10);
    });

    test('fetchById applies id and deleted filters with maybeSingle', () async {
      selectBuilder.singleResult = {
        'id': 'l1',
        'title': 'Blue Budgie',
        'status': 'active',
      };

      final result = await source.fetchById('l1');

      expect(result, isNotNull);
      expect(result!['id'], 'l1');
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['id:l1', 'is_deleted:false']));
    });

    test('fetchById hides inactive listing from non-owner', () async {
      selectBuilder.singleResult = {
        'id': 'l1',
        'user_id': 'seller-1',
        'status': 'sold',
      };

      final result = await source.fetchById('l1', currentUserId: 'buyer-1');

      expect(result, isNull);
    });

    test('fetchById allows inactive listing for owner', () async {
      selectBuilder.singleResult = {
        'id': 'l1',
        'user_id': 'seller-1',
        'status': 'sold',
      };

      final result = await source.fetchById('l1', currentUserId: 'seller-1');

      expect(result, isNotNull);
      expect(result!['id'], 'l1');
    });

    test('fetchByIds filters deleted and inactive listings', () async {
      selectBuilder.result = [
        {'id': 'l1', 'title': 'Blue Budgie'},
      ];

      final result = await source.fetchByIds(['l1', 'l2']);

      expect(result, hasLength(1));
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['is_deleted:false', 'status:active']));
    });

    test('fetchByUser filters by user_id and is_deleted', () async {
      selectBuilder.result = [
        {'id': 'l1', 'user_id': 'user-1'},
      ];

      final result = await source.fetchByUser('user-1');

      expect(result, hasLength(1));
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['user_id:user-1', 'is_deleted:false']));
    });

    test('softDelete sets is_deleted to true', () async {
      await source.softDelete('l1', userId: 'user-1');

      expect(queryBuilder.updatePayload, {'is_deleted': true});
      final eqKeys = queryBuilder.updateBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('id:l1'));
    });

    test('updateStatus sends correct payload', () async {
      await source.updateStatus('l1', 'sold', userId: 'user-1');

      expect(queryBuilder.updatePayload, {'status': 'sold'});
    });

    test('search sanitizes input and applies or filter', () async {
      selectBuilder.result = [];

      await source.search('blue budgie', limit: 10);

      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['is_deleted:false', 'status:active']));
      expect(selectBuilder.orCalls, isNotEmpty);
      expect(selectBuilder.limitValue, 10);
    });

    test('search returns empty list for empty sanitized query', () async {
      final result = await source.search('.,;()\'"`');

      expect(result, isEmpty);
    });

    test(
      'uploadImages validates image and uploads with scoped storage path',
      () async {
        final mockClient = MockSupabaseClient();
        final mockStorage = MockSupabaseStorageClient();
        final mockFileApi = MockStorageFileApi();
        when(() => mockClient.storage).thenReturn(mockStorage);
        when(
          () => mockStorage.from(SupabaseConstants.marketplacePhotosBucket),
        ).thenReturn(mockFileApi);
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'storage-key');
        when(
          () => mockFileApi.getPublicUrl(any()),
        ).thenReturn('https://cdn/img.png');

        final uploadSource = MarketplaceListingRemoteSource(mockClient);
        final file = await _writeTempImage('photo.png', _magicBytesFor('png'));

        final urls = await uploadSource.uploadImages(
          userId: 'user-1',
          listingId: 'listing-1',
          localPaths: [file.path],
        );

        expect(urls, ['https://cdn/img.png']);
        verify(
          () => mockFileApi.uploadBinary(
            'marketplace-images/user-1/listing-1/0.png',
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).called(1);
      },
    );

    test('uploadImages rejects unsafe path components', () async {
      await expectLater(
        () => source.uploadImages(
          userId: '../user-1',
          listingId: 'listing-1',
          localPaths: const [],
        ),
        throwsArgumentError,
      );
    });

    test(
      'uploadImages rejects content that does not match extension',
      () async {
        final uploadSource = MarketplaceListingRemoteSource(
          MockSupabaseClient(),
        );
        final file = await _writeTempImage('photo.jpg', _magicBytesFor('png'));

        await expectLater(
          () => uploadSource.uploadImages(
            userId: 'user-1',
            listingId: 'listing-1',
            localPaths: [file.path],
          ),
          throwsA(isA<StorageException>()),
        );
      },
    );

    test('uploadImages rejects more than three images', () async {
      await expectLater(
        () => source.uploadImages(
          userId: 'user-1',
          listingId: 'listing-1',
          localPaths: const ['1.jpg', '2.jpg', '3.jpg', '4.jpg'],
        ),
        throwsArgumentError,
      );
    });

    test('rethrows on fetch error', () {
      selectBuilder.error = Exception('network error');

      expect(() => source.fetchListings(), throwsA(isA<Exception>()));
    });
  });
}
