import 'dart:convert';
import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sov_inte_forbi/models/station.dart';

class LocalStorageService {
  static const _stationsKey = 'cached_stations';
  static const _stationsCachedAtKey = 'stations_cached_at';
  static const _localFavoritesKey = 'local_favorites';
  static const _localRecentKey = 'local_recent';
  static const _dismissCountKey = 'dismiss_count';
  static const _stationUsageKey = 'station_usage';
  static const _lastMilestoneKey = 'last_milestone';

  SharedPreferences? _prefs;
  bool _prefsUnavailable = false;
  final Map<String, Object?> _fallbackStore = {};

  Future<SharedPreferences?> _instanceOrNull() async {
    if (_prefsUnavailable) return null;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      _prefsUnavailable = true;
      dev.log(
        'SharedPreferences unavailable, using in-memory fallback: $e',
        name: 'Storage',
        level: 900,
      );
      return null;
    }
  }

  Future<String?> _getString(String key) async {
    final prefs = await _instanceOrNull();
    if (prefs != null) return prefs.getString(key);
    final value = _fallbackStore[key];
    return value is String ? value : null;
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await _instanceOrNull();
    if (prefs != null) {
      await prefs.setString(key, value);
      return;
    }
    _fallbackStore[key] = value;
  }

  Future<int?> _getInt(String key) async {
    final prefs = await _instanceOrNull();
    if (prefs != null) return prefs.getInt(key);
    final value = _fallbackStore[key];
    return value is int ? value : null;
  }

  Future<void> _setInt(String key, int value) async {
    final prefs = await _instanceOrNull();
    if (prefs != null) {
      await prefs.setInt(key, value);
      return;
    }
    _fallbackStore[key] = value;
  }

  // --- Station Cache ---

  Future<List<Station>?> getCachedStations() async {
    final json = await _getString(_stationsKey);
    if (json == null) {
      dev.log('No cached stations found', name: 'Storage');
      return null;
    }

    try {
      final list = jsonDecode(json) as List;
      final stations =
          list
              .map(
                (e) => Station(
                  locationSignature: e['sig'] as String,
                  name: e['name'] as String,
                  latitude: (e['lat'] as num).toDouble(),
                  longitude: (e['lon'] as num).toDouble(),
                ),
              )
              .toList();
      dev.log('Read ${stations.length} stations from cache', name: 'Storage');
      return stations;
    } catch (e) {
      dev.log(
        'Failed to parse cached stations: $e',
        name: 'Storage',
        level: 900,
      );
      return null;
    }
  }

  Future<void> cacheStations(List<Station> stations) async {
    dev.log('Caching ${stations.length} stations', name: 'Storage');
    final json = jsonEncode(
      stations
          .map(
            (s) => {
              'sig': s.locationSignature,
              'name': s.name,
              'lat': s.latitude,
              'lon': s.longitude,
            },
          )
          .toList(),
    );
    await _setString(_stationsKey, json);
    await _setString(_stationsCachedAtKey, DateTime.now().toIso8601String());
  }

  Future<bool> isStationCacheStale() async {
    final cachedAt = await _getString(_stationsCachedAtKey);
    if (cachedAt == null) return true;
    final date = DateTime.tryParse(cachedAt);
    if (date == null) return true;
    return DateTime.now().difference(date).inHours > 24;
  }

  // --- Local Favorites (anonymous users) ---

  Future<List<Station>> getLocalFavorites() async {
    final json = await _getString(_localFavoritesKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map(
            (e) => Station(
              locationSignature: e['sig'] as String,
              name: e['name'] as String,
              latitude: (e['lat'] as num).toDouble(),
              longitude: (e['lon'] as num).toDouble(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalFavorites(List<Station> favorites) async {
    final json = jsonEncode(
      favorites
          .map(
            (s) => {
              'sig': s.locationSignature,
              'name': s.name,
              'lat': s.latitude,
              'lon': s.longitude,
            },
          )
          .toList(),
    );
    await _setString(_localFavoritesKey, json);
  }

  // --- Local Recent Stations (anonymous users) ---

  Future<List<Station>> getLocalRecent() async {
    final json = await _getString(_localRecentKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map(
            (e) => Station(
              locationSignature: e['sig'] as String,
              name: e['name'] as String,
              latitude: (e['lat'] as num).toDouble(),
              longitude: (e['lon'] as num).toDouble(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalRecent(List<Station> recent) async {
    final json = jsonEncode(
      recent
          .map(
            (s) => {
              'sig': s.locationSignature,
              'name': s.name,
              'lat': s.latitude,
              'lon': s.longitude,
            },
          )
          .toList(),
    );
    await _setString(_localRecentKey, json);
  }

  // --- Trip Counter / Dismiss Stats ---

  Future<int> getDismissCount() async {
    return await _getInt(_dismissCountKey) ?? 0;
  }

  Future<int> incrementDismissCount() async {
    final count = (await _getInt(_dismissCountKey) ?? 0) + 1;
    await _setInt(_dismissCountKey, count);
    dev.log('Dismiss count incremented to $count', name: 'Storage');
    return count;
  }

  Future<int> getLastMilestone() async {
    return await _getInt(_lastMilestoneKey) ?? 0;
  }

  Future<void> setLastMilestone(int milestone) async {
    await _setInt(_lastMilestoneKey, milestone);
  }

  // --- Station Usage Tracking (for commute detection) ---

  Future<Map<String, int>> getStationUsage() async {
    final json = await _getString(_stationUsageKey);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  Future<void> incrementStationUsage(String stationId) async {
    final usage = await getStationUsage();
    usage[stationId] = (usage[stationId] ?? 0) + 1;
    await _setString(_stationUsageKey, jsonEncode(usage));
  }

  Future<List<String>> getCommuteStations({int threshold = 3}) async {
    final usage = await getStationUsage();
    final entries = usage.entries.where((e) => e.value >= threshold).toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }
}
