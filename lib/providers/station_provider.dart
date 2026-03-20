import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sov_inte_forbi/models/station.dart';
import 'package:sov_inte_forbi/services/firestore_service.dart';
import 'package:sov_inte_forbi/services/local_storage_service.dart';
import 'package:sov_inte_forbi/services/trafikverket_service.dart';

class StationProvider extends ChangeNotifier {
  final TrafikverketService _trafikverket;
  final FirestoreService _firestore;
  final LocalStorageService _localStorage;

  List<Station> _allStations = [];
  List<Station> _favoriteStations = [];
  List<Station> _recentStations = [];
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  StationProvider(this._trafikverket, this._firestore, this._localStorage);

  List<Station> get allStations => _allStations;
  List<Station> get favoriteStations => _favoriteStations;
  List<Station> get recentStations => _recentStations;
  bool get loading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<Station> get filteredStations {
    if (_searchQuery.isEmpty) {
      return [
        ..._favoriteStations,
        ..._recentStations.where(
          (r) =>
              !_favoriteStations.any(
                (f) => f.locationSignature == r.locationSignature,
              ),
        ),
        ..._allStations.take(50),
      ];
    }

    final query = _searchQuery.toLowerCase();
    final scored = <(Station, int)>[];

    for (final s in _allStations) {
      final name = s.name.toLowerCase();
      final sig = s.locationSignature.toLowerCase();

      if (name == query || sig == query) {
        scored.add((s, 100));
      } else if (name.startsWith(query)) {
        scored.add((s, 80));
      } else if (sig.startsWith(query)) {
        scored.add((s, 70));
      } else if (name.contains(query)) {
        scored.add((s, 50));
      } else if (_fuzzyMatch(name, query)) {
        scored.add((s, 30));
      }
    }

    scored.sort((a, b) {
      final isFavA = isFavorite(a.$1.locationSignature) ? 1 : 0;
      final isFavB = isFavorite(b.$1.locationSignature) ? 1 : 0;
      if (isFavA != isFavB) return isFavB - isFavA;
      return b.$2 - a.$2;
    });

    return scored.take(30).map((e) => e.$1).toList();
  }

  bool _fuzzyMatch(String text, String query) {
    int qi = 0;
    for (int ti = 0; ti < text.length && qi < query.length; ti++) {
      if (text[ti] == query[qi]) qi++;
    }
    return qi == query.length;
  }

