import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_logger/core/cache/lru_cache.dart';

void main() {
  group('LruCache', () {
    test('should store and retrieve values', () {
      final cache = LruCache<String, int>(
        maxSize: 3,
        ttl: const Duration(seconds: 1),
      )
        ..put('a', 1)
        ..put('b', 2);

      expect(cache.get('a'), 1);
      expect(cache.get('b'), 2);
    });

    test('should evict oldest entry when max size exceeded', () {
      final cache = LruCache<String, int>(
        maxSize: 2,
        ttl: const Duration(seconds: 1),
      )
        ..put('a', 1)
        ..put('b', 2)
        ..put('c', 3); // Should evict 'a'

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
    });

    test('should respect LRU order', () {
      final cache = LruCache<String, int>(
        maxSize: 2,
        ttl: const Duration(seconds: 1),
      )
        ..put('a', 1)
        ..put('b', 2)
        // ignore: cascade_invocations
        ..get('a'); // Access 'a', making it most recent
      // ignore: cascade_invocations
      cache.put('c', 3); // Should evict 'b', not 'a'

      expect(cache.get('a'), 1);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), 3);
    });

    test('should expire entries after TTL', () async {
      final cache = LruCache<String, int>(
        maxSize: 3,
        ttl: const Duration(milliseconds: 100),
      )..put('a', 1);
      expect(cache.get('a'), 1);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(cache.get('a'), isNull);
    });

    test('should clear all entries', () {
      final cache = LruCache<String, int>(
        maxSize: 3,
        ttl: const Duration(seconds: 1),
      )
        ..put('a', 1)
        ..put('b', 2)
        ..clear();

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
      expect(cache.size, 0);
    });

    test('should invalidate specific key', () {
      final cache = LruCache<String, int>(
        maxSize: 3,
        ttl: const Duration(seconds: 1),
      )
        ..put('a', 1)
        ..put('b', 2)
        ..invalidate('a');

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), 2);
    });

    test('should remove expired entries', () async {
      final cache = LruCache<String, int>(
        maxSize: 3,
        ttl: const Duration(milliseconds: 100),
      )
        ..put('a', 1)
        ..put('b', 2);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      cache.removeExpired();

      expect(cache.size, 0);
    });
  });
}
