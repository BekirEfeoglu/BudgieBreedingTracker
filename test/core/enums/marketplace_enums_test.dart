import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';

void main() {
  group('MarketplaceListingType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in MarketplaceListingType.values) {
        expect(MarketplaceListingType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(
        MarketplaceListingType.fromJson('invalid'),
        MarketplaceListingType.unknown,
      );
      expect(
        MarketplaceListingType.fromJson(''),
        MarketplaceListingType.unknown,
      );
    });

    test('has expected value count', () {
      expect(MarketplaceListingType.values.length, 5);
    });
  });

  group('MarketplaceListingStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in MarketplaceListingStatus.values) {
        expect(MarketplaceListingStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(
        MarketplaceListingStatus.fromJson('invalid'),
        MarketplaceListingStatus.unknown,
      );
      expect(
        MarketplaceListingStatus.fromJson(''),
        MarketplaceListingStatus.unknown,
      );
    });

    test('has expected value count', () {
      expect(MarketplaceListingStatus.values.length, 5);
    });
  });
}
