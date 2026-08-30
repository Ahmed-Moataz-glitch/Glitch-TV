import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ApiCacheService {
  static const String boxName = 'api_network_cache_box';
  static ApiCacheService? _instance;

  ApiCacheService._();

  static ApiCacheService get instance {
    _instance ??= ApiCacheService._();
    return _instance!;
  }

  Future<Box<dynamic>?> _getBox() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<dynamic>(boxName);
      }
      return await Hive.openBox<dynamic>(boxName);
    } catch (e) {
      debugPrint('ApiCacheService._getBox error: $e');
      return null;
    }
  }

  /// Retrieves cached content if present and within [maxAge].
  Future<String?> get(String key, {Duration? maxAge}) async {
    try {
      final box = await _getBox();
      if (box == null) return null;
      final record = box.get(key);
      if (record == null) return null;

      if (record is Map) {
        final timestamp = record['timestamp'] as int?;
        final content = record['content'] as String?;
        if (content == null || content.isEmpty) return null;

        if (maxAge != null && timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (age > maxAge.inMilliseconds) {
            return null; // Expired
          }
        }
        return content;
      } else if (record is String) {
        return record;
      }
    } catch (e) {
      debugPrint('ApiCacheService.get error for $key: $e');
    }
    return null;
  }

  /// Retrieves cached content even if expired (useful for offline/network failure fallback).
  Future<String?> getFallback(String key) async {
    try {
      final box = await _getBox();
      if (box == null) return null;
      final record = box.get(key);
      if (record == null) return null;

      if (record is Map) {
        return record['content'] as String?;
      } else if (record is String) {
        return record;
      }
    } catch (e) {
      debugPrint('ApiCacheService.getFallback error for $key: $e');
    }
    return null;
  }

  /// Saves content with the current timestamp into the persistent cache.
  Future<void> put(String key, String content) async {
    try {
      if (content.trim().isEmpty) return;
      final box = await _getBox();
      if (box == null) return;
      await box.put(key, {
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('ApiCacheService.put error for $key: $e');
    }
  }

  /// Removes an item from the cache.
  Future<void> remove(String key) async {
    try {
      final box = await _getBox();
      if (box == null) return;
      await box.delete(key);
    } catch (e) {
      debugPrint('ApiCacheService.remove error for $key: $e');
    }
  }

  /// Clears all entries in the cache box.
  Future<void> clear() async {
    try {
      final box = await _getBox();
      if (box == null) return;
      await box.clear();
    } catch (e) {
      debugPrint('ApiCacheService.clear error: $e');
    }
  }
}
