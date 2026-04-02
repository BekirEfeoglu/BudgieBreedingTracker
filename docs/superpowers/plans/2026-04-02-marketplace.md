# Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Yetistiriciler arasi kus alim-satim, takas, sahiplendirme ve arama ilanlari platformu.

**Architecture:** Community feature pattern'i izlenir — Freezed model, custom RemoteSource (BaseRemoteSource yerine direkt SupabaseClient), custom Repository (cache destekli), Riverpod providers, ConsumerWidget ekranlar. Supabase RLS ile guvenlik, ContentModerationService ile icerik moderasyonu. Offline-first degil (community pattern gibi Supabase-first).

**Tech Stack:** Flutter, Riverpod 3, GoRouter, Supabase (PostgreSQL + Storage), Freezed 3, easy_localization, fl_chart (istatistik), flutter_svg (ikonlar)

**Spec:** `docs/superpowers/specs/2026-04-02-community-social-features-design.md` — Feature 1

---

### Task 1: Enum Dosyasi

**Files:**
- Create: `lib/core/enums/marketplace_enums.dart`

- [ ] **Step 1: Enum dosyasini olustur**

```dart
enum MarketplaceListingType {
  sale,
  adoption,
  trade,
  wanted,
  unknown;

  String toJson() => name;

  static MarketplaceListingType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return MarketplaceListingType.unknown;
    }
  }
}

enum MarketplaceListingStatus {
  active,
  sold,
  reserved,
  closed,
  unknown;

  String toJson() => name;

  static MarketplaceListingStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return MarketplaceListingStatus.unknown;
    }
  }
}
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/core/enums/marketplace_enums.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/core/enums/marketplace_enums.dart
git commit -m "feat(marketplace): add listing type and status enums"
```

---

### Task 2: Freezed Model

**Files:**
- Create: `lib/data/models/marketplace_listing_model.dart`

- [ ] **Step 1: Model dosyasini olustur**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

part 'marketplace_listing_model.freezed.dart';
part 'marketplace_listing_model.g.dart';

@freezed
abstract class MarketplaceListing with _$MarketplaceListing {
  const MarketplaceListing._();

