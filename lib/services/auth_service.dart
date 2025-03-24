import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/retry_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await RetryHelper.withRetry(
        operation: () => _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await RetryHelper.withRetry(
        operation: () => _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await RetryHelper.withRetry(
        operation: () => _googleSignIn.signIn(),
      );

      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await RetryHelper.withRetry(
        operation: () => googleUser.authentication,
      );

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await RetryHelper.withRetry(
        operation: () => _auth.signInWithCredential(credential),
      );
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out (updated to handle Google Sign-In)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            throw 'Invalid email address';
          case 'user-not-found':
            throw 'No user found with this email';
          default:
            throw 'An error occurred. Please try again later.';
        }
      }
      throw e.toString();
    }
  }
}