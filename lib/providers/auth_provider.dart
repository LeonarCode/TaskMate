import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus { loading, authenticated, unauthenticated, profileIncomplete }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.loading;
  User? _firebaseUser;
  UserModel? _userModel;
  String? _error;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider(this._authService) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _userModel = null;
      } else {
        final hasProfile = await _authService.hasProfile(user.uid);
        if (!hasProfile) {
          _status = AuthStatus.profileIncomplete;
          _userModel = null;
        } else {
          _userModel = await _authService.getUser(user.uid);
          _status = AuthStatus.authenticated;
        }
      }
      notifyListeners();
    });
  }

  // ── Auth actions ─────────────────────────────────────────────────────────────
  Future<void> signInWithEmail(String email, String password) async {
    _setLoading();
    try {
      await _authService.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } catch (e) {
      _setError('An unexpected error occurred');
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    _setLoading();
    try {
      await _authService.registerWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } catch (e) {
      _setError('An unexpected error occurred');
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      final cred = await _authService.signInWithGoogle();

      // User cancelled the picker — not an error, just reset state
      if (cred == null) {
        _status = AuthStatus.unauthenticated;
        _error = null;
        notifyListeners();
        return false;
      }

      // Auth state listener (_init) will handle navigation automatically
      // No need to manually set status here
      return true;
    } on FirebaseAuthException catch (e) {
      // Catch Firebase-specific errors from AuthService
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      // Surface the specific error message from AuthService
      // instead of swallowing it with a generic message
      final msg = e.toString().replaceAll('Exception: ', '');
      _setError(msg);
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  Future<void> completeProfile(UserModel user) async {
    _setLoading();
    try {
      await _authService.createProfile(user);
      _userModel = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _setError('Failed to save profile');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _firebaseUser = null;
    _userModel = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_firebaseUser == null) return;
    _userModel = await _authService.getUser(_firebaseUser!.uid);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    _status =
        _firebaseUser != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credential. Please try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