  const factory MarketplaceListing({
    required String id,
    required String userId,
    @Default('') String username,
    String? avatarUrl,
    @JsonKey(unknownEnumValue: MarketplaceListingType.unknown)
    @Default(MarketplaceListingType.sale)
    MarketplaceListingType listingType,
    @Default('') String title,
    @Default('') String description,
    double? price,
    @Default('TRY') String currency,
    String? birdId,
    @Default('') String species,
    String? mutation,
    @JsonKey(unknownEnumValue: BirdGender.unknown)
    @Default(BirdGender.unknown)
    BirdGender gender,
    String? age,
    @Default([]) List<String> imageUrls,
    @Default('') String city,
    @JsonKey(unknownEnumValue: MarketplaceListingStatus.unknown)
    @Default(MarketplaceListingStatus.active)
    MarketplaceListingStatus status,
    @Default(0) int viewCount,
    @Default(0) int messageCount,
    @Default(false) bool isVerifiedBreeder,
    @Default(false) bool isDeleted,
    @Default(false) bool needsReview,
    @JsonKey(includeFromJson: false) @Default(false) bool isFavoritedByMe,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MarketplaceListing;

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceListingFromJson(json);
}

extension MarketplaceListingX on MarketplaceListing {
  String? get primaryImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : null;

  bool get hasBirdLinked => birdId != null && birdId!.isNotEmpty;

  String get priceDisplay {
    if (price == null) return '';
    return '${price!.toStringAsFixed(0)} $currency';
  }
}
```

- [ ] **Step 2: Code generation calistir**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generated `.freezed.dart` and `.g.dart` files without errors

- [ ] **Step 3: Analiz calistir**

Run: `flutter analyze lib/data/models/marketplace_listing_model.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/data/models/marketplace_listing_model.dart lib/data/models/marketplace_listing_model.freezed.dart lib/data/models/marketplace_listing_model.g.dart
git commit -m "feat(marketplace): add MarketplaceListing freezed model"
```

---

### Task 3: Model Serialization Testi

**Files:**
- Create: `test/data/models/marketplace_listing_model_test.dart`

- [ ] **Step 1: Test dosyasini olustur**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

void main() {
  group('MarketplaceListing', () {
    test('toJson/fromJson round-trip', () {
      final listing = MarketplaceListing(
        id: 'test-id',
        userId: 'user-1',
        username: 'TestUser',
        listingType: MarketplaceListingType.sale,
        title: 'Test Listing',
        description: 'A test listing',
        price: 500,
        currency: 'TRY',
        species: 'Budgerigar',
        gender: BirdGender.male,
        imageUrls: ['https://example.com/img.jpg'],
        city: 'Istanbul',
        status: MarketplaceListingStatus.active,
      );

      final json = listing.toJson();
      final restored = MarketplaceListing.fromJson(json);

      expect(restored.id, listing.id);
      expect(restored.userId, listing.userId);
      expect(restored.listingType, listing.listingType);
      expect(restored.title, listing.title);
      expect(restored.price, listing.price);
      expect(restored.gender, listing.gender);
      expect(restored.city, listing.city);
      expect(restored.status, listing.status);
      expect(restored.imageUrls, listing.imageUrls);
    });

    test('deserializes unknown listingType to unknown', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-1',
        'listing_type': 'barter_supreme',
        'title': 'X',
        'description': 'Y',
        'species': 'Budgerigar',
        'gender': 'male',
        'city': 'Ankara',
        'status': 'active',
      };
      final listing = MarketplaceListing.fromJson(json);
      expect(listing.listingType, MarketplaceListingType.unknown);
    });

    test('deserializes unknown status to unknown', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-1',
        'listing_type': 'sale',
        'title': 'X',
        'description': 'Y',
        'species': 'Budgerigar',
        'gender': 'male',
        'city': 'Ankara',
        'status': 'pending_review',
      };
      final listing = MarketplaceListing.fromJson(json);
      expect(listing.status, MarketplaceListingStatus.unknown);
    });

    test('deserializes unknown gender to unknown', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-1',
        'listing_type': 'sale',
        'title': 'X',
        'description': 'Y',
        'species': 'Budgerigar',
        'gender': 'alien',
        'city': 'Ankara',
        'status': 'active',
      };
      final listing = MarketplaceListing.fromJson(json);
      expect(listing.gender, BirdGender.unknown);
    });

    test('priceDisplay formats correctly', () {
      final listing = MarketplaceListing(
        id: 'id',
        userId: 'u',
        price: 1500,
        currency: 'TRY',
      );
      expect(listing.priceDisplay, '1500 TRY');
    });

    test('priceDisplay returns empty when price is null', () {
      final listing = MarketplaceListing(
        id: 'id',
        userId: 'u',
      );
      expect(listing.priceDisplay, '');
    });

    test('hasBirdLinked returns true when birdId set', () {
      final listing = MarketplaceListing(
        id: 'id',
        userId: 'u',
        birdId: 'bird-1',
      );
      expect(listing.hasBirdLinked, isTrue);
    });

    test('hasBirdLinked returns false when birdId null', () {
      final listing = MarketplaceListing(
        id: 'id',
        userId: 'u',
      );
      expect(listing.hasBirdLinked, isFalse);
    });

    test('primaryImageUrl returns first image', () {
      final listing = MarketplaceListing(
        id: 'id',
        userId: 'u',
        imageUrls: ['img1.jpg', 'img2.jpg'],
      );
      expect(listing.primaryImageUrl, 'img1.jpg');
    });

    test('primaryImageUrl returns null when empty', () {
      final listing = MarketplaceListing(
        id: 'id',
        userId: 'u',
      );
      expect(listing.primaryImageUrl, isNull);
    });

    test('default values are correct', () {
      final listing = MarketplaceListing(id: 'id', userId: 'u');
      expect(listing.listingType, MarketplaceListingType.sale);
      expect(listing.status, MarketplaceListingStatus.active);
      expect(listing.currency, 'TRY');
      expect(listing.viewCount, 0);
      expect(listing.messageCount, 0);
      expect(listing.isVerifiedBreeder, false);
      expect(listing.isDeleted, false);
      expect(listing.needsReview, false);
      expect(listing.isFavoritedByMe, false);
      expect(listing.imageUrls, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Testi calistir**

Run: `flutter test test/data/models/marketplace_listing_model_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/data/models/marketplace_listing_model_test.dart
git commit -m "test(marketplace): add model serialization tests"
```

---

### Task 4: Supabase Constants

**Files:**
- Modify: `lib/core/constants/supabase_constants.dart`

- [ ] **Step 1: Marketplace tablo ve storage sabitleri ekle**

Dosyanin community tablolari bolumunun altina (mevcut community satirlarinin sonrasina) ekle:

```dart
  // Marketplace
  static const String marketplaceListingsTable = 'marketplace_listings';
  static const String marketplaceFavoritesTable = 'marketplace_favorites';
```

Storage buckets bolumune ekle:

```dart
  static const String marketplacePhotosBucket = 'marketplace-photos';
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/core/constants/supabase_constants.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/supabase_constants.dart
git commit -m "feat(marketplace): add supabase table and bucket constants"
```

---

### Task 5: Supabase Migration

**Files:**
- Create: `supabase/migrations/<timestamp>_create_marketplace_tables.sql`

- [ ] **Step 1: Migration dosyasini olustur**

Dosya adi: `supabase/migrations/20260402100000_create_marketplace_tables.sql`

```sql
-- Marketplace Listings table
CREATE TABLE IF NOT EXISTS marketplace_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  listing_type TEXT NOT NULL DEFAULT 'sale'
    CHECK (listing_type IN ('sale', 'adoption', 'trade', 'wanted')),
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price DOUBLE PRECISION,
  currency TEXT NOT NULL DEFAULT 'TRY',
  bird_id UUID,
  species TEXT NOT NULL DEFAULT '',
  mutation TEXT,
  gender TEXT NOT NULL DEFAULT 'unknown',
  age TEXT,
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  city TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'sold', 'reserved', 'closed')),
  view_count INTEGER NOT NULL DEFAULT 0,
  message_count INTEGER NOT NULL DEFAULT 0,
  is_verified_breeder BOOLEAN NOT NULL DEFAULT false,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  needs_review BOOLEAN NOT NULL DEFAULT false,
  reviewed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_user_id ON marketplace_listings(user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_city ON marketplace_listings(city);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_listing_type ON marketplace_listings(listing_type);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_status ON marketplace_listings(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_created_at ON marketplace_listings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_needs_review ON marketplace_listings(needs_review) WHERE needs_review = true;

-- Full-text search with tRGM (requires pg_trgm extension)
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_title_trgm ON marketplace_listings USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_desc_trgm ON marketplace_listings USING gin (description gin_trgm_ops);

-- RLS
ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;

-- Public read for active, non-deleted listings
CREATE POLICY "marketplace_listings_public_read" ON marketplace_listings
  FOR SELECT USING (
    (status = 'active' AND is_deleted = false AND needs_review = false)
    OR user_id = auth.uid()
  );

-- Users manage own listings
CREATE POLICY "marketplace_listings_insert" ON marketplace_listings
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "marketplace_listings_update" ON marketplace_listings
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "marketplace_listings_delete" ON marketplace_listings
  FOR DELETE USING (user_id = auth.uid());

-- Marketplace Favorites table
CREATE TABLE IF NOT EXISTS marketplace_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, listing_id)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_favorites_user_id ON marketplace_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_favorites_listing_id ON marketplace_favorites(listing_id);

-- RLS
ALTER TABLE marketplace_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "marketplace_favorites_own_read" ON marketplace_favorites
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "marketplace_favorites_own_insert" ON marketplace_favorites
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "marketplace_favorites_own_delete" ON marketplace_favorites
  FOR DELETE USING (user_id = auth.uid());

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_marketplace_listings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER marketplace_listings_updated_at
  BEFORE UPDATE ON marketplace_listings
  FOR EACH ROW
  EXECUTE FUNCTION update_marketplace_listings_updated_at();
```

- [ ] **Step 2: Commit**

```bash
git add supabase/migrations/20260402100000_create_marketplace_tables.sql
git commit -m "feat(marketplace): add database migration for listings and favorites tables"
```

---

### Task 6: Remote Source

**Files:**
- Create: `lib/data/remote/api/marketplace_listing_remote_source.dart`

- [ ] **Step 1: Remote source dosyasini olustur**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/marketplace_listing_model.dart';

class MarketplaceListingRemoteSource {
  final SupabaseClient _client;

  MarketplaceListingRemoteSource(this._client);

  static const _selectColumns =
      'id, user_id, listing_type, title, description, price, currency, '
      'bird_id, species, mutation, gender, age, image_urls, city, status, '
      'view_count, message_count, is_verified_breeder, is_deleted, '
      'needs_review, created_at, updated_at';

  Future<List<Map<String, dynamic>>> fetchListings({
    int limit = 20,
    DateTime? before,
    String? city,
    String? listingType,
    String? gender,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      var query = _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq('is_deleted', false)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(limit);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      if (listingType != null && listingType.isNotEmpty) {
        query = query.eq('listing_type', listingType);
      }
      if (gender != null && gender.isNotEmpty) {
        query = query.eq('gender', gender);
      }
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchByUser(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .insert(data)
          .select(_selectColumns)
          .single();
      return response;
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .update(data)
          .eq('id', id)
          .select(_selectColumns)
          .single();
      return response;
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .update({'is_deleted': true})
          .eq('id', id);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .update({'status': status})
          .eq('id', id);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> incrementViewCount(String id) async {
    try {
      await _client.rpc('increment_marketplace_view_count', params: {
        'listing_id': id,
      });
    } catch (e, st) {
      AppLogger.warning('marketplace', 'View count increment failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> search(String query, {int limit = 20}) async {
    try {
      final sanitized = query.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      if (sanitized.isEmpty) return [];

      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq('is_deleted', false)
          .eq('status', 'active')
          .or('title.ilike.%$sanitized%,description.ilike.%$sanitized%')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }
}
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/data/remote/api/marketplace_listing_remote_source.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/data/remote/api/marketplace_listing_remote_source.dart
git commit -m "feat(marketplace): add listing remote source"
```

---

### Task 7: Favorites Remote Source

**Files:**
- Create: `lib/data/remote/api/marketplace_favorite_remote_source.dart`

- [ ] **Step 1: Favorites remote source olustur**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class MarketplaceFavoriteRemoteSource {
  final SupabaseClient _client;

  MarketplaceFavoriteRemoteSource(this._client);

  Future<List<String>> fetchFavoritedListingIds(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .select('listing_id')
          .eq('user_id', userId);
      return List<String>.from(
        (response as List).map((r) => r['listing_id'] as String),
      );
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> addFavorite(String userId, String listingId) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .insert({'user_id': userId, 'listing_id': listingId});
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> removeFavorite(String userId, String listingId) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }
}
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/data/remote/api/marketplace_favorite_remote_source.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/data/remote/api/marketplace_favorite_remote_source.dart
git commit -m "feat(marketplace): add favorite remote source"
```

---

### Task 8: Remote Source Providers

**Files:**
- Modify: `lib/data/remote/api/remote_source_providers.dart`

- [ ] **Step 1: Import ve provider'lari ekle**

Dosyanin ust kismina import ekle:

```dart
import 'marketplace_listing_remote_source.dart';
import 'marketplace_favorite_remote_source.dart';
```

Community provider'larinin altina marketplace provider'larini ekle:

```dart
final marketplaceListingRemoteSourceProvider =
    Provider<MarketplaceListingRemoteSource>((ref) {
  return MarketplaceListingRemoteSource(
    ref.watch(supabaseClientProvider),
  );
});

final marketplaceFavoriteRemoteSourceProvider =
    Provider<MarketplaceFavoriteRemoteSource>((ref) {
  return MarketplaceFavoriteRemoteSource(
    ref.watch(supabaseClientProvider),
  );
});
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/data/remote/api/remote_source_providers.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/data/remote/api/remote_source_providers.dart
git commit -m "feat(marketplace): register remote source providers"
```

---

### Task 9: Repository

**Files:**
- Create: `lib/data/repositories/marketplace_repository.dart`

- [ ] **Step 1: Repository dosyasini olustur**

```dart
import '../models/marketplace_listing_model.dart';
import '../remote/api/marketplace_listing_remote_source.dart';
import '../remote/api/marketplace_favorite_remote_source.dart';
import '../../core/utils/logger.dart';

class MarketplaceRepository {
  final MarketplaceListingRemoteSource _listingSource;
  final MarketplaceFavoriteRemoteSource _favoriteSource;

  const MarketplaceRepository({
    required MarketplaceListingRemoteSource listingSource,
    required MarketplaceFavoriteRemoteSource favoriteSource,
  })  : _listingSource = listingSource,
        _favoriteSource = favoriteSource;

  Future<List<MarketplaceListing>> getListings({
    required String currentUserId,
    int limit = 20,
    DateTime? before,
    String? city,
    String? listingType,
    String? gender,
    double? minPrice,
    double? maxPrice,
  }) async {
    final rows = await _listingSource.fetchListings(
      limit: limit,
      before: before,
      city: city,
      listingType: listingType,
      gender: gender,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    return _enrichListings(rows, currentUserId);
  }

  Future<MarketplaceListing?> getById({
    required String id,
    required String currentUserId,
  }) async {
    final row = await _listingSource.fetchById(id);
    if (row == null) return null;
    final enriched = await _enrichListings([row], currentUserId);
    return enriched.firstOrNull;
  }

  Future<List<MarketplaceListing>> getByUser({
    required String userId,
    required String currentUserId,
  }) async {
    final rows = await _listingSource.fetchByUser(userId);
    return _enrichListings(rows, currentUserId);
  }

  Future<MarketplaceListing> create(Map<String, dynamic> data) async {
    final row = await _listingSource.insert(data);
    return MarketplaceListing.fromJson(row);
  }

  Future<MarketplaceListing> updateListing(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await _listingSource.update(id, data);
    return MarketplaceListing.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _listingSource.softDelete(id);
  }

  Future<void> updateStatus(String id, String status) async {
    await _listingSource.updateStatus(id, status);
  }

  Future<void> incrementViewCount(String id) async {
    await _listingSource.incrementViewCount(id);
  }

  Future<void> toggleFavorite({
    required String userId,
    required String listingId,
    required bool isFavorited,
  }) async {
    if (isFavorited) {
      await _favoriteSource.removeFavorite(userId, listingId);
    } else {
      await _favoriteSource.addFavorite(userId, listingId);
    }
  }

  Future<List<MarketplaceListing>> search({
    required String query,
    required String currentUserId,
    int limit = 20,
  }) async {
    final rows = await _listingSource.search(query, limit: limit);
    return _enrichListings(rows, currentUserId);
  }

  Future<List<MarketplaceListing>> _enrichListings(
    List<Map<String, dynamic>> rows,
    String currentUserId,
  ) async {
    if (rows.isEmpty) return [];

    List<String> favoritedIds = [];
    try {
      favoritedIds =
          await _favoriteSource.fetchFavoritedListingIds(currentUserId);
    } catch (e) {
      AppLogger.warning('marketplace', 'Failed to fetch favorites: $e');
    }

    return rows.map((row) {
      final listing = MarketplaceListing.fromJson(row);
      return listing.copyWith(
        isFavoritedByMe: favoritedIds.contains(listing.id),
      );
    }).toList();
  }
}
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/data/repositories/marketplace_repository.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/marketplace_repository.dart
git commit -m "feat(marketplace): add marketplace repository"
```

---

### Task 10: Repository Provider

**Files:**
- Modify: `lib/data/repositories/repository_providers.dart`

- [ ] **Step 1: Import ve provider ekle**

Import ekle:

```dart
import 'marketplace_repository.dart';
```

Community provider'larinin altina ekle:

```dart
final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(
    listingSource: ref.watch(marketplaceListingRemoteSourceProvider),
    favoriteSource: ref.watch(marketplaceFavoriteRemoteSourceProvider),
  );
});
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/data/repositories/repository_providers.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/repository_providers.dart
git commit -m "feat(marketplace): register marketplace repository provider"
```

---

### Task 11: Feature Providers

**Files:**
- Create: `lib/features/marketplace/providers/marketplace_providers.dart`

- [ ] **Step 1: Provider dosyasini olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/marketplace_enums.dart';
import '../../../data/models/marketplace_listing_model.dart';
import '../../../data/repositories/marketplace_repository.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../features/breeding/providers/breeding_providers.dart';

export 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
export 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';

/// Feature flag
final isMarketplaceEnabledProvider = Provider<bool>((ref) => true);

/// Filter enums
enum MarketplaceFilter {
  all,
  sale,
  adoption,
  trade,
  wanted;

  String get label => switch (this) {
        MarketplaceFilter.all => 'common.all'.tr(),
        MarketplaceFilter.sale => 'marketplace.type_sale'.tr(),
        MarketplaceFilter.adoption => 'marketplace.type_adoption'.tr(),
        MarketplaceFilter.trade => 'marketplace.type_trade'.tr(),
        MarketplaceFilter.wanted => 'marketplace.type_wanted'.tr(),
      };
}

enum MarketplaceSort {
  newest,
  priceAsc,
  priceDesc;

  String get label => switch (this) {
        MarketplaceSort.newest => 'marketplace.sort_newest'.tr(),
        MarketplaceSort.priceAsc => 'marketplace.sort_price_asc'.tr(),
        MarketplaceSort.priceDesc => 'marketplace.sort_price_desc'.tr(),
      };
}

/// Filter state
class MarketplaceFilterNotifier extends Notifier<MarketplaceFilter> {
  @override
  MarketplaceFilter build() => MarketplaceFilter.all;
}

final marketplaceFilterProvider =
    NotifierProvider<MarketplaceFilterNotifier, MarketplaceFilter>(
  MarketplaceFilterNotifier.new,
);

/// Sort state
class MarketplaceSortNotifier extends Notifier<MarketplaceSort> {
  @override
  MarketplaceSort build() => MarketplaceSort.newest;
}

final marketplaceSortProvider =
    NotifierProvider<MarketplaceSortNotifier, MarketplaceSort>(
  MarketplaceSortNotifier.new,
);

/// Search state
class MarketplaceSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final marketplaceSearchQueryProvider =
    NotifierProvider<MarketplaceSearchQueryNotifier, String>(
  MarketplaceSearchQueryNotifier.new,
);

/// City filter state
class MarketplaceCityFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final marketplaceCityFilterProvider =
    NotifierProvider<MarketplaceCityFilterNotifier, String?>(
  MarketplaceCityFilterNotifier.new,
);

/// Listings feed provider
final marketplaceListingsProvider =
    FutureProvider.family<List<MarketplaceListing>, String>(
  (ref, userId) async {
    final repo = ref.watch(marketplaceRepositoryProvider);
    final filter = ref.watch(marketplaceFilterProvider);
    final city = ref.watch(marketplaceCityFilterProvider);

    String? listingType;
    if (filter != MarketplaceFilter.all) {
      listingType = filter.name;
    }

    return repo.getListings(
      currentUserId: userId,
      city: city,
      listingType: listingType,
    );
  },
);

/// Single listing detail
final marketplaceListingByIdProvider =
    FutureProvider.family<MarketplaceListing?, ({String id, String userId})>(
  (ref, params) async {
    final repo = ref.watch(marketplaceRepositoryProvider);
    return repo.getById(id: params.id, currentUserId: params.userId);
  },
);

/// My listings
final myMarketplaceListingsProvider =
    FutureProvider.family<List<MarketplaceListing>, String>(
  (ref, userId) async {
    final repo = ref.watch(marketplaceRepositoryProvider);
    return repo.getByUser(userId: userId, currentUserId: userId);
  },
);

/// Filtered and sorted listings (computed)
final filteredMarketplaceListingsProvider =
    Provider.family<List<MarketplaceListing>, List<MarketplaceListing>>(
  (ref, listings) {
    final sort = ref.watch(marketplaceSortProvider);
    final query = ref.watch(marketplaceSearchQueryProvider).toLowerCase().trim();

    var result = listings;

    if (query.isNotEmpty) {
      result = result.where((l) {
        return l.title.toLowerCase().contains(query) ||
            l.description.toLowerCase().contains(query) ||
            l.species.toLowerCase().contains(query) ||
            l.city.toLowerCase().contains(query) ||
            (l.mutation?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    switch (sort) {
      case MarketplaceSort.newest:
        result.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      case MarketplaceSort.priceAsc:
        result.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      case MarketplaceSort.priceDesc:
        result.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    }

    return result;
  },
);
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/features/marketplace/providers/marketplace_providers.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/marketplace/providers/marketplace_providers.dart
git commit -m "feat(marketplace): add feature providers with filter, sort, and search"
```

