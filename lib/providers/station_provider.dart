import 'package:flutter/material.dart';
import 'package:sov_inte_forbi/models/station.dart';
import 'package:sov_inte_forbi/services/firestore_service.dart';
import 'package:sov_inte_forbi/services/trafikverket_service.dart';

class StationProvider extends ChangeNotifier {
  final TrafikverketService _trafikverket;
  final FirestoreService _firestore;

  List<Station> _allStations = [];
  List<Station> _favoriteStations = [];
  List<Station> _recentStations = [];
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  StationProvider(this._trafikverket, this._firestore);

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
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _allStations = await _trafikverket.fetchStations();
      _allStations.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _error = 'Could not load stations. Check your connection.';
      print('Station load error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadFavorites(String userId) async {
    try {
      _favoriteStations = await _firestore.getFavoriteStations(userId);
      notifyListeners();
    } catch (e) {
      print('Load favorites error: $e');
    }
  }

  Future<void> loadRecentStations(String userId) async {
    try {
      _recentStations = await _firestore.getRecentStations(userId);
      notifyListeners();
    } catch (e) {
      print('Load recent error: $e');
    }
  }

  Future<void> toggleFavorite(Station station, String userId) async {
    final existing = _favoriteStations.indexWhere(
      (f) => f.locationSignature == station.locationSignature,
    );

    if (existing >= 0) {
      _favoriteStations.removeAt(existing);
      await _firestore.removeFavoriteStation(userId, station.locationSignature);
    } else {
      _favoriteStations.add(station);
      await _firestore.addFavoriteStation(userId, station);
    }
    notifyListeners();
  }

  Future<void> addRecentStation(String userId, Station station) async {
    _recentStations.removeWhere(
      (r) => r.locationSignature == station.locationSignature,
    );
    _recentStations.insert(0, station);
    if (_recentStations.length > 10) {
      _recentStations = _recentStations.take(10).toList();
    }
    await _firestore.addRecentStation(userId, station);
    notifyListeners();
  }

  Station? findBySignature(String sig) {
    try {
      return _allStations.firstWhere((s) => s.locationSignature == sig);
    } catch (_) {
      return null;
    }
  }
}
