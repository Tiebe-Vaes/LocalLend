import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Bridges FirebaseAuth + the `users` collection for sign-in/sign-up and
/// profile updates.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Stream that emits whenever the signed-in Firebase user changes.
  Stream<User?> authStateChanges() => _auth.authStateChanges();
  /// Currently signed-in Firebase user, or null if signed out.
  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Creates a Firebase user, writes its profile document and returns it.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    final user = AppUser(
      id: cred.user!.uid,
      email: email.trim(),
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    await _users.doc(user.id).set(user.toMap());
    return user;
  }

  /// Signs the user in with email + password.
  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// Signs the current user out.
  Future<void> signOut() => _auth.signOut();

  /// Live stream of the [AppUser] profile document for [uid].
  Stream<AppUser?> watchAppUser(String uid) =>
      _users.doc(uid).snapshots().map((d) => d.exists ? AppUser.fromDoc(d) : null);

  /// One-shot read of the [AppUser] profile for [uid].
  Future<AppUser?> fetchAppUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Persists the user's last known location.
  Future<void> updateLocation(String uid, double lat, double lng) =>
      _users.doc(uid).update({'lat': lat, 'lng': lng});

  /// Adds or removes [itemId] from the user's favourites list.
  Future<void> toggleFavorite(String uid, String itemId, bool add) =>
      _users.doc(uid).update({
        'favoriteItemIds':
            add ? FieldValue.arrayUnion([itemId]) : FieldValue.arrayRemove([itemId]),
      });
}
