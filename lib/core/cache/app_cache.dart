import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppCache {
  AppCache._();

  // ── Memory layer ──────────────────────────────────
  static final Map<String, _CacheEntry> _memory = {};

  // ── Prefix for disk keys ──────────────────────────
  static const _prefix = 'app_cache_';

  // ── Default TTLs used across the app ─────────────
  static const Duration ttlAllCars = Duration(minutes: 5);
  static const Duration ttlCategory = Duration(minutes: 3);
  static const Duration ttlSearch = Duration(minutes: 2);
  static const Duration ttlCarDetail = Duration(minutes: 10);
  static const Duration ttlBrandFilter = Duration(minutes: 3);

  // ── Keys ──────────────────────────────────────────
  static const String keyAllCars = 'cars_all';
  static String keyCategory(String c) => 'cars_cat_$c';
  static String keySearch(String q) => 'cars_search_${q.toLowerCase()}';
  static String keyCarDetail(String id) => 'car_detail_$id';
  static String keyBrand(String b) => 'cars_brand_$b';

  // ─────────────────────────────────────────────────
  // GET — returns decoded value or null if missing / stale
  // Checks memory first, then disk.
  // ─────────────────────────────────────────────────
  static Future<dynamic> get(String key) async {
    // 1. Memory hit
    final mem = _memory[key];
    if (mem != null) {
      if (!mem.isExpired) {
        debugPrint('[Cache] MEM HIT: $key');
        return mem.data;
      }
      // Stale — evict from memory
      _memory.remove(key);
      debugPrint('[Cache] MEM STALE: $key');
    }

    // 2. Disk hit
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final entry = _CacheEntry.fromJson(map);
        if (!entry.isExpired) {
          // Warm the memory layer
          _memory[key] = entry;
          debugPrint('[Cache] DISK HIT: $key');
          return entry.data;
        }
        // Stale — clean up disk
        await prefs.remove('$_prefix$key');
        debugPrint('[Cache] DISK STALE: $key');
      }
    } catch (e) {
      debugPrint('[Cache] GET ERROR ($key): $e');
    }

    return null;
  }

  // ─────────────────────────────────────────────────
  // SET — stores value in both memory and disk
  // ─────────────────────────────────────────────────
  static Future<void> set(
    String key,
    dynamic data, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final entry = _CacheEntry(data: data, expiresAt: DateTime.now().add(ttl));

    // Write to memory immediately
    _memory[key] = entry;

    // Write to disk async
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode(entry.toJson()));
      debugPrint('[Cache] SET: $key (TTL ${ttl.inSeconds}s)');
    } catch (e) {
      debugPrint('[Cache] SET ERROR ($key): $e');
    }
  }

  // ─────────────────────────────────────────────────
  // INVALIDATE — removes a specific key from both layers
  // Call this after adding/editing/deleting a car so the
  // home page fetches fresh data on next load.
  // ─────────────────────────────────────────────────
  static Future<void> invalidate(String key) async {
    _memory.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
      debugPrint('[Cache] INVALIDATED: $key');
    } catch (e) {
      debugPrint('[Cache] INVALIDATE ERROR ($key): $e');
    }
  }

  // Invalidate all car list caches (call after add/delete car)
  static Future<void> invalidateCarLists() async {
    await invalidate(keyAllCars);
    // Invalidate all category and brand caches
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs
        .getKeys()
        .where(
          (k) =>
              k.startsWith('${_prefix}cars_cat_') ||
              k.startsWith('${_prefix}cars_brand_') ||
              k.startsWith('${_prefix}cars_search_'),
        )
        .toList();
    for (final k in allKeys) {
      await prefs.remove(k);
    }
    _memory.removeWhere(
      (k, _) =>
          k.startsWith('cars_cat_') ||
          k.startsWith('cars_brand_') ||
          k.startsWith('cars_search_'),
    );
    debugPrint('[Cache] Invalidated all car list caches');
  }

  // ─────────────────────────────────────────────────
  // CLEAR — wipes everything (useful for logout)
  // ─────────────────────────────────────────────────
  static Future<void> clear() async {
    _memory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
      debugPrint('[Cache] CLEARED ALL (${keys.length} entries)');
    } catch (e) {
      debugPrint('[Cache] CLEAR ERROR: $e');
    }
  }

  // ─────────────────────────────────────────────────
  // STATUS — debug info about what's cached
  // ─────────────────────────────────────────────────
  static Future<CacheStats> getStats() async {
    int diskCount = 0;
    int diskBytes = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      diskCount = keys.length;
      for (final k in keys) {
        diskBytes += (prefs.getString(k) ?? '').length;
      }
    } catch (_) {}
    return CacheStats(
      memoryEntries: _memory.length,
      diskEntries: diskCount,
      diskBytes: diskBytes,
    );
  }
}

// ── Internal cache entry model ─────────────────────────────────
class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'data': data,
    'expires_at': expiresAt.toIso8601String(),
  };

  factory _CacheEntry.fromJson(Map<String, dynamic> map) => _CacheEntry(
    data: map['data'],
    expiresAt: DateTime.parse(map['expires_at'] as String),
  );
}

// ── Cache stats model (used by CacheDebugPage) ─────────────────
class CacheStats {
  final int memoryEntries;
  final int diskEntries;
  final int diskBytes;

  const CacheStats({
    required this.memoryEntries,
    required this.diskEntries,
    required this.diskBytes,
  });

  String get diskSize {
    if (diskBytes < 1024) return '$diskBytes B';
    if (diskBytes < 1024 * 1024) {
      return '${(diskBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(diskBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
