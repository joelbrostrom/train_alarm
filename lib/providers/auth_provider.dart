import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sov_inte_forbi/models/app_user.dart';
import 'package:sov_inte_forbi/services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore;

  AppUser? _user;
  bool _loading = true;

  AuthProvider(this._firestore) {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get loading => _loading;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _loading = false;
      notifyListeners();
      return;
    }

    // Always create the local user immediately so the UI updates
    final localUser = AppUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
    );

    _user = localUser;
    _loading = false;
    notifyListeners();

    // Then try to load/save from Firestore in the background
    try {
      final existing = await _firestore.getUser(firebaseUser.uid);
      if (existing != null) {
        _user = existing;
      } else {
        await _firestore.saveUser(localUser);
      }
      notifyListeners();
    } catch (e) {
      print('Firestore user sync error (non-fatal): $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      await _auth.signInWithPopup(provider);
    } catch (e) {
      print('Google sign-in error: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateDefaultMinutes(int minutes) async {
    if (_user == null) return;
    _user = _user!.copyWith(defaultAlertMinutes: minutes);
    await _firestore.saveUser(_user!);
    notifyListeners();
  }

  Future<void> updateHomeStation({
    required String stationId,
    required String stationName,
    required double latitude,
    required double longitude,
  }) async {
    if (_user == null) return;
    _user = _user!.copyWith(
      homeStationId: stationId,
      homeStationName: stationName,
      homeLatitude: latitude,
      homeLongitude: longitude,
    );
    await _firestore.saveUser(_user!);
    notifyListeners();
  }
}
