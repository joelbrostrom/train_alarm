import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sov_inte_forbi/models/app_user.dart';
import 'package:sov_inte_forbi/services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore;

  AppUser? _user;
  bool _loading = true;
  bool _skippedSignIn = false;

  AuthProvider(this._firestore) {
    // Use userChanges() — a superset of authStateChanges() that also fires on
    // token refresh and profile updates. More reliable on web.
    _auth.userChanges().listen(_onAuthChanged);

    // If Firebase already has a persisted session, the stream fires
    // asynchronously. As a belt-and-suspenders check, also read currentUser.
    final existing = _auth.currentUser;
    if (existing != null) {
      _onAuthChanged(existing);
    }
  }

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get loading => _loading;
  bool get skippedSignIn => _skippedSignIn;
  bool get showSignIn => !isSignedIn && !_skippedSignIn && !_loading;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    print('_onAuthChanged fired: uid=${firebaseUser?.uid}');

    if (firebaseUser == null) {
      _user = null;
      _loading = false;
      notifyListeners();
      return;
    }

    final localUser = AppUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
    );

    _user = localUser;
    _loading = false;
    notifyListeners();

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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _errorMessage = null;
      _loading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && _user?.uid != credential.user!.uid) {
        await _onAuthChanged(credential.user);
      }
    } on FirebaseAuthException catch (e) {
      _loading = false;
      _errorMessage = _friendlyAuthError(e.code);
      notifyListeners();
    } catch (e) {
      _loading = false;
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _errorMessage = null;
      _loading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && _user?.uid != credential.user!.uid) {
        await _onAuthChanged(credential.user);
      }
    } on FirebaseAuthException catch (e) {
      _loading = false;
      _errorMessage = _friendlyAuthError(e.code);
      notifyListeners();
    } catch (e) {
      _loading = false;
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static String _friendlyAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-credential' => 'Invalid email or password.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  Future<void> signInWithGoogle() async {
    try {
      _loading = true;
      notifyListeners();

      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      final credential = await _auth.signInWithPopup(provider);

      print('Google sign-in result: user=${credential.user?.uid}');

      // The stream should handle this, but as a safety net on web where
      // the event can occasionally be missed, handle it directly.
      if (credential.user != null && _user?.uid != credential.user!.uid) {
        print('Stream did not update user — handling directly');
        await _onAuthChanged(credential.user);
      }
    } catch (e) {
      _loading = false;
      notifyListeners();
      print('Google sign-in error: $e');
    }
  }

  void skipSignIn() {
    _skippedSignIn = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _skippedSignIn = false;
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
