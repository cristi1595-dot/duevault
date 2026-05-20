import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_sign_in/google_sign_in.dart';
import '../utils/logger.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final isGuestProvider = StateProvider<bool>((ref) => true);
final hasSeenOnboardingProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Standard GoogleSignIn instance - MINIMAL for testing
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '933555779274-babvkfn1rvfl7rufl386cgqq50u12fvl.apps.googleusercontent.com',
    scopes: ['email', 'https://www.googleapis.com/auth/drive.appdata'],
  );

  // Cache the access token directly from GoogleSignInAuthentication
  String? _cachedAccessToken;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      logger.i('Starting Google Sign-In process...');

      // Just sign out to be sure
      await _googleSignIn.signOut().catchError((e) {
        logger.w('Sign out error (ignored): $e');
        return null;
      });

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        logger.w('Google Sign-In was canceled by the user.');
        return null;
      }

      logger.i('Google Sign-In successful for: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;

      logger.i('Obtained authentication tokens.');

      // Save access token directly — userCredential.credential is null on Android (fix C2)
      _cachedAccessToken = googleAuth.accessToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential;
    } catch (e, stack) {
      logger.e('Error signing in with Google', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Refresh the access token silently for Drive API operations (fix M2)
  /// Call this before every Drive operation to ensure a valid, non-expired token.
  Future<String?> getFreshAccessToken() async {
    try {
      // Try silent sign-in first (no UI)
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      // User needs to explicitly sign in again
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      _cachedAccessToken = googleAuth.accessToken;
      return _cachedAccessToken;
    } catch (e, stack) {
      logger.e('Error refreshing access token', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Use the same instance (fix M1)
    await _auth.signOut();
    _cachedAccessToken = null;
  }

  /// Reauthenticate the user with Google Sign-In to refresh credentials
  Future<void> reauthenticate() async {
    final user = _auth.currentUser;
    if (user == null) return;

    logger.i('Reauthenticating user for sensitive operation...');
    GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
    googleUser ??= await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Reauthentication canceled by the user.');
    }

    final googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
    _cachedAccessToken = googleAuth.accessToken;
    logger.i('Reauthentication successful.');
  }

  /// Wipe and delete the Firebase Authentication user account permanently.
  /// Handles security reauthentication if the login session is stale.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.delete();
      logger.i('Firebase user deleted successfully.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        logger.w('Reauthentication required to delete account.');
        // Trigger silent or explicit sign-in to get fresh credentials
        GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
        googleUser ??= await _googleSignIn.signIn();
        
        if (googleUser == null) {
          throw Exception('Reauthentication canceled by the user.');
        }

        final googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Reauthenticate the current user session
        await user.reauthenticateWithCredential(credential);
        
        // Retry deletion
        await user.delete();
        logger.i('Firebase user deleted successfully after reauthentication.');
      } else {
        rethrow;
      }
    }
  }

  // Get the cached access token for Drive API
  String? get currentAccessToken => _cachedAccessToken;
}
