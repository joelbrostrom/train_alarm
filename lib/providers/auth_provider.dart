import 'dart:developer' as dev;

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
    _auth.authStateChanges().listen(_onAuthChanged);

    final existing = _auth.currentUser;
    if (existing != null) {
      _onAuthChanged(existing);
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (_loading) {
        dev.log(
          'Auth loading timed out — clearing loading state',
          name: 'Auth',
        );
        _loading = false;
        notifyListeners();
      }
    });
  }

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get loading => _loading;
  bool get skippedSignIn => _skippedSignIn;
  bool get showSignIn => !isSignedIn && !_skippedSignIn && !_loading;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    dev.log('Auth state changed: uid=${firebaseUser?.uid}', name: 'Auth');

    if (firebaseUser == null) {
      dev.log('User signed out', name: 'Auth');
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
        dev.log('Loaded existing Firestore user profile', name: 'Auth');
        _user = existing;
      } else {
        dev.log('Creating new Firestore user profile', name: 'Auth');
        await _firestore.saveUser(localUser);
      }
      notifyListeners();
    } catch (e) {
      dev.log(
        'Firestore user sync error (non-fatal): $e',
        name: 'Auth',
        level: 900,
      );
    }
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> signInWithEmail(String email, String password) async {
    dev.log('Signing in with email: $email', name: 'Auth');
    try {
      _errorMessage = null;
      _loading = true;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      dev.log(
        'Email sign-in successful: uid=${credential.user?.uid}',
        name: 'Auth',
      );
      if (credential.user != null && _user?.uid != credential.user!.uid) {
        await _onAuthChanged(credential.user);
      }
    } on FirebaseAuthException catch (e) {
      dev.log('Email sign-in failed: ${e.code}', name: 'Auth', level: 1000);
      _loading = false;
      _errorMessage = _friendlyAuthError(e.code);
      notifyListeners();
    } catch (e) {
      dev.log('Email sign-in error: $e', name: 'Auth', level: 1000);
      _loading = false;
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    dev.log('Signing up with email: $email', name: 'Auth');
    try {
      _errorMessage = null;
      _loading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      dev.log(
        'Email sign-up successful: uid=${credential.user?.uid}',
        name: 'Auth',
      );
      if (credential.user != null && _user?.uid != credential.user!.uid) {
        await _onAuthChanged(credential.user);
      }
    } on FirebaseAuthException catch (e) {
      dev.log('Email sign-up failed: ${e.code}', name: 'Auth', level: 1000);
      _loading = false;
      _errorMessage = _friendlyAuthError(e.code);
      notifyListeners();
    } catch (e) {
      dev.log('Email sign-up error: $e', name: 'Auth', level: 1000);
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
    dev.log('Starting Google sign-in', name: 'Auth');
    try {
      _loading = true;
      notifyListeners();

      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      final credential = await _auth.signInWithPopup(provider);

      dev.log(
        'Google sign-in result: uid=${credential.user?.uid}',
        name: 'Auth',
      );

      if (credential.user != null && _user?.uid != credential.user!.uid) {
        dev.log('Auth stream did not fire — handling directly', name: 'Auth');
        await _onAuthChanged(credential.user);
      }
    } catch (e) {
      _loading = false;
      notifyListeners();
      dev.log('Google sign-in error: $e', name: 'Auth', level: 1000);
    }
  }

  void skipSignIn() {
    dev.log('User skipped sign-in', name: 'Auth');
    _skippedSignIn = true;
    _loading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    dev.log('Signing out', name: 'Auth');
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
