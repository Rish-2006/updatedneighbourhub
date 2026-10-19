// lib/services/auth_service.dart
//
// This service handles ALL authentication logic.
// It talks to Firebase Auth and Google Sign-In.
//
// IMPORTANT: We ONLY request basic profile info from Google (name, email, photo).
//            We do NOT access Gmail messages, contacts, or any other Google data.
//
// This service extends ChangeNotifier so Provider can notify the UI
// whenever the user's login state changes.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  // The main Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In instance
  // scopes: we only request 'email' and 'profile' - nothing else
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'], // Only basic profile info - NO Gmail access
  );

  // The currently logged-in Firebase user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  // Whether a user is currently logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // A stream that emits the user whenever they log in or out
  // The main app listens to this to decide which screen to show
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Google Sign-In ──────────────────────────────────────────────────────
  // Returns either a UserModel (success) or a String error message (failure)
  Future<({UserModel? user, String? error})> signInWithGoogle() async {
    try {
      // Step 1: Show the Google account picker dialog
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in dialog
      if (googleUser == null) {
        return (user: null, error: 'Sign-in was cancelled.');
      }

      // Step 2: Get the authentication tokens from Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Step 3: Create a Firebase credential using the Google tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign into Firebase using the Google credential
      final UserCredential result =
          await _auth.signInWithCredential(credential);

      // Step 5: Build our UserModel from the Firebase user info
      final User firebaseUser = result.user!;
      final userModel = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Neighbour',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        neighbourhood: '', // Will be set during onboarding
        createdAt: DateTime.now(),
      );

      // Save user to Firestore so they appear in members list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toMap(), SetOptions(merge: true));

      notifyListeners(); // Tell the UI the auth state changed
      return (user: userModel, error: null);
    } on FirebaseAuthException catch (e) {
      return (user: null, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return (user: null, error: 'Sign-in failed. Please try again.');
    }
  }

  // ─── Email/Password Sign-In ───────────────────────────────────────────────
  Future<({User? user, String? error})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return (user: result.user, error: null);
    } on FirebaseAuthException catch (e) {
      return (user: null, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return (user: null, error: 'Login failed. Please try again.');
    }
  }

  // ─── Email/Password Registration ──────────────────────────────────────────
  Future<({User? user, String? error})> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update the Firebase user's display name
      await result.user?.updateDisplayName(name.trim());

      // Save user to Firestore so they appear in members list
      if (result.user != null) {
        final userModel = UserModel(
          id: result.user!.uid,
          name: name.trim(),
          email: email.trim(),
          photoUrl: '',
          neighbourhood: '',
          createdAt: DateTime.now(),
        );
        // We use a fresh instance or you can inject it, but instance is fine for Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toMap(), SetOptions(merge: true));
      }

      notifyListeners();
      return (user: result.user, error: null);
    } on FirebaseAuthException catch (e) {
      return (user: null, error: _getFirebaseErrorMessage(e.code));
    } catch (e) {
      return (user: null, error: 'Registration failed. Please try again.');
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      return _getFirebaseErrorMessage(e.code);
    } catch (e) {
      return 'Failed to send reset email. Please try again.';
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      // Sign out from Google (may fail if not logged in via Google)
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google Sign out error (ignored): $e');
      }
      
      // Always sign out from Firebase
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Firebase Sign out error: $e');
      throw Exception('Failed to sign out from Firebase: $e');
    }
  }

  // ─── Helper: Human-friendly error messages ────────────────────────────────
  // Firebase gives error codes like "user-not-found" - we convert these
  // into friendly messages that make sense to users.
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Contact support.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
