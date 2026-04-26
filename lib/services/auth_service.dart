import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  // ── Stream ──────────────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Email / Password ────────────────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Force account picker every time — prevents stale account issues
      // where a previously signed-in account is reused silently
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User dismissed the picker

      final googleAuth = await googleUser.authentication;

      // Null tokens = SHA-1 not registered or google-services.json is outdated
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception(
          'Google authentication tokens are null. '
          'Make sure your SHA-1 fingerprint is added in Firebase Console '
          'and google-services.json is re-downloaded.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'An account already exists with this email using a different sign-in method.',
          );
        case 'invalid-credential':
          throw Exception('Invalid credential. Please try again.');
        case 'network-request-failed':
          throw Exception('No internet connection. Please check your network.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        default:
          throw Exception('Google Sign-In failed: ${e.message}');
      }
    } catch (e) {
      final msg = e.toString();

      // ApiException: 12501 — user pressed back/cancelled, not an error
      if (msg.contains('12501')) return null;

      // ApiException: 10 — SHA-1 not registered in Firebase Console
      if (msg.contains(': 10') || msg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'SHA-1 fingerprint not registered in Firebase Console. '
          'Run: cd android && ./gradlew signingReport '
          'then add the SHA-1 to your Firebase project settings.',
        );
      }

      // ApiException: 12500 — google-services.json is outdated
      if (msg.contains('12500')) {
        throw Exception(
          'Google Sign-In configuration error. '
          'Re-download google-services.json from Firebase Console.',
        );
      }

      // ApiException: 7 — network error
      if (msg.contains(': 7')) {
        throw Exception('No internet connection. Please check your network.');
      }

      rethrow;
    }
  }

  // ── Profile check ───────────────────────────────────────────────────────────
  Future<bool> hasProfile(String uid) async {
    final doc = await _firestore.collection(AppStrings.colUsers).doc(uid).get();
    return doc.exists && (doc.data()?['username'] != null);
  }

  // ── Create / Update profile ─────────────────────────────────────────────────
  Future<void> createProfile(UserModel user) async {
    await _firestore
        .collection(AppStrings.colUsers)
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(AppStrings.colUsers).doc(uid).update(data);
  }

  // ── Get user ────────────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(AppStrings.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    return _firestore
        .collection(AppStrings.colUsers)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ── Sign out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Username availability ───────────────────────────────────────────────────
  Future<bool> isUsernameAvailable(String username) async {
    final query =
        await _firestore
            .collection(AppStrings.colUsers)
            .where('username', isEqualTo: username.trim().toLowerCase())
            .limit(1)
            .get();
    return query.docs.isEmpty;
  }
}
