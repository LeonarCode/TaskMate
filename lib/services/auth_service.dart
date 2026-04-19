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
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
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
