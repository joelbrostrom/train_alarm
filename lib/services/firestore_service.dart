import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sov_inte_forbi/models/alarm.dart';
import 'package:sov_inte_forbi/models/app_user.dart';
import 'package:sov_inte_forbi/models/station.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---

  Future<AppUser?> getUser(String uid) async {
    dev.log('Fetching user: $uid', name: 'Firestore');
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      dev.log('User not found: $uid', name: 'Firestore');
      return null;
    }
    return AppUser.fromFirestoreMap(doc.data()!);
  }

  Future<void> saveUser(AppUser user) async {
    dev.log('Saving user: ${user.uid}', name: 'Firestore');
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestoreMap(), SetOptions(merge: true));
  }

  // --- Favorite Stations ---

  Future<List<Station>> getFavoriteStations(String userId) async {
    dev.log('Fetching favorite stations for: $userId', name: 'Firestore');
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
    dev.log(
      'Adding favorite: ${station.name} for user=$userId',
      name: 'Firestore',
    );
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
    dev.log(
      'Removing favorite: $locationSignature for user=$userId',
      name: 'Firestore',
    );
    await _db
        .collection('users')
        .doc(userId)
        .collection('favoriteStations')
        .doc(locationSignature)
        .delete();
  }

  // --- Alarms ---

  Future<List<Alarm>> getAlarms(String userId) async {
    dev.log('Fetching alarms for: $userId', name: 'Firestore');
    final snap =
        await _db
            .collection('users')
            .doc(userId)
            .collection('alarms')
            .orderBy('createdAt', descending: true)
            .get();

    dev.log('Fetched ${snap.docs.length} alarms', name: 'Firestore');
    return snap.docs
        .map((doc) => Alarm.fromFirestoreMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> saveAlarm(String userId, Alarm alarm) async {
    dev.log(
      'Saving alarm: ${alarm.id} (${alarm.stationName}) for user=$userId',
      name: 'Firestore',
    );
    await _db
        .collection('users')
        .doc(userId)
        .collection('alarms')
        .doc(alarm.id)
        .set(alarm.toFirestoreMap(), SetOptions(merge: true));
  }

  Future<void> deleteAlarm(String userId, String alarmId) async {
    dev.log('Deleting alarm: $alarmId for user=$userId', name: 'Firestore');
    await _db
        .collection('users')
        .doc(userId)
        .collection('alarms')
        .doc(alarmId)
        .delete();
  }

  // --- Recent Stations ---

  Future<List<Station>> getRecentStations(String userId) async {
    dev.log('Fetching recent stations for: $userId', name: 'Firestore');
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
    dev.log(
      'Adding recent station: ${station.name} for user=$userId',
      name: 'Firestore',
    );
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
