import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sov_inte_forbi/models/alarm.dart';
import 'package:sov_inte_forbi/models/app_user.dart';
import 'package:sov_inte_forbi/models/station.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromFirestoreMap(doc.data()!);
  }

  Future<void> saveUser(AppUser user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestoreMap(), SetOptions(merge: true));
  }

  // --- Favorite Stations ---

  Future<List<Station>> getFavoriteStations(String userId) async {
    final snap =
        await _db
            .collection('users')
            .doc(userId)
            .collection('favoriteStations')
            .orderBy('createdAt', descending: true)
            .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return Station(
        locationSignature: data['stationId'] as String? ?? '',
        name: data['stationName'] as String? ?? '',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<void> addFavoriteStation(String userId, Station station) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favoriteStations')
        .doc(station.locationSignature)
        .set({
          ...station.toFirestoreMap(),
          'createdAt': DateTime.now().toIso8601String(),
        });
  }

  Future<void> removeFavoriteStation(
    String userId,
    String locationSignature,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favoriteStations')
        .doc(locationSignature)
        .delete();
  }

  // --- Alarms ---

  Future<List<Alarm>> getAlarms(String userId) async {
    final snap =
        await _db
            .collection('users')
            .doc(userId)
            .collection('alarms')
            .orderBy('createdAt', descending: true)
            .get();

    return snap.docs
        .map((doc) => Alarm.fromFirestoreMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> saveAlarm(String userId, Alarm alarm) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('alarms')
        .doc(alarm.id)
        .set(alarm.toFirestoreMap(), SetOptions(merge: true));
  }

  Future<void> deleteAlarm(String userId, String alarmId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('alarms')
        .doc(alarmId)
        .delete();
  }

  // --- Recent Stations ---

  Future<List<Station>> getRecentStations(String userId) async {
    final snap =
        await _db
            .collection('users')
            .doc(userId)
            .collection('recentStations')
            .orderBy('usedAt', descending: true)
            .limit(10)
            .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return Station(
        locationSignature: data['stationId'] as String? ?? '',
        name: data['stationName'] as String? ?? '',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  Future<void> addRecentStation(String userId, Station station) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('recentStations')
        .doc(station.locationSignature)
        .set({
          ...station.toFirestoreMap(),
          'usedAt': DateTime.now().toIso8601String(),
        });
  }
}
