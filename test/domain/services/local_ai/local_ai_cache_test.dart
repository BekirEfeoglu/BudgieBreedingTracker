import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalAiCache', () {
    test('returns null on miss', () {
      final cache = LocalAiCache(
        maxEntries: 4,
        ttl: const Duration(minutes: 1),
      );

      expect(cache.get('missing'), isNull);
      expect(cache.length, 0);
    });

    test('stores and retrieves entries', () {
      final cache = LocalAiCache(
        maxEntries: 4,
        ttl: const Duration(minutes: 1),
      );

      cache.put('key', {'result': 'hello'});

      expect(cache.get('key'), {'result': 'hello'});
      expect(cache.length, 1);
    });

    test('expires entries past ttl', () {
      var now = DateTime(2026, 4, 19, 12);
      final cache = LocalAiCache(
        maxEntries: 4,
        ttl: const Duration(seconds: 30),
        now: () => now,
      );

      cache.put('key', {'result': 'stored'});
      expect(cache.get('key'), {'result': 'stored'});

      now = now.add(const Duration(seconds: 31));
      expect(cache.get('key'), isNull);
      expect(cache.length, 0, reason: 'expired entries are purged on miss');
    });

    test('evicts oldest entry when exceeding maxEntries', () {
      final cache = LocalAiCache(
        maxEntries: 2,
        ttl: const Duration(minutes: 5),
      );

      cache.put('a', {'v': 1});
      cache.put('b', {'v': 2});
      cache.put('c', {'v': 3});

      expect(cache.get('a'), isNull, reason: 'a was evicted');
      expect(cache.get('b'), {'v': 2});
      expect(cache.get('c'), {'v': 3});
    });

    test('re-inserting key refreshes recency and keeps single entry', () {
      final cache = LocalAiCache(
        maxEntries: 2,
        ttl: const Duration(minutes: 5),
      );

      cache.put('a', {'v': 1});
      cache.put('b', {'v': 2});
      cache.put('a', {'v': 11});
      cache.put('c', {'v': 3});

      expect(
        cache.get('a'),
        {'v': 11},
        reason: 'a was refreshed so it survives eviction',
      );
      expect(cache.get('b'), isNull, reason: 'b is now oldest and evicted');
      expect(cache.get('c'), {'v': 3});
    });

    test('get bumps recency so entry survives subsequent eviction', () {
      final cache = LocalAiCache(
        maxEntries: 2,
        ttl: const Duration(minutes: 5),
      );

      cache.put('a', {'v': 1});
      cache.put('b', {'v': 2});
      // Access 'a' so it becomes most-recent.
      expect(cache.get('a'), {'v': 1});
      cache.put('c', {'v': 3});

      expect(cache.get('a'), {'v': 1});
      expect(cache.get('b'), isNull, reason: 'b was least-recent and evicted');
      expect(cache.get('c'), {'v': 3});
    });

    test('clear drops all entries', () {
      final cache = LocalAiCache(
        maxEntries: 4,
        ttl: const Duration(minutes: 5),
      );

      cache.put('a', {'v': 1});
      cache.put('b', {'v': 2});
      cache.clear();

      expect(cache.length, 0);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
    });
  });
}