---

### Task 12: Form Providers

**Files:**
- Create: `lib/features/marketplace/providers/marketplace_form_providers.dart`

- [ ] **Step 1: Form provider dosyasini olustur**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../features/breeding/providers/breeding_providers.dart';

class MarketplaceFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const MarketplaceFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  MarketplaceFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) =>
      MarketplaceFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

class MarketplaceFormNotifier extends Notifier<MarketplaceFormState> {
  @override
  MarketplaceFormState build() => const MarketplaceFormState();

  Future<void> createListing({
    required String userId,
    required MarketplaceListingType listingType,
    required String title,
    required String description,
    double? price,
    String? birdId,
    required String species,
    String? mutation,
    required BirdGender gender,
    String? age,
    required List<String> imageUrls,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.create({
        'id': const Uuid().v4(),
        'user_id': userId,
        'listing_type': listingType.toJson(),
        'title': title,
        'description': description,
        if (price != null) 'price': price,
        if (birdId != null) 'bird_id': birdId,
        'species': species,
        if (mutation != null) 'mutation': mutation,
        'gender': gender.toJson(),
        if (age != null) 'age': age,
        'image_urls': imageUrls,
        'city': city,
      });
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateListing({
    required String listingId,
    required MarketplaceListingType listingType,
    required String title,
    required String description,
    double? price,
    String? birdId,
    required String species,
    String? mutation,
    required BirdGender gender,
    String? age,
    required List<String> imageUrls,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateListing(listingId, {
        'listing_type': listingType.toJson(),
        'title': title,
        'description': description,
        'price': price,
        'bird_id': birdId,
        'species': species,
        'mutation': mutation,
        'gender': gender.toJson(),
        'age': age,
        'image_urls': imageUrls,
        'city': city,
      });
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteListing(String listingId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.delete(listingId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus(String listingId, MarketplaceListingStatus status) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateStatus(listingId, status.toJson());
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite({
    required String userId,
    required String listingId,
    required bool isFavorited,
  }) async {
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.toggleFavorite(
        userId: userId,
        listingId: listingId,
        isFavorited: isFavorited,
      );
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
    }
  }

  void reset() => state = const MarketplaceFormState();
}

final marketplaceFormStateProvider =
    NotifierProvider<MarketplaceFormNotifier, MarketplaceFormState>(
  MarketplaceFormNotifier.new,
);
```

- [ ] **Step 2: Analiz calistir**

Run: `flutter analyze lib/features/marketplace/providers/marketplace_form_providers.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/marketplace/providers/marketplace_form_providers.dart
git commit -m "feat(marketplace): add form notifier with create, update, delete, favorite"
```

---

### Task 13: Lokalizasyon Keyleri

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: tr.json'a marketplace bolumu ekle**

Mevcut JSON'un uygun yerine (community'nin altina) ekle:

```json
"marketplace": {
  "title": "Pazar Yeri",
  "add_listing": "İlan Ver",
  "new_listing": "Yeni İlan",
  "edit_listing": "İlanı Düzenle",
  "my_listings": "İlanlarım",
  "no_listings": "Henüz ilan yok",
  "no_listings_hint": "İlk ilanınızı verin",
  "no_results": "Aramanızla eşleşen ilan bulunamadı",
  "type_sale": "Satılık",
  "type_adoption": "Sahiplendirme",
  "type_trade": "Takas",
  "type_wanted": "Aranıyor",
  "status_active": "Aktif",
  "status_sold": "Satıldı",
  "status_reserved": "Rezerve",
  "status_closed": "Kapatıldı",
  "sort_newest": "En Yeni",
  "sort_price_asc": "Fiyat (Artan)",
  "sort_price_desc": "Fiyat (Azalan)",
  "title_label": "İlan Başlığı",
  "title_required": "İlan başlığı zorunludur",
  "description_label": "Açıklama",
  "description_required": "Açıklama zorunludur",
  "price_label": "Fiyat",
  "price_required": "Satış ilanı için fiyat zorunludur",
  "species_label": "Tür",
  "species_required": "Tür bilgisi zorunludur",
  "mutation_label": "Mutasyon",
  "gender_label": "Cinsiyet",
  "age_label": "Yaş",
  "city_label": "Şehir",
  "city_required": "Şehir bilgisi zorunludur",
  "city_filter": "Şehir Filtresi",
  "all_cities": "Tüm Şehirler",
  "listing_type_label": "İlan Tipi",
  "add_photos": "Fotoğraf Ekle",
  "max_photos": "En fazla 5 fotoğraf eklenebilir",
  "link_bird": "Kuş Bağla",
  "link_bird_hint": "Mevcut kuşlarınızdan birini ilana bağlayın",
  "linked_bird": "Bağlı Kuş",
  "view_count": "{} görüntülenme",
  "message_seller": "Satıcıya Mesaj",
  "message_owner": "İlan Sahibine Mesaj",
  "favorite": "Favorilere Ekle",
  "unfavorite": "Favorilerden Kaldır",
  "mark_sold": "Satıldı Olarak İşaretle",
  "mark_reserved": "Rezerve Et",
  "close_listing": "İlanı Kapat",
  "reactivate": "Tekrar Yayınla",
  "confirm_delete": "Bu ilanı silmek istediğinizden emin misiniz?",
  "delete_success": "İlan silindi",
  "save_success": "İlan kaydedildi",
  "update_success": "İlan güncellendi",
  "verified_breeder": "Doğrulanmış Yetiştirici",
  "free_tier_limit": "Ücretsiz planda en fazla {} aktif ilan verebilirsiniz",
  "listing_detail": "İlan Detayı",
  "seller_info": "Satıcı Bilgileri",
  "bird_info": "Kuş Bilgileri",
  "contact_seller": "İletişime Geç",
  "report_listing": "İlanı Bildir",
  "share_listing": "İlanı Paylaş",
  "search_hint": "İlan ara...",
  "filter_results": "Sonuçları Filtrele",
  "price_range": "Fiyat Aralığı",
  "min_price": "Min Fiyat",
  "max_price": "Max Fiyat",
  "genetics_card": "Genetik Bilgi Kartı",
  "listing_error": "İlan yüklenirken hata oluştu",
  "save_error": "İlan kaydedilirken hata oluştu"
}
```

- [ ] **Step 2: en.json'a marketplace bolumu ekle**

```json
"marketplace": {
  "title": "Marketplace",
  "add_listing": "Create Listing",
  "new_listing": "New Listing",
  "edit_listing": "Edit Listing",
  "my_listings": "My Listings",
  "no_listings": "No listings yet",
  "no_listings_hint": "Create your first listing",
  "no_results": "No listings match your search",
  "type_sale": "For Sale",
  "type_adoption": "For Adoption",
  "type_trade": "For Trade",
  "type_wanted": "Wanted",
  "status_active": "Active",
  "status_sold": "Sold",
  "status_reserved": "Reserved",
  "status_closed": "Closed",
  "sort_newest": "Newest",
  "sort_price_asc": "Price (Low to High)",
  "sort_price_desc": "Price (High to Low)",
  "title_label": "Listing Title",
  "title_required": "Listing title is required",
  "description_label": "Description",
  "description_required": "Description is required",
  "price_label": "Price",
  "price_required": "Price is required for sale listings",
  "species_label": "Species",
  "species_required": "Species is required",
  "mutation_label": "Mutation",
  "gender_label": "Gender",
  "age_label": "Age",
  "city_label": "City",
  "city_required": "City is required",
  "city_filter": "City Filter",
  "all_cities": "All Cities",
  "listing_type_label": "Listing Type",
  "add_photos": "Add Photos",
  "max_photos": "Maximum 5 photos allowed",
  "link_bird": "Link Bird",
  "link_bird_hint": "Link one of your birds to this listing",
  "linked_bird": "Linked Bird",
  "view_count": "{} views",
  "message_seller": "Message Seller",
  "message_owner": "Message Owner",
  "favorite": "Add to Favorites",
  "unfavorite": "Remove from Favorites",
  "mark_sold": "Mark as Sold",
  "mark_reserved": "Reserve",
  "close_listing": "Close Listing",
  "reactivate": "Reactivate",
  "confirm_delete": "Are you sure you want to delete this listing?",
  "delete_success": "Listing deleted",
  "save_success": "Listing saved",
  "update_success": "Listing updated",
  "verified_breeder": "Verified Breeder",
  "free_tier_limit": "Free plan allows up to {} active listings",
  "listing_detail": "Listing Detail",
  "seller_info": "Seller Info",
  "bird_info": "Bird Info",
  "contact_seller": "Contact Seller",
  "report_listing": "Report Listing",
  "share_listing": "Share Listing",
  "search_hint": "Search listings...",
  "filter_results": "Filter Results",
  "price_range": "Price Range",
  "min_price": "Min Price",
  "max_price": "Max Price",
  "genetics_card": "Genetics Card",
  "listing_error": "Error loading listing",
  "save_error": "Error saving listing"
}
```

- [ ] **Step 3: de.json'a marketplace bolumu ekle**

```json
"marketplace": {
  "title": "Marktplatz",
  "add_listing": "Anzeige erstellen",
  "new_listing": "Neue Anzeige",
  "edit_listing": "Anzeige bearbeiten",
  "my_listings": "Meine Anzeigen",
  "no_listings": "Noch keine Anzeigen",
  "no_listings_hint": "Erstellen Sie Ihre erste Anzeige",
  "no_results": "Keine Anzeigen gefunden",
  "type_sale": "Zu verkaufen",
  "type_adoption": "Zur Adoption",
  "type_trade": "Zum Tausch",
  "type_wanted": "Gesucht",
  "status_active": "Aktiv",
  "status_sold": "Verkauft",
  "status_reserved": "Reserviert",
  "status_closed": "Geschlossen",
  "sort_newest": "Neueste",
  "sort_price_asc": "Preis (aufsteigend)",
  "sort_price_desc": "Preis (absteigend)",
  "title_label": "Anzeigentitel",
  "title_required": "Anzeigentitel ist erforderlich",
  "description_label": "Beschreibung",
  "description_required": "Beschreibung ist erforderlich",
  "price_label": "Preis",
  "price_required": "Preis ist für Verkaufsanzeigen erforderlich",
  "species_label": "Art",
  "species_required": "Art ist erforderlich",
  "mutation_label": "Mutation",
  "gender_label": "Geschlecht",
  "age_label": "Alter",
  "city_label": "Stadt",
  "city_required": "Stadt ist erforderlich",
  "city_filter": "Stadtfilter",
  "all_cities": "Alle Städte",
  "listing_type_label": "Anzeigentyp",
  "add_photos": "Fotos hinzufügen",
  "max_photos": "Maximal 5 Fotos erlaubt",
  "link_bird": "Vogel verknüpfen",
  "link_bird_hint": "Verknüpfen Sie einen Ihrer Vögel mit dieser Anzeige",
  "linked_bird": "Verknüpfter Vogel",
  "view_count": "{} Aufrufe",
  "message_seller": "Verkäufer kontaktieren",
  "message_owner": "Besitzer kontaktieren",
  "favorite": "Zu Favoriten hinzufügen",
  "unfavorite": "Aus Favoriten entfernen",
  "mark_sold": "Als verkauft markieren",
  "mark_reserved": "Reservieren",
  "close_listing": "Anzeige schließen",
  "reactivate": "Wieder aktivieren",
  "confirm_delete": "Möchten Sie diese Anzeige wirklich löschen?",
  "delete_success": "Anzeige gelöscht",
  "save_success": "Anzeige gespeichert",
  "update_success": "Anzeige aktualisiert",
  "verified_breeder": "Verifizierter Züchter",
  "free_tier_limit": "Im kostenlosen Plan sind maximal {} aktive Anzeigen erlaubt",
  "listing_detail": "Anzeigendetail",
  "seller_info": "Verkäuferinfo",
  "bird_info": "Vogelinfo",
  "contact_seller": "Verkäufer kontaktieren",
  "report_listing": "Anzeige melden",
  "share_listing": "Anzeige teilen",
  "search_hint": "Anzeigen suchen...",
  "filter_results": "Ergebnisse filtern",
  "price_range": "Preisbereich",
  "min_price": "Mindestpreis",
  "max_price": "Höchstpreis",
  "genetics_card": "Genetik-Karte",
  "listing_error": "Fehler beim Laden der Anzeige",
  "save_error": "Fehler beim Speichern der Anzeige"
}
```

- [ ] **Step 4: L10n sync kontrolu**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All keys in sync across tr/en/de

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(marketplace): add localization keys for tr/en/de"
```

---

### Task 14: Route Names ve Routes

**Files:**
- Modify: `lib/router/route_names.dart`
- Create: `lib/router/routes/marketplace_routes.dart`
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Route sabitleri ekle**

`lib/router/route_names.dart` dosyasindaki community bolumunun altina ekle:

```dart
  // Marketplace
  static const marketplace = '/marketplace';
  static const marketplaceDetail = '/marketplace/:id';
  static const marketplaceForm = '/marketplace/form';
  static const marketplaceMyListings = '/marketplace/my-listings';
```

- [ ] **Step 2: Route builder dosyasini olustur**

`lib/router/routes/marketplace_routes.dart`:

```dart
import 'package:go_router/go_router.dart';

import '../../core/widgets/not_found_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/marketplace/screens/marketplace_detail_screen.dart';
import '../../features/marketplace/screens/marketplace_form_screen.dart';
import '../../features/marketplace/screens/marketplace_my_listings_screen.dart';
import '../route_names.dart';
import '../route_utils.dart';

List<RouteBase> buildMarketplaceRoutes() => [
      GoRoute(
        path: AppRoutes.marketplace,
        builder: (context, state) => const MarketplaceScreen(),
        routes: [
          // Specific paths BEFORE parameterized
          GoRoute(
            path: 'form',
            builder: (context, state) => MarketplaceFormScreen(
              editListingId: state.uri.queryParameters['editId'],
            ),
          ),
          GoRoute(
            path: 'my-listings',
            builder: (context, state) =>
                const MarketplaceMyListingsScreen(),
          ),
          // Parameterized AFTER specific
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              if (!isValidRouteId(id)) return const NotFoundScreen();
              return MarketplaceDetailScreen(listingId: id);
            },
          ),
        ],
      ),
    ];
```

- [ ] **Step 3: App router'a marketplace routes'u entegre et**

`lib/router/app_router.dart` dosyasinda:
- Import ekle: `import 'routes/marketplace_routes.dart';`
- Community routes'un altina ekle: `...buildMarketplaceRoutes(),`

- [ ] **Step 4: Commit**

Not: Ekranlar henuz olusturulmadi, bu yuzden analyze burada calismaz. Ekranlar Task 15-18'de olusturulacak.

```bash
git add lib/router/route_names.dart lib/router/routes/marketplace_routes.dart lib/router/app_router.dart
git commit -m "feat(marketplace): add route names, route builder, and router integration"
```

---

### Task 15: Marketplace List Screen

**Files:**
- Create: `lib/features/marketplace/screens/marketplace_screen.dart`

- [ ] **Step 1: Liste ekranini olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../core/widgets/buttons/fab_button.dart';
import '../../../features/breeding/providers/breeding_providers.dart';
import '../../../router/route_names.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_listing_card.dart';
import '../widgets/marketplace_filter_bar.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final listingsAsync = ref.watch(marketplaceListingsProvider(userId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            tooltip: 'common.search'.tr(),
            onPressed: () {
              // Search handled via filter bar
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.listChecks),
            tooltip: 'marketplace.my_listings'.tr(),
            onPressed: () => context.push(AppRoutes.marketplaceMyListings),
          ),
        ],
      ),
      body: Column(
        children: [
          const MarketplaceFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(marketplaceListingsProvider(userId));
              },
              child: listingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => app.ErrorState(
                  message:
                      '${'common.data_load_error'.tr()}: $error',
                  onRetry: () => ref.invalidate(
                      marketplaceListingsProvider(userId)),
                ),
                data: (allListings) {
                  final listings = ref.watch(
                      filteredMarketplaceListingsProvider(allListings));

                  if (allListings.isEmpty) {
                    return EmptyState(
                      icon: AppIcon(AppIcons.bird),
                      title: 'marketplace.no_listings'.tr(),
                      subtitle: 'marketplace.no_listings_hint'.tr(),
                      actionLabel: 'marketplace.add_listing'.tr(),
                      onAction: () =>
                          context.push('${AppRoutes.marketplace}/form'),
                    );
                  }

                  if (listings.isEmpty) {
                    return EmptyState(
                      icon: const Icon(Icons.search_off),
                      title: 'common.no_results'.tr(),
                      subtitle: 'marketplace.no_results'.tr(),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xxxl * 2,
                    ),
                    itemCount: listings.length,
                    itemBuilder: (context, index) =>
                        MarketplaceListingCard(listing: listings[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FabButton(
        icon: const Icon(Icons.add),
        tooltip: 'marketplace.add_listing'.tr(),
        onPressed: () => context.push('${AppRoutes.marketplace}/form'),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/marketplace/screens/marketplace_screen.dart
git commit -m "feat(marketplace): add marketplace list screen"
```

---

### Task 16: Listing Card Widget

**Files:**
- Create: `lib/features/marketplace/widgets/marketplace_listing_card.dart`

- [ ] **Step 1: Kart widget'ini olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/marketplace_listing_model.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../router/route_names.dart';

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceListing listing;

  const MarketplaceListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.marketplace}/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing.primaryImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  listing.primaryImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      LucideIcons.image,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.isVerifiedBreeder)
                        Padding(
                          padding:
                              const EdgeInsets.only(left: AppSpacing.xs),
                          child: Icon(
                            LucideIcons.badgeCheck,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      StatusBadge(
                        label: _listingTypeLabel(listing.listingType),
                        icon: Icon(
                          _listingTypeIcon(listing.listingType),
                          size: 14,
                        ),
                      ),
                      const Spacer(),
                      if (listing.price != null)
                        Text(
                          listing.priceDisplay,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        listing.city,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${listing.species} · ${listing.gender.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _listingTypeLabel(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => 'marketplace.type_sale'.tr(),
        MarketplaceListingType.adoption =>
          'marketplace.type_adoption'.tr(),
        MarketplaceListingType.trade => 'marketplace.type_trade'.tr(),
        MarketplaceListingType.wanted => 'marketplace.type_wanted'.tr(),
        MarketplaceListingType.unknown => '',
      };

  IconData _listingTypeIcon(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => LucideIcons.tag,
        MarketplaceListingType.adoption => LucideIcons.heart,
        MarketplaceListingType.trade => LucideIcons.arrowLeftRight,
        MarketplaceListingType.wanted => LucideIcons.search,
        MarketplaceListingType.unknown => LucideIcons.helpCircle,
      };
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/marketplace/widgets/marketplace_listing_card.dart
git commit -m "feat(marketplace): add listing card widget"
```

---

### Task 17: Filter Bar Widget

**Files:**
- Create: `lib/features/marketplace/widgets/marketplace_filter_bar.dart`

- [ ] **Step 1: Filter bar widget'ini olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/marketplace_providers.dart';

class MarketplaceFilterBar extends ConsumerWidget {
  const MarketplaceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(marketplaceFilterProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: MarketplaceFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(marketplaceFilterProvider.notifier).state = filter;
              },
              selectedColor:
                  theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/marketplace/widgets/marketplace_filter_bar.dart
git commit -m "feat(marketplace): add filter bar widget"
```

---

### Task 18: Detail, Form, MyListings Screens (Stub)

**Files:**
- Create: `lib/features/marketplace/screens/marketplace_detail_screen.dart`
- Create: `lib/features/marketplace/screens/marketplace_form_screen.dart`
- Create: `lib/features/marketplace/screens/marketplace_my_listings_screen.dart`

- [ ] **Step 1: Detail screen olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../features/breeding/providers/breeding_providers.dart';
import '../../../router/route_names.dart';
import '../providers/marketplace_providers.dart';
import '../providers/marketplace_form_providers.dart';

class MarketplaceDetailScreen extends ConsumerWidget {
  final String listingId;

  const MarketplaceDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final listingAsync = ref.watch(
      marketplaceListingByIdProvider((id: listingId, userId: userId)),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace.listing_detail'.tr()),
      ),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => app.ErrorState(
          message: '${'marketplace.listing_error'.tr()}: $error',
          onRetry: () => ref.invalidate(
            marketplaceListingByIdProvider((id: listingId, userId: userId)),
          ),
        ),
        data: (listing) {
          if (listing == null) {
            return app.ErrorState(
              message: 'error.not_found'.tr(),
            );
          }

          final isOwner = listing.userId == userId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image gallery
                if (listing.imageUrls.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PageView.builder(
                      itemCount: listing.imageUrls.length,
                      itemBuilder: (context, index) => Image.network(
                        listing.imageUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      // Title + price
                      Text(
                        listing.title,
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (listing.price != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          listing.priceDisplay,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      // Description
                      Text(
                        listing.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Bird info
                      _InfoRow(
                        label: 'marketplace.species_label'.tr(),
                        value: listing.species,
                      ),
                      if (listing.mutation != null)
                        _InfoRow(
                          label: 'marketplace.mutation_label'.tr(),
                          value: listing.mutation!,
                        ),
                      _InfoRow(
                        label: 'marketplace.gender_label'.tr(),
                        value: listing.gender.name,
                      ),
                      if (listing.age != null)
                        _InfoRow(
                          label: 'marketplace.age_label'.tr(),
                          value: listing.age!,
                        ),
                      _InfoRow(
                        label: 'marketplace.city_label'.tr(),
                        value: listing.city,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Actions
                      if (!isOwner)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              // TODO: Mesajlasma entegrasyonu (Feature 2)
                            },
                            icon: const Icon(LucideIcons.messageCircle),
                            label: Text(
                                'marketplace.message_seller'.tr()),
                          ),
                        ),
                      if (isOwner) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '${AppRoutes.marketplace}/form?editId=${listing.id}',
                            ),
                            icon: const Icon(LucideIcons.edit),
                            label:
                                Text('marketplace.edit_listing'.tr()),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed =
                                  await showConfirmDialog(
                                context,
                                title: 'common.delete'.tr(),
                                message:
                                    'marketplace.confirm_delete'.tr(),
                                isDestructive: true,
                              );
                              if (confirmed == true) {
                                ref
                                    .read(marketplaceFormStateProvider
                                        .notifier)
                                    .deleteListing(listing.id);
                                if (context.mounted) context.pop();
                              }
                            },
                            icon: const Icon(LucideIcons.trash2),
                            label: Text('common.delete'.tr()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Form screen olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../features/breeding/providers/breeding_providers.dart';
import '../providers/marketplace_form_providers.dart';

class MarketplaceFormScreen extends ConsumerStatefulWidget {
  final String? editListingId;

  const MarketplaceFormScreen({super.key, this.editListingId});

  @override
  ConsumerState<MarketplaceFormScreen> createState() =>
      _MarketplaceFormScreenState();
}

class _MarketplaceFormScreenState
    extends ConsumerState<MarketplaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _speciesController = TextEditingController();
  final _mutationController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();

  MarketplaceListingType _listingType = MarketplaceListingType.sale;
  BirdGender _gender = BirdGender.unknown;

  bool get _isEdit => widget.editListingId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _speciesController.dispose();
    _mutationController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(marketplaceFormStateProvider);

    ref.listen<MarketplaceFormState>(marketplaceFormStateProvider,
        (_, state) {
      if (state.isSuccess) {
        ref.read(marketplaceFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'marketplace.edit_listing'.tr()
              : 'marketplace.new_listing'.tr(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Listing type
              DropdownButtonFormField<MarketplaceListingType>(
                initialValue: _listingType,
                decoration: InputDecoration(
                  labelText: 'marketplace.listing_type_label'.tr(),
                ),
                items: MarketplaceListingType.values
                    .where((t) => t != MarketplaceListingType.unknown)
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_typeLabel(type)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _listingType = value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'marketplace.title_label'.tr(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.title_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'marketplace.description_label'.tr(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.description_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Price (only for sale)
              if (_listingType == MarketplaceListingType.sale)
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'marketplace.price_label'.tr(),
                    suffixText: 'TRY',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_listingType == MarketplaceListingType.sale &&
                        (value == null || value.trim().isEmpty)) {
                      return 'marketplace.price_required'.tr();
                    }
                    return null;
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              // Species
              TextFormField(
                controller: _speciesController,
                decoration: InputDecoration(
                  labelText: 'marketplace.species_label'.tr(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.species_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Mutation
              TextFormField(
                controller: _mutationController,
                decoration: InputDecoration(
                  labelText: 'marketplace.mutation_label'.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Gender
              DropdownButtonFormField<BirdGender>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: 'marketplace.gender_label'.tr(),
                ),
                items: [BirdGender.male, BirdGender.female, BirdGender.unknown]
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _gender = value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              // Age
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'marketplace.age_label'.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'marketplace.city_label'.tr(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'marketplace.city_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Submit
              PrimaryButton(
                label: _isEdit
                    ? 'common.update'.tr()
                    : 'common.save'.tr(),
                isLoading: formState.isLoading,
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(marketplaceFormStateProvider.notifier);

    if (_isEdit) {
      notifier.updateListing(
        listingId: widget.editListingId!,
        listingType: _listingType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _listingType == MarketplaceListingType.sale
            ? double.tryParse(_priceController.text.trim())
            : null,
        species: _speciesController.text.trim(),
        mutation: _mutationController.text.trim().isEmpty
            ? null
            : _mutationController.text.trim(),
        gender: _gender,
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
        imageUrls: [],
        city: _cityController.text.trim(),
      );
    } else {
      notifier.createListing(
        userId: userId,
        listingType: _listingType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _listingType == MarketplaceListingType.sale
            ? double.tryParse(_priceController.text.trim())
            : null,
        species: _speciesController.text.trim(),
        mutation: _mutationController.text.trim().isEmpty
            ? null
            : _mutationController.text.trim(),
        gender: _gender,
        age: _ageController.text.trim().isEmpty
            ? null
            : _ageController.text.trim(),
        imageUrls: [],
        city: _cityController.text.trim(),
      );
    }
  }

  String _typeLabel(MarketplaceListingType type) => switch (type) {
        MarketplaceListingType.sale => 'marketplace.type_sale'.tr(),
        MarketplaceListingType.adoption =>
          'marketplace.type_adoption'.tr(),
        MarketplaceListingType.trade => 'marketplace.type_trade'.tr(),
        MarketplaceListingType.wanted => 'marketplace.type_wanted'.tr(),
        MarketplaceListingType.unknown => '',
      };
}
```

- [ ] **Step 3: My Listings screen olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../features/breeding/providers/breeding_providers.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_listing_card.dart';

class MarketplaceMyListingsScreen extends ConsumerWidget {
  const MarketplaceMyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final listingsAsync = ref.watch(myMarketplaceListingsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace.my_listings'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myMarketplaceListingsProvider(userId));
        },
        child: listingsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (error, _) => app.ErrorState(
            message: '${'common.data_load_error'.tr()}: $error',
            onRetry: () =>
                ref.invalidate(myMarketplaceListingsProvider(userId)),
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return EmptyState(
                icon: const Icon(Icons.storefront),
                title: 'marketplace.no_listings'.tr(),
                subtitle: 'marketplace.no_listings_hint'.tr(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) =>
                  MarketplaceListingCard(listing: listings[index]),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Analiz calistir**

Run: `flutter analyze lib/features/marketplace/`
Expected: No issues found (or minor warnings to fix)

- [ ] **Step 5: Commit**

```bash
git add lib/features/marketplace/screens/
git commit -m "feat(marketplace): add detail, form, and my-listings screens"
```

---

### Task 19: Widget Tests

**Files:**
- Create: `test/features/marketplace/screens/marketplace_screen_test.dart`
- Create: `test/features/marketplace/providers/marketplace_form_providers_test.dart`

- [ ] **Step 1: Liste ekrani widget testi**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/screens/marketplace_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

import '../../../helpers/test_localization.dart';

class MockMarketplaceRepository extends Mock
    implements MarketplaceRepository {}

void main() {
  late MockMarketplaceRepository mockRepo;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
  });

  Widget buildSubject({List<MarketplaceListing> listings = const []}) {
    when(() => mockRepo.getListings(
          currentUserId: any(named: 'currentUserId'),
          city: any(named: 'city'),
          listingType: any(named: 'listingType'),
        )).thenAnswer((_) async => listings);

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        marketplaceListingsProvider('test-user')
            .overrideWith((_) async => listings),
      ],
      child: const MaterialApp(home: MarketplaceScreen()),
    );
  }

  testWidgets('shows loading state', (tester) async {
    when(() => mockRepo.getListings(
          currentUserId: any(named: 'currentUserId'),
        )).thenAnswer((_) => Future.delayed(
          const Duration(seconds: 10),
          () => <MarketplaceListing>[],
        ));

    await pumpLocalizedWidget(tester, buildSubject());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no listings', (tester) async {
    await pumpLocalizedWidget(tester, buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('shows listings when data available', (tester) async {
    final listings = [
      MarketplaceListing(
        id: 'l1',
        userId: 'u1',
        title: 'Test Bird',
        species: 'Budgerigar',
        city: 'Istanbul',
      ),
    ];

    await pumpLocalizedWidget(tester, buildSubject(listings: listings));
    await tester.pumpAndSettle();

    expect(find.text('Test Bird'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Form notifier unit testi**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_form_providers.dart';

class MockMarketplaceRepository extends Mock
    implements MarketplaceRepository {}

void main() {
  late MockMarketplaceRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
    container = ProviderContainer(overrides: [
      marketplaceRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial state is correct', () {
    final state = container.read(marketplaceFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
  });

  test('createListing sets isSuccess on success', () async {
    when(() => mockRepo.create(any())).thenAnswer(
      (_) async => MarketplaceListing(id: 'new', userId: 'u1'),
    );

    await container
        .read(marketplaceFormStateProvider.notifier)
        .createListing(
          userId: 'u1',
          listingType: MarketplaceListingType.sale,
          title: 'Test',
          description: 'Desc',
          price: 100,
          species: 'Budgerigar',
          gender: BirdGender.male,
          imageUrls: [],
          city: 'Istanbul',
        );

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isSuccess, isTrue);
    expect(state.isLoading, isFalse);
  });

  test('createListing sets error on failure', () async {
    when(() => mockRepo.create(any())).thenThrow(Exception('Network error'));

    await container
        .read(marketplaceFormStateProvider.notifier)
        .createListing(
          userId: 'u1',
          listingType: MarketplaceListingType.sale,
          title: 'Test',
          description: 'Desc',
          species: 'Budgerigar',
          gender: BirdGender.male,
          imageUrls: [],
          city: 'Istanbul',
        );

    final state = container.read(marketplaceFormStateProvider);
    expect(state.error, isNotNull);
    expect(state.isLoading, isFalse);
  });

  test('deleteListing sets isSuccess on success', () async {
    when(() => mockRepo.delete(any())).thenAnswer((_) async {});

    await container
        .read(marketplaceFormStateProvider.notifier)
        .deleteListing('listing-1');

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isSuccess, isTrue);
  });

  test('reset clears state', () async {
    when(() => mockRepo.create(any())).thenAnswer(
      (_) async => MarketplaceListing(id: 'new', userId: 'u1'),
    );

    await container
        .read(marketplaceFormStateProvider.notifier)
        .createListing(
          userId: 'u1',
          listingType: MarketplaceListingType.sale,
          title: 'Test',
          description: 'Desc',
          species: 'Budgerigar',
          gender: BirdGender.male,
          imageUrls: [],
          city: 'Istanbul',
        );

    container.read(marketplaceFormStateProvider.notifier).reset();

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
  });
}
```

- [ ] **Step 3: Testleri calistir**

Run: `flutter test test/features/marketplace/`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add test/features/marketplace/
git commit -m "test(marketplace): add widget and provider unit tests"
```

---

### Task 20: CLAUDE.md Stats Guncelleme ve Final Dogrulama

**Files:**
- Modify: `CLAUDE.md` (stats table)

- [ ] **Step 1: verify_rules.py calistir**

Run: `python3 scripts/verify_rules.py`
Expected: Check which stats need updating (feature modules, routes, enum files, models, etc.)

- [ ] **Step 2: Stats tablosunu guncelle**

CLAUDE.md'deki Codebase Stats tablosunda degisen degerleri guncelle:
- Feature modules: 20 → 21
- Routes: 60 → 64
- Enum files: 12 → 13
- Freezed models: artacak
- Diger degisen metrikler

- [ ] **Step 3: Code quality kontrolu**

Run: `python3 scripts/verify_code_quality.py`
Expected: No violations

- [ ] **Step 4: L10n sync kontrolu**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All keys in sync

- [ ] **Step 5: Flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: update CLAUDE.md stats for marketplace feature"
```
