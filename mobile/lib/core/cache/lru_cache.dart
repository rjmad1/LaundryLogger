import 'dart:collection';

/// LRU cache entry with TTL support.
class _CacheEntry<T> {
  _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory LRU cache with TTL (time-to-live) support.
///
/// Used for caching expensive read operations like aggregates and summaries.
/// Invalidates entries on write operations or when TTL expires.
class LruCache<K, V> {
  /// Creates an LRU cache with max capacity and TTL.
  LruCache({
    required this.maxSize,
    required this.ttl,
  });

  /// Maximum number of entries to keep in cache.
  final int maxSize;

  /// Time-to-live for cache entries.
  final Duration ttl;

  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  /// Gets a value from cache if it exists and hasn't expired.
  V? get(K key) {
    final entry = _cache.remove(key);
    if (entry == null) return null;

    // Check if expired
    if (entry.isExpired) {
      return null;
    }

    // Move to end (most recently used)
    _cache[key] = entry;
    return entry.value;
  }

  /// Puts a value in the cache with TTL.
  void put(K key, V value) {
    // Remove if exists
    _cache.remove(key);

    // Add to end
    final expiresAt = DateTime.now().add(ttl);
    _cache[key] = _CacheEntry(value, expiresAt);

    // Evict oldest if over capacity
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Invalidates a specific key.
  void invalidate(K key) {
    _cache.remove(key);
  }

  /// Clears all cache entries.
  void clear() {
    _cache.clear();
  }

  /// Gets current cache size.
  int get size => _cache.length;

  /// Removes all expired entries.
  void removeExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }
}
