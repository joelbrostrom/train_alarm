import 'dart:convert';

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

  SharedPreferencesAsync? _prefs;

  Future<SharedPreferencesAsync> get _instance async {
    _prefs ??= SharedPreferencesAsync();
    return _prefs!;
  }

  // --- Station Cache ---

  Future<List<Station>?> getCachedStations() async {
    final prefs = await _instance;
    final json = await prefs.getString(_stationsKey);
    if (json == null) return null;

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
      return null;
    }
  }

  Future<void> cacheStations(List<Station> stations) async {
    final prefs = await _instance;
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
    await prefs.setString(_stationsKey, json);
    await prefs.setString(
      _stationsCachedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<bool> isStationCacheStale() async {
    final prefs = await _instance;
    final cachedAt = await prefs.getString(_stationsCachedAtKey);
    if (cachedAt == null) return true;
    final date = DateTime.tryParse(cachedAt);
    if (date == null) return true;
    return DateTime.now().difference(date).inHours > 24;
  }

  // --- Local Favorites (anonymous users) ---

  Future<List<Station>> getLocalFavorites() async {
    final prefs = await _instance;
    final json = await prefs.getString(_localFavoritesKey);
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
    final prefs = await _instance;
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
    await prefs.setString(_localFavoritesKey, json);
  }

  // --- Local Recent Stations (anonymous users) ---

  Future<List<Station>> getLocalRecent() async {
    final prefs = await _instance;
    final json = await prefs.getString(_localRecentKey);
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
    final prefs = await _instance;
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
    await prefs.setString(_localRecentKey, json);
  }

  // --- Trip Counter / Dismiss Stats ---

  Future<int> getDismissCount() async {
    final prefs = await _instance;
    return await prefs.getInt(_dismissCountKey) ?? 0;
  }

  Future<int> incrementDismissCount() async {
    final prefs = await _instance;
    final count = (await prefs.getInt(_dismissCountKey) ?? 0) + 1;
    await prefs.setInt(_dismissCountKey, count);
    return count;
  }

  Future<int> getLastMilestone() async {
    final prefs = await _instance;
    return await prefs.getInt(_lastMilestoneKey) ?? 0;
  }

  Future<void> setLastMilestone(int milestone) async {
    final prefs = await _instance;
    await prefs.setInt(_lastMilestoneKey, milestone);
  }

  // --- Station Usage Tracking (for commute detection) ---

  Future<Map<String, int>> getStationUsage() async {
    final prefs = await _instance;
    final json = await prefs.getString(_stationUsageKey);
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
    final prefs = await _instance;
    await prefs.setString(_stationUsageKey, jsonEncode(usage));
  }

  Future<List<String>> getCommuteStations({int threshold = 3}) async {
    final usage = await getStationUsage();
    final entries = usage.entries.where((e) => e.value >= threshold).toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }
}