  bool isFavorite(String locationSignature) {
    return _favoriteStations.any(
      (f) => f.locationSignature == locationSignature,
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadStations() async {
    dev.log('Loading stations...', name: 'Station');
    _loading = true;
    _error = null;
    notifyListeners();

    final cached = await _localStorage.getCachedStations();
    if (cached != null && cached.isNotEmpty) {
      _allStations = List<Station>.of(cached);
      _allStations.sort((a, b) => a.name.compareTo(b.name));
      _loading = false;
      dev.log(
        'Loaded ${_allStations.length} stations from cache',
        name: 'Station',
      );
      notifyListeners();

      if (await _localStorage.isStationCacheStale()) {
        dev.log(
          'Station cache is stale — refreshing in background',
          name: 'Station',
        );
        _refreshStationsInBackground();
      }
      return;
    }

    try {
      _allStations = List<Station>.of(await _trafikverket.fetchStations());
      _allStations.sort((a, b) => a.name.compareTo(b.name));
      _localStorage.cacheStations(_allStations);
      dev.log(
        'Fetched ${_allStations.length} stations from API',
        name: 'Station',
      );
    } catch (e) {
      _error = 'Could not load stations. Check your connection.';
      dev.log('Station load error: $e', name: 'Station', level: 1000);
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _refreshStationsInBackground() async {
    try {
      final fresh = List<Station>.of(
        await _trafikverket.fetchStations(forceRefresh: true),
      );
      fresh.sort((a, b) => a.name.compareTo(b.name));
      _allStations = fresh;
      _localStorage.cacheStations(fresh);
      dev.log(
        'Background refresh complete: ${fresh.length} stations',
        name: 'Station',
      );
      notifyListeners();
    } catch (e) {
      dev.log('Background refresh failed: $e', name: 'Station', level: 900);
    }
  }

  Future<void> loadLocalData() async {
    _favoriteStations = List<Station>.of(
      await _localStorage.getLocalFavorites(),
    );
    _recentStations = List<Station>.of(await _localStorage.getLocalRecent());
    dev.log(
      'Loaded local data: ${_favoriteStations.length} favorites, '
      '${_recentStations.length} recent',
      name: 'Station',
    );
    notifyListeners();
  }

  Future<void> loadFavorites(String userId) async {
    dev.log(
      'Loading favorites from Firestore for user=$userId',
      name: 'Station',
    );
    try {
      _favoriteStations = List<Station>.of(
        await _firestore.getFavoriteStations(userId),
      );
      dev.log('Loaded ${_favoriteStations.length} favorites', name: 'Station');
      notifyListeners();
    } catch (e) {
      dev.log('Load favorites error: $e', name: 'Station', level: 1000);
    }
  }

  Future<void> loadRecentStations(String userId) async {
    dev.log('Loading recent stations for user=$userId', name: 'Station');
    try {
      _recentStations = List<Station>.of(
        await _firestore.getRecentStations(userId),
      );
      dev.log(
        'Loaded ${_recentStations.length} recent stations',
        name: 'Station',
      );
      notifyListeners();
    } catch (e) {
      dev.log('Load recent error: $e', name: 'Station', level: 1000);
    }
  }

  Future<void> toggleFavorite(Station station, String? userId) async {
    dev.log(
      'Toggle favorite: ${station.name} (${station.locationSignature})',
      name: 'Station',
    );
    final existing = _favoriteStations.indexWhere(
      (f) => f.locationSignature == station.locationSignature,
    );

    if (existing >= 0) {
      _favoriteStations.removeAt(existing);
      if (userId != null) {
        await _firestore.removeFavoriteStation(
          userId,
          station.locationSignature,
        );
      }
    } else {
      _favoriteStations.add(station);
      if (userId != null) {
        await _firestore.addFavoriteStation(userId, station);
      }
    }
    _localStorage.saveLocalFavorites(_favoriteStations);
    notifyListeners();
  }

  Future<void> addRecentStation(String? userId, Station station) async {
    dev.log('Adding recent station: ${station.name}', name: 'Station');
    _recentStations.removeWhere(
      (r) => r.locationSignature == station.locationSignature,
    );
    _recentStations.insert(0, station);
    if (_recentStations.length > 10) {
      _recentStations = _recentStations.take(10).toList();
    }
    _localStorage.saveLocalRecent(_recentStations);
    if (userId != null) {
      await _firestore.addRecentStation(userId, station);
    }
    notifyListeners();
  }

  List<Station> nearbyStations(double lat, double lon, {int limit = 3}) {
    if (_allStations.isEmpty) return [];
    final sorted = List<Station>.from(_allStations);
    sorted.sort((a, b) {
      final dA = _quickDistance(lat, lon, a.latitude, a.longitude);
      final dB = _quickDistance(lat, lon, b.latitude, b.longitude);
      return dA.compareTo(dB);
    });
    return sorted.take(limit).toList();
  }

  static double quickDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return _quickDistance(lat1, lon1, lat2, lon2) / 1000;
  }

  static double _quickDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<List<Station>> getCommuteStations() async {
    final ids = await _localStorage.getCommuteStations();
    return ids
        .map((id) => findBySignature(id))
        .where((s) => s != null)
        .cast<Station>()
        .toList();
  }

  Station? findBySignature(String sig) {
    try {
      return _allStations.firstWhere((s) => s.locationSignature == sig);
    } catch (_) {
      return null;
    }
  }
}
