import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class _HistoryCacheEntry {
  const _HistoryCacheEntry({
    required this.savedAt,
    required this.payload,
  });

  final DateTime savedAt;
  final Object payload;
}

class CachedValue<T> {
  const CachedValue({
    required this.value,
    required this.savedAt,
  });

  final T value;
  final DateTime savedAt;

  bool isStale(Duration ttl) {
    return DateTime.now().difference(savedAt) > ttl;
  }
}

class SensorCacheManager {
  SensorCacheManager._();

  static final SensorCacheManager instance = SensorCacheManager._();

  final Map<String, _HistoryCacheEntry> _memoryCache = {};

  Future<CachedValue<T>?> read<T>(
    String key,
    T Function(Object? payload) decoder,
  ) async {
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null) {
      return CachedValue(
        value: decoder(memoryEntry.payload),
        savedAt: memoryEntry.savedAt,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt =
          DateTime.tryParse(decoded['savedAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
      final payload = decoded['payload'];
      final entry = _HistoryCacheEntry(savedAt: savedAt, payload: payload);
      _memoryCache[key] = entry;
      return CachedValue(value: decoder(payload), savedAt: savedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Object payload) async {
    final entry = _HistoryCacheEntry(
      savedAt: DateTime.now(),
      payload: payload,
    );
    _memoryCache[key] = entry;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'savedAt': entry.savedAt.toIso8601String(),
        'payload': payload,
      }),
    );
  }
}
